import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/providers/auth_providers.dart';
import '../controllers/providers/course_material_provider.dart';
import '../controllers/providers/quiz_providers.dart';
import '../models/course_material.dart';

enum _DeleteMaterialChoice { materialOnly, materialAndQuizzes }

class CourseDetailPage extends ConsumerStatefulWidget {
  const CourseDetailPage({super.key, required this.courseId});

  final String courseId;

  @override
  ConsumerState<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends ConsumerState<CourseDetailPage> {
  final Set<String> _selectedMaterialIds = {};
  bool _isUploading = false;
  bool _isGenerating = false;
  final Set<String> _deletingMaterialIds = {};
  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
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
          courseMaterialListProvider((user.uid, widget.courseId)),
        );

        return Scaffold(
          appBar: AppBar(title: const Text('Course Materials')),
          body: materials.isEmpty
              ? const Center(child: Text('No materials yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: materials.length,
                  itemBuilder: (context, index) {
                    final m = materials[index];
                    final isIndexed = m.status == MaterialStatus.indexed;
                    final isSelected = _selectedMaterialIds.contains(m.id);
                    return Card(
                      child: ListTile(
                        leading: Checkbox(
                          value: isSelected,
                          onChanged: isIndexed
                              ? (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _selectedMaterialIds.add(m.id);
                                    } else {
                                      _selectedMaterialIds.remove(m.id);
                                    }
                                  });
                                }
                              : null,
                        ),
                        title: Text(m.fileName),
                        subtitle: Text('Status: ${m.status.asString}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (m.status == MaterialStatus.error)
                              IconButton(
                                tooltip: 'Retry indexing',
                                icon: const Icon(Icons.refresh),
                                onPressed: () async {
                                  // Optional: quick feedback
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Retrying indexing...'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                  await ref
                                      .read(
                                        courseMaterialListProvider((
                                          user.uid,
                                          widget.courseId,
                                        )).notifier,
                                      )
                                      .retry(m);
                                },
                              ),
                            const SizedBox(width: 8),
                            _deletingMaterialIds.contains(m.id)
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () async {
                                      if (m.status == MaterialStatus.indexing) {
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
                                      final choice =
                                          await showDialog<
                                            _DeleteMaterialChoice
                                          >(
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
                                                          null,
                                                        ),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          context,
                                                          _DeleteMaterialChoice
                                                              .materialOnly,
                                                        ),
                                                    child: const Text(
                                                      'Material only',
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          context,
                                                          _DeleteMaterialChoice
                                                              .materialAndQuizzes,
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
                                      if (choice == null) return;
                                      final deleteQuizzes =
                                          choice ==
                                          _DeleteMaterialChoice
                                              .materialAndQuizzes;
                                      setState(() {
                                        _deletingMaterialIds.add(m.id);
                                      });
                                      try {
                                        await ref
                                            .read(
                                              courseMaterialListProvider((
                                                user.uid,
                                                widget.courseId,
                                              )).notifier,
                                            )
                                            .removeWithOption(
                                              materialId: m.id,
                                              deleteQuizzes: deleteQuizzes,
                                            );
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Material deleted.',
                                              ),
                                            ),
                                          );
                                        }
                                        setState(() {
                                          _selectedMaterialIds.remove(m.id);
                                        });
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Failed to delete material: $e',
                                              ),
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
                          ],
                        ),
                      ),
                    );
                  },
                ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _selectedMaterialIds.isEmpty || _isGenerating
                          ? null
                          : () async {
                              await _generateQuiz(context, ref, user.uid);
                            },
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.quiz_outlined),
                      label: Text(
                        _isGenerating
                            ? 'Generating…'
                            : (_selectedMaterialIds.isEmpty
                                  ? 'Select materials to generate quiz'
                                  : 'Generate Quiz (${_selectedMaterialIds.length} selected)'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () {
                        context.pushNamed(
                          'quizList',
                          pathParameters: {'courseId': widget.courseId},
                        );
                      },
                      icon: const Icon(Icons.list_alt_outlined),
                      label: const Text('View Quizzes'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
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
            icon: _isUploading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file),
            label: Text(_isUploading ? 'Uploading…' : 'Add PDF'),
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
    );

    if (result == null) return;

    final picked = result.files.single;

    try {
      setState(() {
        _isUploading = true;
      });
      await ref
          .read(courseMaterialListProvider((user.uid, courseId)).notifier)
          .uploadAndIndex(fileName: picked.name, filePath: picked.path!);

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

  Future<void> _generateQuiz(
    BuildContext context,
    WidgetRef ref,
    String creatorId,
  ) async {
    if (_selectedMaterialIds.isEmpty) return;
    try {
      setState(() {
        _isGenerating = true;
      });
      // Default to 10 questions for now
      final quizId = await ref
          .read(quizListProvider((creatorId, widget.courseId)).notifier)
          .generate(
            materialIds: _selectedMaterialIds.toList(),
            numQuestions: 10,
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Quiz generated: $quizId')));
      }
      setState(() {
        _selectedMaterialIds.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to generate quiz: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }
}
