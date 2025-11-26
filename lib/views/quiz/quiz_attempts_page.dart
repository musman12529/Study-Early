import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/providers/auth_providers.dart';
import '../../controllers/providers/quiz_providers.dart';

class QuizAttemptsPage extends ConsumerWidget {
  const QuizAttemptsPage({
    super.key,
    required this.courseId,
    required this.quizId,
  });

  final String courseId;
  final String quizId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: Text('Not logged in')));
        }

        final attempts = ref.watch(
          quizAttemptsProvider((user.uid, courseId, quizId)),
        );
        final myAttempts = attempts.where((a) => a.userId == user.uid).toList()
          ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

        return Scaffold(
          appBar: AppBar(title: const Text('My Attempts')),
          body: myAttempts.isEmpty
              ? const Center(child: Text('No attempts yet'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: myAttempts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final a = myAttempts[index];
                    final when = _formatDateTime(a.completedAt ?? a.startedAt);
                    final score = '${a.numCorrect}/${a.numTotal}';
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.history),
                        title: Text('Attempt • $when'),
                        subtitle: Text('Score: $score'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          context.pushNamed(
                            'quizAttemptDetail',
                            pathParameters: {
                              'courseId': courseId,
                              'quizId': quizId,
                              'attemptId': a.id,
                            },
                          );
                        },
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
