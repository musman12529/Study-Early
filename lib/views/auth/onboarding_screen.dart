import 'dart:typed_data';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:studyearly/controllers/services/user_service.dart';
import 'package:studyearly/controllers/providers/profile_photo_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  bool _isSaving = false;
  Uint8List? _photoBytes;
  String? _photoPath;
  String? _photoFileName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(profilePhotoProvider.notifier).clear();
      }
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
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
    setState(() {
      _photoFileName = f.name;
      _photoBytes = f.bytes;
      _photoPath = f.path;
    });
    // Update controller state
    ref
        .read(profilePhotoProvider.notifier)
        .setSelected(
          fileName: _photoFileName ?? 'photo',
          previewBytes: _photoBytes,
          path: _photoPath,
        );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _isSaving = true);
    try {
      final firestore = FirebaseFirestore.instance;
      final users = UserService(firestore);
      final displayName = _displayNameController.text.trim();
      final photoUrl = await ref
          .read(profilePhotoProvider.notifier)
          .upload(user.uid);

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
      if (mounted) context.go('/home');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save profile: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const accentRed = Color(0xFFFF6B6B);
    final user = FirebaseAuth.instance.currentUser;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await FirebaseAuth.instance.signOut();
        if (mounted) context.go('/login');
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (mounted) context.go('/login');
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('asset/logo.png', height: 40),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  "Let's complete your profile",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "This helps us personalize your experience.",
                  style: TextStyle(fontSize: 14, color: Color(0xFF667085)),
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (user?.email != null) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            user!.email!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF667085),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Photo picker + preview
                      Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFE5E7EB),
                              image: () {
                                final state = ref.watch(profilePhotoProvider);
                                if (state.previewBytes != null) {
                                  return DecorationImage(
                                    image: MemoryImage(state.previewBytes!),
                                    fit: BoxFit.cover,
                                  );
                                }
                                if (!kIsWeb && state.path != null) {
                                  return DecorationImage(
                                    image: FileImage(File(state.path!)),
                                    fit: BoxFit.cover,
                                  );
                                }
                                return null;
                              }(),
                            ),
                            child: () {
                              final state = ref.watch(profilePhotoProvider);
                              final hasPreview =
                                  state.previewBytes != null ||
                                  (!kIsWeb && state.path != null);
                              return hasPreview
                                  ? null
                                  : const Icon(
                                      Icons.person,
                                      color: Colors.white70,
                                    );
                            }(),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: _isSaving ? null : _pickPhoto,
                            icon: const Icon(Icons.photo_camera),
                            label: const Text('Choose photo'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _displayNameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: UnderlineInputBorder(),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Full Name is required'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentRed,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Save and continue',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
