import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../controllers/providers/user_providers.dart';
import '../../controllers/providers/profile_photo_provider.dart';
import '../../controllers/services/user_service.dart';

class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({super.key});

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileStreamProvider).asData?.value;
    _nameController = TextEditingController(text: profile?.displayName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: kIsWeb,
    );
    if (result == null) return;
    final f = result.files.single;
    ref
        .read(profilePhotoProvider.notifier)
        .setSelected(fileName: f.name, previewBytes: f.bytes, path: f.path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _isSaving = true);
    try {
      final firestore = FirebaseFirestore.instance;
      final users = UserService(firestore);
      final displayName = _nameController.text.trim();
      final currentProfile = ref.read(userProfileStreamProvider).asData?.value;
      final previousUrl = currentProfile?.photoUrl;
      final photoUrl = await ref
          .read(profilePhotoProvider.notifier)
          .upload(user.uid, previousUrl: previousUrl);

      await users.updateBasicProfile(
        userId: user.uid,
        displayName: displayName,
        photoUrl: photoUrl,
      );

      if (displayName.isNotEmpty) {
        await user.updateDisplayName(displayName);
      }
      if (photoUrl != null && photoUrl.isNotEmpty) {
        await user.updatePhotoURL(photoUrl);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileStreamProvider).asData?.value;
    final photoState = ref.watch(profilePhotoProvider);
    ImageProvider<Object>? currentPhoto;
    if (photoState.previewBytes != null) {
      currentPhoto = MemoryImage(photoState.previewBytes!);
    } else if (!kIsWeb && photoState.path != null) {
      currentPhoto = FileImage(File(photoState.path!));
    } else if (profile?.photoUrl != null && profile!.photoUrl!.isNotEmpty) {
      currentPhoto = NetworkImage(profile.photoUrl!);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF101828),
        title: const Text('Edit Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundImage: currentPhoto,
                      child: currentPhoto == null
                          ? const Icon(
                              Icons.person,
                              size: 36,
                              color: Colors.white70,
                            )
                          : null,
                      backgroundColor: const Color(0xFFE5E7EB),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _isSaving ? null : _pickPhoto,
                      icon: const Icon(Icons.photo_camera),
                      label: const Text('Change photo'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: UnderlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Full Name is required'
                      : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A73E8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
