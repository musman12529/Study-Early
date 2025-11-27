import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/providers/auth_providers.dart';
import '../controllers/providers/course_material_provider.dart';
import '../models/course_material.dart';

class CourseDetailPage extends ConsumerWidget {
  const CourseDetailPage({super.key, required this.courseId});

  final String courseId;

  static const Color _brandBlue = Color(0xFF1A73E8);
  static const Color _navy = Color(0xFF101828);
  static const Color _accentRed = Color(0xFFFF6B6B);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) =>
          Scaffold(body: Center(child: Text('Error: $err'))),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Not logged in')),
          );
        }

        final materials =
            ref.watch(courseMaterialListProvider((user.uid, courseId)));

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER: back, logo, notifications
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'asset/logo.png',
                            height: 24,
                          ),
                          const SizedBox(width: 6),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_none_outlined),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Notifications feature will be implemented later',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // COURSE TITLE
                  Text(
                    courseId,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: _navy,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // "Materials" + add button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Materials',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _navy,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () async {
                          await _pickUploadAndIndex(
                            context,
                            ref,
                            user,
                            courseId,
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // MAIN CONTENT SCROLL
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // MATERIALS LIST CONTAINER
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.grey.shade300,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                  color: Colors.black.withOpacity(0.03),
                                ),
                              ],
                            ),
                            child: materials.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 20,
                                    ),
                                    child: Text(
                                      'No materials yet. Tap + to add a PDF.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  )
                                : Column(
                                    children: [
                                      for (int i = 0;
                                          i < materials.length;
                                          i++)
                                        _MaterialRow(
                                          material: materials[i],
                                          showDivider:
                                              i != materials.length - 1,
                                          onDelete: () async {
                                            final m = materials[i];
                                            if (m.status ==
                                                MaterialStatus.indexing) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Cannot delete while indexing.',
                                                  ),
                                                ),
                                              );
                                              return;
                                            }
                                            await ref
                                                .read(
                                                  courseMaterialListProvider((
                                                    user.uid,
                                                    courseId,
                                                  )).notifier,
                                                )
                                                .remove(m.id);
                                          },
                                          onRetryIndex: () async {
                                            final m = materials[i];
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Retrying indexing...',
                                                ),
                                                duration: Duration(seconds: 1),
                                              ),
                                            );
                                            await ref
                                                .read(
                                                  courseMaterialListProvider((
                                                    user.uid,
                                                    courseId,
                                                  )).notifier,
                                                )
                                                .retry(m);
                                          },
                                          onExtraAction: () {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Feature will be implemented later',
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                          ),

                          const SizedBox(height: 24),

                          // BLUE BUTTONS: Generate Quiz / View Quizzes
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Generate Quiz feature will be implemented later',
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _brandBlue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      'Generate Quiz',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SizedBox(
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'View Quizzes feature will be implemented later',
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _brandBlue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      'View Quizzes',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // CHATBOT button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Chatbot feature will be implemented later',
                                    ),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: _brandBlue),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'CHATBOT',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _brandBlue,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // SUMMARIZE button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Summarize feature will be implemented later',
                                    ),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: _brandBlue),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'SUMMARIZE',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _brandBlue,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
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
      withData: kIsWeb, // Only read bytes on web, use file path on mobile
    );

    if (result == null) return;

    final picked = result.files.single;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await ref
          .read(courseMaterialListProvider((user.uid, courseId)).notifier)
          .uploadAndIndex(
            fileName: picked.name,
            filePath: picked.path,
            fileBytes: kIsWeb ? picked.bytes : null,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload + indexing complete.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      Navigator.of(context).pop();
    }
  }
}

class _MaterialRow extends StatelessWidget {
  const _MaterialRow({
    required this.material,
    required this.showDivider,
    required this.onDelete,
    required this.onRetryIndex,
    required this.onExtraAction,
  });

  final CourseMaterial material;
  final bool showDivider;
  final VoidCallback onDelete;
  final VoidCallback onRetryIndex;
  final VoidCallback onExtraAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // PDF icon
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.picture_as_pdf,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // File name
              Expanded(
                child: Text(
                  material.fileName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF101828),
                  ),
                ),
              ),
              // Optional retry if error
              if (material.status == MaterialStatus.error)
                IconButton(
                  tooltip: 'Retry indexing',
                  icon: const Icon(Icons.refresh),
                  onPressed: onRetryIndex,
                ),
              // Delete
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
              ),
              // Extra action (red checklist icon)
              IconButton(
                icon: const Icon(
                  Icons.checklist_rtl,
                  color: CourseDetailPage._accentRed,
                ),
                onPressed: onExtraAction,
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 0,
            thickness: 0.5,
            color: Colors.grey.shade300,
          ),
      ],
    );
  }
}
