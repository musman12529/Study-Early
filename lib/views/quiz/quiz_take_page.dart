import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/providers/auth_providers.dart';
import '../../controllers/providers/quiz_providers.dart';
import '../../models/quiz/quiz.dart';
import '../../models/quiz/quiz_answer.dart';
import '../../models/quiz/quiz_attempt.dart';

class QuizTakePage extends ConsumerStatefulWidget {
  const QuizTakePage({super.key, required this.courseId, required this.quizId});

  final String courseId;
  final String quizId;

  @override
  ConsumerState<QuizTakePage> createState() => _QuizTakePageState();
}

class _QuizTakePageState extends ConsumerState<QuizTakePage> {
  int _index = 0;
  final Map<String, Set<String>> _selections = {};
  String? _submittedAttemptId;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateChangesProvider);
    return authState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: Text('Not logged in')));
        }

        final quizzes = ref.watch(
          quizListProvider((user.uid, widget.courseId)),
        );
        final quiz = quizzes.firstWhere(
          (q) => q.id == widget.quizId,
          orElse: () => Quiz(
            id: widget.quizId,
            courseId: widget.courseId,
            creatorId: user.uid,
            vectorStoreId: null,
            materialIds: const [],
            numQuestions: 0,
            status: QuizStatus.pending,
            questions: const [],
          ),
        );

        final attempts = ref.watch(
          quizAttemptsProvider((user.uid, widget.courseId, widget.quizId)),
        );
        final submittedAttempt = _submittedAttemptId == null
            ? null
            : attempts.where((a) => a.id == _submittedAttemptId).firstOrNull;

        if (quiz.questions.isEmpty || quiz.status != QuizStatus.ready) {
          return Scaffold(
            appBar: AppBar(title: const Text('Take Quiz')),
            body: const Center(
              child: Text('Quiz is not ready yet. Please try again later.'),
            ),
          );
        }

        if (_index >= quiz.questions.length) {
          _index = quiz.questions.length - 1;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Take Quiz'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          body: submittedAttempt != null
              ? _ResultView(quiz: quiz, attempt: submittedAttempt)
              : _QuestionView(
                  questionIndex: _index,
                  total: quiz.questions.length,
                  quiz: quiz,
                  selections: _selections,
                  onChanged: (qid, choiceIds) {
                    setState(() {
                      _selections[qid] = choiceIds;
                    });
                  },
                ),
          bottomNavigationBar: submittedAttempt != null
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _index > 0
                                ? () {
                                    setState(() {
                                      _index -= 1;
                                    });
                                  }
                                : null,
                            child: const Text('Previous'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _index < quiz.questions.length - 1
                              ? ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _index += 1;
                                    });
                                  },
                                  child: const Text('Next'),
                                )
                              : ElevatedButton.icon(
                                  icon: const Icon(Icons.check),
                                  onPressed: () async {
                                    final answers = quiz.questions.map((q) {
                                      final selected =
                                          _selections[q.id]?.toList() ??
                                          const <String>[];
                                      return QuizAnswer(
                                        questionId: q.id,
                                        selectedOptionIds: selected,
                                      );
                                    }).toList();

                                    final attempt = await ref
                                        .read(
                                          quizAttemptsProvider((
                                            user.uid,
                                            widget.courseId,
                                            widget.quizId,
                                          )).notifier,
                                        )
                                        .startAttempt(userId: user.uid);
                                    setState(() {
                                      _submittedAttemptId = attempt.id;
                                    });
                                    await ref
                                        .read(
                                          quizAttemptsProvider((
                                            user.uid,
                                            widget.courseId,
                                            widget.quizId,
                                          )).notifier,
                                        )
                                        .submit(
                                          quiz: quiz,
                                          attempt: attempt,
                                          answers: answers,
                                        );
                                  },
                                  label: const Text('Submit'),
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

class _QuestionView extends StatelessWidget {
  const _QuestionView({
    required this.questionIndex,
    required this.total,
    required this.quiz,
    required this.selections,
    required this.onChanged,
  });

  final int questionIndex;
  final int total;
  final Quiz quiz;
  final Map<String, Set<String>> selections;
  final void Function(String questionId, Set<String> selectedOptionIds)
  onChanged;

  @override
  Widget build(BuildContext context) {
    final q = quiz.questions[questionIndex];
    final selected = selections[q.id] ?? <String>{};
    final multiple = q.multipleCorrectAllowed;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question ${questionIndex + 1} of $total',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(q.prompt, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: q.options.length,
              itemBuilder: (context, idx) {
                final opt = q.options[idx];
                if (multiple) {
                  final checked = selected.contains(opt.id);
                  return CheckboxListTile(
                    value: checked,
                    onChanged: (v) {
                      final next = Set<String>.from(selected);
                      if (v == true) {
                        next.add(opt.id);
                      } else {
                        next.remove(opt.id);
                      }
                      onChanged(q.id, next);
                    },
                    title: Text(opt.text),
                  );
                } else {
                  // only one selection
                  final groupValue = selected.isEmpty ? null : selected.first;
                  return RadioListTile<String>(
                    value: opt.id,
                    groupValue: groupValue,
                    onChanged: (v) {
                      onChanged(q.id, {opt.id});
                    },
                    title: Text(opt.text),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.quiz, required this.attempt});

  final Quiz quiz;
  final QuizAttempt attempt;

  @override
  Widget build(BuildContext context) {
    final percent = attempt.numTotal == 0
        ? 0
        : ((attempt.numCorrect / attempt.numTotal) * 100).round();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Results', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Score: ${attempt.numCorrect}/${attempt.numTotal} ($percent%)'),
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
                return Card(
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
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...q.options.map((o) {
                          final chosen = ans.selectedOptionIds.contains(o.id);
                          final correct = o.isCorrect;
                          Color? color;
                          if (chosen && correct) color = Colors.green[100];
                          if (chosen && !correct) color = Colors.red[100];
                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(vertical: 2),
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
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
