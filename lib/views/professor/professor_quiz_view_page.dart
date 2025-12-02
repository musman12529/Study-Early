import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../controllers/providers/auth_providers.dart';
import '../../controllers/providers/course_providers.dart';
import '../../controllers/providers/quiz_providers.dart';
import '../../controllers/providers/user_providers.dart';
import '../../models/quiz/quiz.dart';
import '../../models/user_profile.dart';
import '../../models/quiz/quiz_question.dart';
import '../../utils/pdf_export.dart';

class ProfessorQuizViewPage extends ConsumerWidget {
  const ProfessorQuizViewPage({
    super.key,
    required this.courseId,
    required this.quizId,
  });
  final String courseId;
  final String quizId;

  static const Color _navy = Color(0xFF101828);

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
        final profile = profileState.asData?.value;
        if (profile == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (profile.role != UserRole.professor) {
          return const Scaffold(
            body: Center(child: Text('Professor access only')),
          );
        }

        final quizzes = ref.watch(quizListProvider((user.uid, courseId)));
        final quiz = quizzes.firstWhere(
          (q) => q.id == quizId,
          orElse: () => Quiz(
            id: 'missing',
            courseId: '',
            creatorId: '',
            vectorStoreId: null,
            materialIds: [],
            numQuestions: 0,
            questions: [],
          ),
        );

        final courses = ref.watch(courseListProvider(user.uid));
        String courseTitle;
        if (courses.isEmpty) {
          courseTitle = '';
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
                  Text(
                    quiz.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: _navy,
                    ),
                  ),
                  if (courseTitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      courseTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: quiz.questions.isEmpty
                                ? null
                                : () => _handleDownloadQuiz(context, quiz),
                            icon: const Icon(Icons.download, size: 18),
                            label: const Text('Quiz PDF'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: quiz.questions.isEmpty
                                ? null
                                : () => _handleDownloadAnswers(context, quiz),
                            icon: const Icon(Icons.download_done, size: 18),
                            label: const Text('Answers PDF'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: quiz.questions.isEmpty
                        ? const Center(
                            child: Text(
                              'No questions generated for this quiz.',
                              style: TextStyle(color: Colors.black54),
                            ),
                          )
                        : ListView.separated(
                            itemCount: quiz.questions.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final q = quiz.questions[index];
                              return _QuestionTile(question: q, index: index);
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

class _QuestionTile extends StatelessWidget {
  const _QuestionTile({required this.question, required this.index});
  final QuizQuestion question;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            'Q${index + 1}. ${question.prompt}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _ProfessorQuizViewPageStyles.navy,
            ),
          ),
          const SizedBox(height: 8),
          for (final opt in question.options)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    opt.isCorrect ? Icons.check_circle : Icons.circle_outlined,
                    size: 16,
                    color: opt.isCorrect ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      opt.text,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: opt.isCorrect
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if ((question.explanation?.trim().isNotEmpty ?? false)) ...[
            const SizedBox(height: 8),
            const Text(
              'Explanation',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _ProfessorQuizViewPageStyles.navy,
              ),
            ),
            Text(question.explanation!, style: const TextStyle(fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

class _ProfessorQuizViewPageStyles {
  static const Color navy = Color(0xFF101828);
}

String _sanitizeFileName(String name) {
  return name.replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_').trim();
}

Future<void> _handleDownloadQuiz(BuildContext context, Quiz quiz) async {
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

Future<void> _handleDownloadAnswers(BuildContext context, Quiz quiz) async {
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
