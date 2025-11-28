import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/providers/auth_providers.dart';
import '../../controllers/providers/course_providers.dart';
import '../../controllers/providers/quiz_providers.dart';
import '../../models/quiz/quiz.dart';

class QuizListPage extends ConsumerWidget {
  const QuizListPage({super.key, required this.courseId});

  final String courseId;

  static const Color _brandBlue = Color(0xFF1A73E8);
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

    return authState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) =>
          Scaffold(body: Center(child: Text('Error: $err'))),
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: Text('Not logged in')));
        }

        final quizzes = ref.watch(quizListProvider((user.uid, courseId)));

        // Get course title if we have it, otherwise just show "Quizzes"
        final courses = ref.watch(courseListProvider(user.uid));
        // Get course title if we have it, otherwise just show "Quizzes"
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                          Image.asset(
                            'asset/logo.png',
                            height: 26,
                          ),
                          const SizedBox(width: 6),
                        ],
                      ),
                      const SizedBox(width: 48), // spacer to balance layout
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
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
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

                              final Color statusColor;
                              if (q.status == QuizStatus.ready) {
                                statusColor = Colors.green;
                              } else if (q.status == QuizStatus.error) {
                                statusColor = Colors.red;
                              } else {
                                statusColor = Colors.orange;
                              }

                              return InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: q.status == QuizStatus.ready
                                    ? () {
                                        context.pushNamed(
                                          'quizTake',
                                          pathParameters: {
                                            'courseId': courseId,
                                            'quizId': q.id,
                                          },
                                        );
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
                                        color:
                                            Colors.black.withOpacity(0.03),
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
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: _navy,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${_formatDateTime(q.createdAt)} • '
                                              '${q.numQuestions} questions • '
                                              '${q.materialIds.length} materials',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Status: ${q.status.asString}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: statusColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'take' &&
                                              q.status ==
                                                  QuizStatus.ready) {
                                            context.pushNamed(
                                              'quizTake',
                                              pathParameters: {
                                                'courseId': courseId,
                                                'quizId': q.id,
                                              },
                                            );
                                          } else if (value == 'attempts') {
                                            context.pushNamed(
                                              'quizAttempts',
                                              pathParameters: {
                                                'courseId': courseId,
                                                'quizId': q.id,
                                              },
                                            );
                                          } else if (value == 'delete') {
                                            _confirmDelete(context)
                                                .then((ok) async {
                                              if (ok != true) return;
                                              final messenger =
                                                  ScaffoldMessenger.of(
                                                context,
                                              );
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
                                                      Text(
                                                        'Deleting quiz…',
                                                      ),
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
                                                        'Quiz deleted.'),
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
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: 'take',
                                            enabled: q.status ==
                                                QuizStatus.ready,
                                            child:
                                                const Text('Take quiz'),
                                          ),
                                          const PopupMenuItem(
                                            value: 'attempts',
                                            child:
                                                Text('View attempts'),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Text(
                                              'Delete quiz',
                                              style: TextStyle(
                                                  color: Colors.red),
                                            ),
                                          ),
                                        ],
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
