import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/providers/auth_providers.dart';
import '../controllers/providers/course_material_provider.dart';
import '../controllers/providers/course_providers.dart';
import '../controllers/providers/quiz_providers.dart';
import '../controllers/providers/user_providers.dart';
import '../controllers/providers/material_summary_provider.dart';
import '../models/user_profile.dart';
import '../models/course_material.dart';
import 'widgets/notification_bell_button.dart';
import 'widgets/quiz_generation_options_dialog.dart';
import 'material_summary_page.dart';

enum _DeleteMaterialChoice { materialOnly, materialAndQuizzes }

class CourseDetailPage extends ConsumerStatefulWidget {
  const CourseDetailPage({super.key, required this.courseId});

  final String courseId;

  @override
  ConsumerState<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends ConsumerState<CourseDetailPage> {
  static const Color _brandBlue = Color(0xFF1A73E8);
  static const Color _navy = Color(0xFF101828);
  static const Color _accentRed = Color(0xFFFF6B6B);

  final Set<String> _selectedMaterialIds = {};
  final Set<String> _deletingMaterialIds = {};

  bool _isUploading = false;
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: Text('Not logged in')));
        }

        // Get course title to show as big heading
        final courses = ref.watch(courseListProvider(user.uid));
        final course = courses.firstWhere(
          (c) => c.id == widget.courseId,
          orElse: () => courses.first,
        );

        final materials = ref.watch(
          courseMaterialListProvider((user.uid, widget.courseId)),
        );

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER ROW: back, logo, bell
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => context.pop(),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset('asset/logo.png', height: 26),
                          const SizedBox(width: 6),
                        ],
                      ),
                      NotificationBellButton(
                        userId: user.uid,
                        onPressed: () {
                          context.pushNamed('notifications');
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // COURSE TITLE
                  Text(
                    course.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: _navy,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // "Materials" + plus icon
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
                        onPressed: _isUploading
                            ? null
                            : () async {
                                await _pickUploadAndIndex(
                                  context,
                                  ref,
                                  user,
                                  widget.courseId,
                                );
                              },
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // MAIN CONTENT + BUTTONS
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // MATERIALS CONTAINER
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
                                        _buildMaterialRow(
                                          context,
                                          user.uid,
                                          materials[i],
                                          isLast: i == materials.length - 1,
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
                                    onPressed:
                                        _selectedMaterialIds.isEmpty ||
                                            _isGenerating
                                        ? null
                                        : () async {
                                            final options =
                                                await _promptNumQuestions(
                                                  context,
                                                );
                                            if (options == null) return;
                                            await _generateQuiz(
                                              context,
                                              ref,
                                              user.uid,
                                              options,
                                            );
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _brandBlue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isGenerating
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : const Text(
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
                                      context.pushNamed(
                                        'quizList',
                                        pathParameters: {
                                          'courseId': widget.courseId,
                                        },
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
                                context.pushNamed(
                                  'chat',
                                  pathParameters: {'courseId': widget.courseId},
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

  // Single material row styled like the mockup
  Widget _buildMaterialRow(
    BuildContext context,
    String userId,
    CourseMaterial m, {
    required bool isLast,
  }) {
    final isSelected = _selectedMaterialIds.contains(m.id);
    final isDeleting = _deletingMaterialIds.contains(m.id);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // PDF badge
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
                  m.fileName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF101828),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Summary button (only for indexed materials)
              if (m.status == MaterialStatus.indexed)
                IconButton(
                  tooltip: 'View summary',
                  icon: const Icon(Icons.summarize_outlined),
                  color: _brandBlue,
                  onPressed: () {
                    _showSummary(context, ref, user.uid, m);
                  },
                ),

              // Retry if error
              if (m.status == MaterialStatus.error)
                IconButton(
                  tooltip: 'Retry indexing',
                  icon: const Icon(Icons.refresh),
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Retrying indexing...'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                    await ref
                        .read(
                          courseMaterialListProvider((
                            userId,
                            widget.courseId,
                          )).notifier,
                        )
                        .retry(m);
                  },
                ),

              // Delete icon or spinner
              isDeleting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        if (m.status == MaterialStatus.indexing) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cannot delete while indexing.'),
                            ),
                          );
                          return;
                        }

                        final choice = await showDialog<_DeleteMaterialChoice>(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Delete material?'),
                              content: const Text(
                                'Do you also want to delete quizzes that reference this material?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => context.pop(null),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => context.pop(
                                    _DeleteMaterialChoice.materialOnly,
                                  ),
                                  child: const Text('Material only'),
                                ),
                                TextButton(
                                  onPressed: () => context.pop(
                                    _DeleteMaterialChoice.materialAndQuizzes,
                                  ),
                                  child: const Text(
                                    'Material + quizzes',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            );
                          },
                        );

                        if (choice == null) return;

                        final deleteQuizzes =
                            choice == _DeleteMaterialChoice.materialAndQuizzes;

                        setState(() {
                          _deletingMaterialIds.add(m.id);
                        });

                        try {
                          await ref
                              .read(
                                courseMaterialListProvider((
                                  userId,
                                  widget.courseId,
                                )).notifier,
                              )
                              .removeWithOption(
                                materialId: m.id,
                                deleteQuizzes: deleteQuizzes,
                              );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Material deleted.'),
                              ),
                            );
                          }
                          setState(() {
                            _selectedMaterialIds.remove(m.id);
                          });
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to delete material: $e'),
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() {
                              _deletingMaterialIds.remove(m.id);
                            });
                          }
                        }
                      },
                    ),

              // Selection toggle (pink checkbox-like)
              IconButton(
                icon: Icon(
                  isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                  color: isSelected ? _accentRed : Colors.grey,
                ),
                onPressed: m.status == MaterialStatus.indexed
                    ? () {
                        setState(() {
                          if (isSelected) {
                            _selectedMaterialIds.remove(m.id);
                          } else {
                            _selectedMaterialIds.add(m.id);
                          }
                        });
                      }
                    : null,
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 0, thickness: 0.5, color: Colors.grey.shade300),
      ],
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
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>?> _promptNumQuestions(
    BuildContext context,
  ) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const QuizGenerationOptionsDialog(),
    );
  }

  Future<void> _generateQuiz(
    BuildContext context,
    WidgetRef ref,
    String creatorId,
    Map<String, dynamic> options,
  ) async {
    if (_selectedMaterialIds.isEmpty) return;
    try {
      setState(() {
        _isGenerating = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Quiz generation started. It will appear in View Quizzes once ready.',
            ),
          ),
        );
      }

      final profile = ref.read(userProfileStreamProvider).asData?.value;
      final roleStr = (profile?.role == UserRole.professor)
          ? 'professor'
          : null;

      await ref
          .read(quizListProvider((creatorId, widget.courseId)).notifier)
          .generate(
            materialIds: _selectedMaterialIds.toList(),
            numQuestions: (options['numQuestions'] as int).clamp(1, 20),
            instructions: options['instructions'] as String?,
            difficulty: options['difficulty'] as String?,
            includeExplanations: options['includeExplanations'] as bool?,
            temperature: (options['temperature'] as num?)?.toDouble(),
            allowMultipleCorrect: options['allowMultipleCorrect'] as bool?,
            role: roleStr,
          );

      setState(() {
        _selectedMaterialIds.clear();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  void _showSummary(
    BuildContext context,
    WidgetRef ref,
    String userId,
    CourseMaterial material,
  ) {
    final courses = ref.read(courseListProvider(userId));
    final course = courses.firstWhere(
      (c) => c.id == widget.courseId,
      orElse: () => courses.first,
    );

    if (course.vectorStoreId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Course vector store not available.'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MaterialSummaryPage(
          userId: userId,
          courseId: widget.courseId,
          materialId: material.id,
          materialIds: [material.id],
          materialName: material.fileName,
          vectorStoreId: course.vectorStoreId!,
        ),
      ),
    );
  }
}
