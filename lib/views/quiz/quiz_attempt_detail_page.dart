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

  static const Color _navy = Color(0xFF101828);
  static const Color _brandBlue = Color(0xFF1A73E8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) =>
          Scaffold(body: Center(child: Text('Error: $err'))),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Not logged in')),
          );
        }

        final quizzes = ref.watch(quizListProvider((user.uid, courseId)));
        if (quizzes.isEmpty) {
          return _simpleMessageScaffold(
            context,
            'Attempt Details',
            'Quiz not found.',
          );
        }

        final quiz = quizzes.firstWhere(
          (q) => q.id == quizId,
          orElse: () => quizzes.first,
        );

        final attempts = ref.watch(
          quizAttemptsProvider((user.uid, courseId, quizId)),
        );
        if (attempts.isEmpty) {
          return _simpleMessageScaffold(
            context,
            'Attempt Details',
            'Attempt not found.',
          );
        }

        final attempt = attempts.firstWhere(
          (a) => a.id == attemptId,
          orElse: () => attempts.first,
        );

        final percent = attempt.numTotal == 0
            ? 0
            : ((attempt.numCorrect / attempt.numTotal) * 100).round();

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER: back + StudyEarly logo
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
                      const SizedBox(width: 48), // spacer
                    ],
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Attempt Details',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    quiz.title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Score: ${attempt.numCorrect}/${attempt.numTotal} ($percent%)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _brandBlue,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // QUESTIONS + ANSWERS
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

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
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
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: _navy,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...q.options.map((o) {
                                  final chosen = ans.selectedOptionIds
                                      .contains(o.id);
                                  final correct = o.isCorrect;

                                  Color? color;
                                  if (chosen && correct) {
                                    color = Colors.green[50];
                                  } else if (chosen && !correct) {
                                    color = Colors.red[50];
                                  }

                                  return Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(8),
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
                                        if (!correct)
                                          const SizedBox(width: 0),
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
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
          ),
        );
      },
    );
  }

  // Fallback simple scaffold if quiz/attempt not found
  Scaffold _simpleMessageScaffold(
    BuildContext context,
    String title,
    String message,
  ) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: _navy,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
