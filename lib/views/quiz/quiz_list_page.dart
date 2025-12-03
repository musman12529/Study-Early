import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/providers/auth_providers.dart';
import '../../controllers/providers/course_providers.dart';
import '../../controllers/providers/quiz_providers.dart';
import '../../models/quiz/quiz.dart';
import '../../controllers/providers/user_providers.dart';
import '../../models/user_profile.dart';
import 'dart:typed_data';
import 'package:printing/printing.dart';
import '../../utils/pdf_export.dart';

class QuizListPage extends ConsumerWidget {
  const QuizListPage({super.key, required this.courseId});

  final String courseId;

  static const Color _navy = Color(0xFF101828);

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete quiz?'),
        content: const Text(
          'This will permanently delete the quiz and all its attempts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

        final quizzes = ref.watch(quizListProvider((user.uid, courseId)));
        final profile = profileState.asData?.value;
        final isProfessor = profile?.role == UserRole.professor;

        final courses = ref.watch(courseListProvider(user.uid));
        String courseTitle;
        if (courses.isEmpty) {
          courseTitle = 'Quizzes';
        } else {
          final course = courses.firstWhere(
            (c) => c.id == courseId,
            orElse: () => courses.first,
          );
          courseTitle = course.title;
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER: back + logo
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
                          Image.asset('asset/logo.png', height: 26),
                          const SizedBox(width: 6),
                        ],
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // PAGE TITLE
                  Text(
                    'Quizzes',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    courseTitle,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),

                  const SizedBox(height: 20),

                  // QUIZ LIST
                  Expanded(
                    child: quizzes.isEmpty
                        ? const Center(
                            child: Text(
                              'No quizzes yet.\nGenerate a quiz from your course materials.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: quizzes.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final q = quizzes[index];

                              final Color statusColor = q.questions.isNotEmpty
                                  ? Colors.green
                                  : Colors.orange;

                              return InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: q.questions.isNotEmpty
                                    ? () {
                                        if (isProfessor) {
                                          context.pushNamed(
                                            'professorQuizView',
                                            pathParameters: {
                                              'courseId': courseId,
                                              'quizId': q.id,
                                            },
                                          );
                                        } else {
                                          context.pushNamed(
                                            'quizTake',
                                            pathParameters: {
                                              'courseId': courseId,
                                              'quizId': q.id,
                                            },
                                          );
                                        }
                                      }
                                    : null,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
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
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.quiz_outlined,
                                        color: statusColor,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              q.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: _navy,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${_formatDateTime(q.createdAt)} - '
                                              '${q.numQuestions} questions - '
                                              '${q.materialIds.length} materials - '
                                              '${q.difficulty.asString}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            // status removed
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'view' &&
                                              q.questions.isNotEmpty) {
                                            context.pushNamed(
                                              'professorQuizView',
                                              pathParameters: {
                                                'courseId': courseId,
                                                'quizId': q.id,
                                              },
                                            );
                                          } else if (value == 'take' &&
                                              q.questions.isNotEmpty) {
                                            context.pushNamed(
                                              'quizTake',
                                              pathParameters: {
                                                'courseId': courseId,
                                                'quizId': q.id,
                                              },
                                            );
                                          } else if (value == 'attempts' &&
                                              !isProfessor) {
                                            context.pushNamed(
                                              'quizAttempts',
                                              pathParameters: {
                                                'courseId': courseId,
                                                'quizId': q.id,
                                              },
                                            );
                                          } else if (value == 'download_quiz') {
                                            // handled in itemBuilder using callback
                                          } else if (value ==
                                              'download_answers') {
                                            // handled in itemBuilder using callback
                                          } else if (value == 'delete') {
                                            _confirmDelete(context).then((
                                              ok,
                                            ) async {
                                              if (ok != true) return;
                                              final messenger =
                                                  ScaffoldMessenger.of(context);
                                              messenger.showSnackBar(
                                                SnackBar(
                                                  content: Row(
                                                    children: const [
                                                      SizedBox(
                                                        width: 16,
                                                        height: 16,
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                            ),
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text('Deleting quiz…'),
                                                    ],
                                                  ),
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
                                                    .remove(quizId: q.id);
                                                messenger.showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Quiz deleted.',
                                                    ),
                                                  ),
                                                );
                                              } catch (e) {
                                                messenger.showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Failed to delete quiz: $e',
                                                    ),
                                                  ),
                                                );
                                              }
                                            });
                                          }
                                        },
                                        itemBuilder: (context) {
                                          if (isProfessor) {
                                            return [
                                              PopupMenuItem(
                                                value: 'view',
                                                enabled: q.questions.isNotEmpty,
                                                child: const Text('View quiz'),
                                              ),
                                              PopupMenuItem(
                                                value: 'download_quiz',
                                                enabled: q.questions.isNotEmpty,
                                                child: const Text(
                                                  'Download quiz PDF',
                                                ),
                                                onTap: () async {
                                                  await _downloadQuizPdf(
                                                    context,
                                                    q,
                                                  );
                                                },
                                              ),
                                              PopupMenuItem(
                                                value: 'download_answers',
                                                enabled: q.questions.isNotEmpty,
                                                child: const Text(
                                                  'Download answers PDF',
                                                ),
                                                onTap: () async {
                                                  await _downloadAnswersPdf(
                                                    context,
                                                    q,
                                                  );
                                                },
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Text(
                                                  'Delete quiz',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ];
                                          } else {
                                            return [
                                              PopupMenuItem(
                                                value: 'take',
                                                enabled: q.questions.isNotEmpty,
                                                child: const Text('Take quiz'),
                                              ),
                                              const PopupMenuItem(
                                                value: 'attempts',
                                                child: Text('View attempts'),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Text(
                                                  'Delete quiz',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ];
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
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
}

Future<void> _downloadQuizPdf(BuildContext context, Quiz quiz) async {
  try {
    final Uint8List bytes = await buildQuizPdf(quiz);
    final name = _sanitizeFileName('${quiz.title}_quiz.pdf');
    await Printing.sharePdf(bytes: bytes, filename: name);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Quiz PDF ready.')));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to prepare PDF: $e')));
    }
  }
}

Future<void> _downloadAnswersPdf(BuildContext context, Quiz quiz) async {
  try {
    final Uint8List bytes = await buildAnswersPdf(quiz);
    final name = _sanitizeFileName('${quiz.title}_answers.pdf');
    await Printing.sharePdf(bytes: bytes, filename: name);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Answer key PDF ready.')));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to prepare PDF: $e')));
    }
  }
}

String _sanitizeFileName(String name) {
  return name.replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_').trim();
}

String _two(int v) => v.toString().padLeft(2, '0');
String _formatDateTime(DateTime d) {
  final local = d.toLocal();
  final y = local.year.toString();
  final m = _two(local.month);
  final day = _two(local.day);
  final hh = _two(local.hour);
  final mm = _two(local.minute);
  return '$y-$m-$day $hh:$mm';
}
