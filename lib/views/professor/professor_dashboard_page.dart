import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers/auth_providers.dart';
import '../../controllers/providers/course_material_provider.dart';
import '../../controllers/providers/course_providers.dart';
import '../../controllers/providers/user_providers.dart';
import '../../models/user_profile.dart';
import '../widgets/notification_bell_button.dart';

class ProfessorDashboardPage extends ConsumerStatefulWidget {
  const ProfessorDashboardPage({super.key});

  @override
  ConsumerState<ProfessorDashboardPage> createState() =>
      _ProfessorDashboardPageState();
}

class _ProfessorDashboardPageState
    extends ConsumerState<ProfessorDashboardPage> {
  static const Color _navy = Color(0xFF101828);
  static const Color _accentRed = Color(0xFFFF6B6B);

  String? _selectedCourseId;
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateChangesProvider);
    final profileState = ref.watch(userProfileStreamProvider);

    return authState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: Text('Not logged in')));
        }
        final profile = profileState.asData?.value;
        if (profile == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (profile.role != UserRole.professor) {
          return const Scaffold(
            body: Center(child: Text('Professor access only')),
          );
        }

        final courses = ref.watch(courseListProvider(user.uid));
        _selectedCourseId ??= courses.isNotEmpty ? courses.first.id : null;

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset('asset/logo.png', height: 32),
                          const SizedBox(width: 8),
                        ],
                      ),
                      Row(
                        children: [
                          NotificationBellButton(
                            userId: user.uid,
                            onPressed: () {
                              if (context.mounted) {
                                Navigator.of(
                                  context,
                                ).pushNamed('notifications');
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout),
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF101828),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Manage Materials',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (courses.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        'No courses yet. Create a course first to upload PDFs.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCourseId,
                            items: [
                              for (final c in courses)
                                DropdownMenuItem(
                                  value: c.id,
                                  child: Text(
                                    c.title,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: (v) =>
                                setState(() => _selectedCourseId = v),
                            decoration: const InputDecoration(
                              labelText: 'Course',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: (_isUploading || _selectedCourseId == null)
                              ? null
                              : () => _pickUploadAndIndex(
                                  context,
                                  ref,
                                  user,
                                  _selectedCourseId!,
                                ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentRed,
                            foregroundColor: Colors.white,
                          ),
                          icon: _isUploading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.file_upload),
                          label: Text(
                            _isUploading ? 'Uploading...' : 'Upload PDF',
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Students',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Add student (coming soon)'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add student'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickUploadAndIndex(
    BuildContext context,
    WidgetRef ref,
    User user,
    String courseId,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: kIsWeb,
    );

    if (result == null) return;

    final picked = result.files.single;

    try {
      setState(() {
        _isUploading = true;
      });

      await ref
          .read(courseMaterialListProvider((user.uid, courseId)).notifier)
          .uploadAndIndex(
            fileName: picked.name,
            filePath: kIsWeb ? null : picked.path,
            fileBytes: kIsWeb ? picked.bytes : null,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload + indexing started.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }
}
