import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../controllers/providers/auth_providers.dart';
import '../controllers/providers/course_material_provider.dart';
import '../models/course_material.dart';
import '../controllers/providers/quiz_providers.dart';
import 'quiz/quiz_list_page.dart';
import 'chat/chat_page.dart';

class CourseDetailPage extends ConsumerWidget {
  const CourseDetailPage({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  final String courseId;
  final String courseTitle;

  static const Color _brandBlue = Color(0xFF1A73E8);
  static const Color _navy = Color(0xFF101828);
  static const Color _accentRed = Color(0xFFFF6B6B);
  static const int _maxUploadBytes = 20 * 1024 * 1024; // 20 MB limit

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: Text('Not logged in')));
        }

        final materials = ref.watch(
          courseMaterialListProvider((user.uid, courseId)),
        );
        final selectedIds = ref.watch(
          selectedMaterialIdsProvider((user.uid, courseId)),
        );

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                          Image.asset('asset/logo.png', height: 24),
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
                    courseTitle,
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
                              border: Border.all(color: Colors.grey.shade300),
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
                                      for (int i = 0; i < materials.length; i++)
                                        _MaterialRow(
                                          material: materials[i],
                                          showDivider:
                                              i != materials.length - 1,
                                          isSelected: selectedIds.contains(
                                            materials[i].id,
                                          ),
                                          onDelete: () async {
                                            final m = materials[i];
                                            if (m.status ==
                                                MaterialStatus.indexing) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Cannot delete while indexing.',
                                                  ),
                                                ),
                                              );
                                              return;
                                            }
                                            final choice = await showDialog<String>(
                                              context: context,
                                              builder: (context) {
                                                return AlertDialog(
                                                  title: const Text(
                                                    'Delete material?',
                                                  ),
                                                  content: const Text(
                                                    'Do you also want to delete quizzes that reference this material?',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                            'cancel',
                                                          ),
                                                      child: const Text(
                                                        'Cancel',
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                            'material',
                                                          ),
                                                      child: const Text(
                                                        'Material only',
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                            'all',
                                                          ),
                                                      child: const Text(
                                                        'Material + quizzes',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );

                                            if (choice == null ||
                                                choice == 'cancel') {
                                              return;
                                            }

                                            final messenger =
                                                ScaffoldMessenger.of(context);
                                            try {
                                              if (choice == 'material') {
                                                await ref
                                                    .read(
                                                      courseMaterialListProvider(
                                                        (user.uid, courseId),
                                                      ).notifier,
                                                    )
                                                    .removeWithOption(
                                                      materialId: m.id,
                                                      deleteQuizzes: false,
                                                    );
                                              } else if (choice == 'all') {
                                            await ref
                                                .read(
                                                  courseMaterialListProvider(
                                                    (user.uid, courseId),
                                                  ).notifier,
                                                )
                                                    .removeWithOption(
                                                      materialId: m.id,
                                                      deleteQuizzes: true,
                                                    );
                                              }
                                              messenger.showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Material deleted.',
                                                  ),
                                                ),
                                              );
                                            } catch (e) {
                                              messenger.showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Failed to delete: $e',
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          onToggleSelected: () {
                                            final notifier = ref.read(
                                              selectedMaterialIdsProvider((
                                                user.uid,
                                                courseId,
                                              )).notifier,
                                            );
                                            final current = {...selectedIds};
                                            final id = materials[i].id;
                                            if (current.contains(id)) {
                                              current.remove(id);
                                            } else {
                                              current.add(id);
                                            }
                                            notifier.state = current;
                                          },
                                          onRetryIndex: () async {
                                            final m = materials[i];
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
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
                                    onPressed: () async {
                                      if (selectedIds.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Select at least one material first.',
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      final controller = TextEditingController(
                                        text: '5',
                                      );
                                      final num = await showDialog<int>(
                                        context: context,
                                        builder: (context) {
                                          String? error;
                                          return StatefulBuilder(
                                            builder: (context, setState) {
                                              return AlertDialog(
                                                title: const Text(
                                                  'Generate quiz',
                                                ),
                                                content: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    TextField(
                                                      controller: controller,
                                                      keyboardType:
                                                          TextInputType.number,
                                                      inputFormatters: [
                                                        FilteringTextInputFormatter
                                                            .digitsOnly,
                                                      ],
                                                      decoration:
                                                          const InputDecoration(
                                                            labelText:
                                                                'Number of questions',
                                                          ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    const Text(
                                                      'Max 20 questions.',
                                                      style: TextStyle(
                                                        color: Colors.black54,
                                                      ),
                                                    ),
                                                    if (error != null)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              top: 8,
                                                            ),
                                                        child: Text(
                                                          error!,
                                                          style:
                                                              const TextStyle(
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                          context,
                                                        ).pop(),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      final parsed =
                                                          int.tryParse(
                                                            controller.text
                                                                .trim(),
                                                          );
                                                      if (parsed == null ||
                                                          parsed <= 0) {
                                                        setState(() {
                                                          error =
                                                              'Enter a positive number (max 20).';
                                                        });
                                                        return;
                                                      }
                                                      if (parsed > 20) {
                                                        setState(() {
                                                          error =
                                                              'Maximum is 20.';
                                                        });
                                                        return;
                                                      }
                                                      Navigator.of(
                                                        context,
                                                      ).pop(parsed);
                                                    },
                                                    child: const Text(
                                                      'Generate',
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      );
                                      if (num == null) return;
                                      final messenger = ScaffoldMessenger.of(
                                        context,
                                      );
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text('Generating quiz…'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                      try {
                                        await ref
                                            .read(
                                              quizListProvider((
                                                user.uid,
                                                courseId,
                                              )).notifier,
                                            )
                                            .generate(
                                              materialIds: selectedIds.toList(),
                                              numQuestions: num,
                                            );
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text('Quiz generated.'),
                                          ),
                                        );
                                        if (context.mounted) {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => QuizListPage(
                                                courseId: courseId,
                                          ),
                                        ),
                                      );
                                        }
                                      } catch (e) {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to generate quiz: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _brandBlue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
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
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              QuizListPage(courseId: courseId),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _brandBlue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
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
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ChatPage(courseId: courseId),
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
    if (picked.size > _maxUploadBytes) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File too large. Maximum size is 20 MB.'),
          ),
        );
      }
      return;
    }

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
    required this.isSelected,
    required this.onDelete,
    required this.onToggleSelected,
    required this.onRetryIndex,
  });

  final CourseMaterial material;
  final bool showDivider;
  final bool isSelected;
  final VoidCallback onDelete;
  final VoidCallback onToggleSelected;
  final VoidCallback onRetryIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

              // Toggle checkbox
              IconButton(
                icon: Icon(
                  isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                  color: isSelected ? CourseDetailPage._accentRed : Colors.grey,
                ),
                onPressed: onToggleSelected,
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 0, thickness: 0.5, color: Colors.grey.shade300),
      ],
    );
  }
}
