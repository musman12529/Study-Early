import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:studyearly/models/quiz/quiz.dart';
import 'package:studyearly/models/quiz/quiz_attempt.dart';
import 'package:studyearly/models/quiz/quiz_answer.dart';

class QuizService {
  QuizService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _quizzesRef(
    String creatorId,
    String courseId,
  ) {
    return _firestore
        .collection('users')
        .doc(creatorId)
        .collection('courses')
        .doc(courseId)
        .collection('quizzes');
  }

  CollectionReference<Map<String, dynamic>> _attemptsRef(
    String creatorId,
    String courseId,
    String quizId,
  ) {
    return _quizzesRef(creatorId, courseId).doc(quizId).collection('attempts');
  }

  Stream<List<Quiz>> watchQuizzes({
    required String creatorId,
    required String courseId,
  }) {
    return _quizzesRef(creatorId, courseId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Quiz.fromMap).toList());
  }

  Future<String> generateQuiz({
    required String creatorId,
    required String courseId,
    required List<String> materialIds,
    required int numQuestions,
  }) async {
    final result =
        await FirebaseFunctions.instanceFor(
          region: 'northamerica-northeast2',
        ).httpsCallable('generateQuiz').call({
          'userId': creatorId,
          'courseId': courseId,
          'materialIds': materialIds,
          'numQuestions': numQuestions,
        });

    final data = result.data as Map<String, dynamic>;
    return data['quizId'] as String;
  }

  Stream<List<QuizAttempt>> watchAttempts({
    required String creatorId,
    required String courseId,
    required String quizId,
  }) {
    return _attemptsRef(creatorId, courseId, quizId)
        .orderBy('startedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(QuizAttempt.fromMap).toList());
  }

  Future<QuizAttempt> createAttempt({
    required String creatorId,
    required String courseId,
    required String quizId,
    required String userId,
  }) async {
    final attempt = QuizAttempt(
      quizId: quizId,
      userId: userId,
      answers: const [],
      numCorrect: 0,
      numTotal: 0,
    );
    await _attemptsRef(
      creatorId,
      courseId,
      quizId,
    ).doc(attempt.id).set(attempt.toMap());
    return attempt;
  }

  Future<void> submitAttempt({
    required String creatorId,
    required String courseId,
    required Quiz quiz,
    required QuizAttempt attempt,
    required List<QuizAnswer> answers,
  }) async {
    int correct = 0;
    for (final answer in answers) {
      final q = quiz.questions.firstWhere(
        (q) => q.id == answer.questionId,
        orElse: () =>
            throw StateError('Question not found: ${answer.questionId}'),
      );
      final correctOptionIds = q.options
          .where((o) => o.isCorrect)
          .map((o) => o.id)
          .toSet();
      final chosen = answer.selectedOptionIds.toSet();
      final isCorrect =
          chosen.length == correctOptionIds.length &&
          chosen.containsAll(correctOptionIds);
      if (isCorrect) correct += 1;
    }

    final updated = attempt.copyWith(
      answers: answers.map((a) {
        final q = quiz.questions.firstWhere((q) => q.id == a.questionId);
        final correctOptionIds = q.options
            .where((o) => o.isCorrect)
            .map((o) => o.id)
            .toSet();
        final chosen = a.selectedOptionIds.toSet();
        final ok =
            chosen.length == correctOptionIds.length &&
            chosen.containsAll(correctOptionIds);
        return a.copyWith(isCorrect: ok);
      }).toList(),
      numCorrect: correct,
      numTotal: quiz.numQuestions,
      completedAt: DateTime.now(),
    );

    await _attemptsRef(
      creatorId,
      quiz.courseId,
      quiz.id,
    ).doc(updated.id).update(updated.toMap());
  }
}
