import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers/auth_providers.dart';
import '../../controllers/providers/quiz_providers.dart';
import '../../models/quiz/quiz_answer.dart';

class QuizAttemptDetailPage extends ConsumerWidget {
  const QuizAttemptDetailPage({
    super.key,
    required this.courseId,
    required this.quizId,
    required this.attemptId,
  });

  final String courseId;
  final String quizId;
  final String attemptId;

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

        final quizzes = ref.watch(quizListProvider((user.uid, courseId)));
        final quiz = quizzes.firstWhere(
          (q) => q.id == quizId,
          orElse: () => quizzes.first,
        );

        final attempts = ref.watch(
          quizAttemptsProvider((user.uid, courseId, quizId)),
        );
        final attempt = attempts.firstWhere(
          (a) => a.id == attemptId,
          orElse: () => attempts.first,
        );

        final percent = attempt.numTotal == 0
            ? 0
            : ((attempt.numCorrect / attempt.numTotal) * 100).round();

        return Scaffold(
          appBar: AppBar(title: const Text('Attempt Details')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Score: ${attempt.numCorrect}/${attempt.numTotal} ($percent%)',
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: quiz.questions.length,
                    itemBuilder: (context, idx) {
                      final q = quiz.questions[idx];
                      final ans = attempt.answers.firstWhere(
                        (a) => a.questionId == q.id,
                        orElse: () => QuizAnswer(
                          questionId: q.id,
                          selectedOptionIds: const [],
                        ),
                      );
                      final isCorrect = ans.isCorrect;
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isCorrect
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: isCorrect
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      q.prompt,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...q.options.map((o) {
                                final chosen = ans.selectedOptionIds.contains(
                                  o.id,
                                );
                                final correct = o.isCorrect;
                                Color? color;
                                if (chosen && correct)
                                  color = Colors.green[100];
                                if (chosen && !correct) color = Colors.red[100];
                                return Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: correct
                                          ? Colors.green
                                          : Colors.grey.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      if (correct)
                                        const Icon(
                                          Icons.check,
                                          color: Colors.green,
                                        ),
                                      if (!correct) const SizedBox(width: 0),
                                      const SizedBox(width: 6),
                                      Expanded(child: Text(o.text)),
                                    ],
                                  ),
                                );
                              }),
                              if (q.explanation != null &&
                                  q.explanation!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Explanation: ${q.explanation}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
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
        );
      },
    );
  }
}
