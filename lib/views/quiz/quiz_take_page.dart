import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/providers/auth_providers.dart';
import '../../controllers/providers/quiz_providers.dart';
import '../../models/quiz/quiz.dart';
import '../../models/quiz/quiz_answer.dart';
import '../../models/quiz/quiz_attempt.dart';

class QuizTakePage extends ConsumerStatefulWidget {
  const QuizTakePage({
    super.key,
    required this.courseId,
    required this.quizId,
  });

  final String courseId;
  final String quizId;

  @override
  ConsumerState<QuizTakePage> createState() => _QuizTakePageState();
}

class _QuizTakePageState extends ConsumerState<QuizTakePage> {
  static const Color _navy = Color(0xFF101828);
  static const Color _accentRed = Color(0xFFFF6B6B);


  int _index = 0;
  final Map<String, Set<String>> _selections = {};
  String? _submittedAttemptId;

  @override
  Widget build(BuildContext context) {
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

        final quizzes =
            ref.watch(quizListProvider((user.uid, widget.courseId)));
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

        // Not ready state
        if (quiz.questions.isEmpty || quiz.status != QuizStatus.ready) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(onBack: () => context.pop()),
                    const SizedBox(height: 24),
                    const Text(
                      'Take Quiz',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: _navy,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Quiz is not ready yet.\nPlease try again later.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
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

        if (_index >= quiz.questions.length) {
          _index = quiz.questions.length - 1;
        }

        final showingResults = submittedAttempt != null;

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(onBack: () => context.pop()),
                  const SizedBox(height: 24),
                  Text(
                    showingResults ? 'Results' : 'Take Quiz',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!showingResults)
                    Text(
                      'Question ${_index + 1} of ${quiz.questions.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: showingResults
                        ? _ResultView(
                            quiz: quiz,
                            attempt: submittedAttempt!,
                          )
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
                  ),
                ],
              ),
            ),
          ),

          // Bottom nav buttons
          bottomNavigationBar: showingResults
              ? null
              : SafeArea(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: _accentRed),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Previous',
                              style: TextStyle(
                                color: _accentRed,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _accentRed,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Next',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              : ElevatedButton.icon(
                                  icon: const Icon(Icons.check),
                                  onPressed: () async {
                                    final answers =
                                        quiz.questions.map((q) {
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
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _accentRed,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  label: const Text(
                                    'Submit',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
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
}

// Shared header used on this page
class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;
  static const Color _navy = Color(0xFF101828);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
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
    );
  }
}

class _QuestionView extends StatelessWidget {
  static const Color _navy = Color(0xFF101828);

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

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            q.prompt,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _navy,
            ),
          ),
          if (multiple) ...[
            const SizedBox(height: 4),
            const Text(
              'Select all that apply',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: q.options.length,
              itemBuilder: (context, idx) {
                final opt = q.options[idx];

                if (multiple) {
                  final checked = selected.contains(opt.id);
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: CheckboxListTile(
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
                    ),
                  );
                } else {
                  final groupValue =
                      selected.isEmpty ? null : selected.first;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: RadioListTile<String>(
                      value: opt.id,
                      groupValue: groupValue,
                      onChanged: (v) {
                        onChanged(q.id, {opt.id});
                      },
                      title: Text(opt.text),
                    ),
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
                            isCorrect
                                ? Icons.check_circle
                                : Icons.cancel,
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
                        final chosen =
                            ans.selectedOptionIds.contains(o.id);
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
                                const Icon(Icons.check,
                                    color: Colors.green),
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

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
