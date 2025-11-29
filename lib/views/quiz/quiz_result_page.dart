import 'package:flutter/material.dart';
import '../../models/quiz/quiz.dart';
import '../../models/quiz/quiz_attempt.dart';
import '../../models/quiz/quiz_answer.dart';

class QuizResultPage extends StatelessWidget {
  const QuizResultPage({super.key, required this.quiz, required this.attempt});
  static const Color _navy = Color(0xFF101828);

  final Quiz quiz;
  final QuizAttempt attempt;

  @override
  Widget build(BuildContext context) {
    final percent = attempt.numTotal == 0
        ? 0
        : ((attempt.numCorrect / attempt.numTotal) * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Score: ${attempt.numCorrect}/${attempt.numTotal} ($percent%)',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _navy,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: quiz.questions.length,
            itemBuilder: (context, idx) {
              final q = quiz.questions[idx];
              final ans = attempt.answers.firstWhere(
                (a) => a.questionId == q.id,
                orElse: () {
                  return QuizAnswer(
                    questionId: q.id,
                    selectedOptionIds: const [],
                  );
                },
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
                            isCorrect ? Icons.check_circle : Icons.cancel,
                            color: isCorrect ? Colors.green : Colors.red,
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
                        final chosen = ans.selectedOptionIds.contains(o.id);
                        final correct = o.isCorrect;

                        Color? bgColor;
                        if (chosen && correct) bgColor = Colors.green[50];
                        if (chosen && !correct) bgColor = Colors.red[50];

                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: bgColor,
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
                                const Icon(Icons.check, color: Colors.green),
                              if (!correct) const SizedBox(width: 0),
                              const SizedBox(width: 6),
                              Expanded(child: Text(o.text)),
                            ],
                          ),
                        );
                      }),
                      if (q.explanation != null && q.explanation!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Explanation: ${q.explanation}',
                            style: Theme.of(context).textTheme.bodySmall,
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
    );
  }
}
