import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/providers/auth_providers.dart';
import '../../controllers/providers/quiz_providers.dart';
import '../../models/quiz/quiz.dart';

class QuizListPage extends ConsumerWidget {
  const QuizListPage({super.key, required this.courseId});

  final String courseId;

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

        final quizzes = ref.watch(quizListProvider((user.uid, courseId)));

        return Scaffold(
          appBar: AppBar(title: const Text('Quizzes')),
          body: quizzes.isEmpty
              ? const Center(child: Text('No quizzes yet'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: quizzes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final q = quizzes[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          Icons.quiz_outlined,
                          color: q.status == QuizStatus.ready
                              ? Colors.green
                              : (q.status == QuizStatus.error
                                    ? Colors.red
                                    : Colors.orange),
                        ),
                        title: Text(
                          q.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${_formatDateTime(q.createdAt)} • '
                          '${q.numQuestions} questions • '
                          '${q.materialIds.length} materials • '
                          'Status: ${q.status.asString}',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'take' &&
                                q.status == QuizStatus.ready) {
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
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'take',
                              enabled: q.status == QuizStatus.ready,
                              child: const Text('Take quiz'),
                            ),
                            const PopupMenuItem(
                              value: 'attempts',
                              child: Text('View attempts'),
                            ),
                          ],
                        ),
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
                      ),
                    );
                  },
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
