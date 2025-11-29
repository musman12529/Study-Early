import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:studyearly/controllers/services/quiz_service.dart';
import 'package:studyearly/models/quiz/quiz.dart';
import 'package:studyearly/models/quiz/quiz_attempt.dart';
import 'package:studyearly/models/quiz/quiz_answer.dart';

class QuizListNotifier
    extends FamilyNotifier<List<Quiz>, (String creatorId, String courseId)> {
  late final QuizService _service;
  StreamSubscription<List<Quiz>>? _subscription;

  @override
  List<Quiz> build((String creatorId, String courseId) args) {
    final creatorId = args.$1;
    final courseId = args.$2;

    _service = QuizService(FirebaseFirestore.instance);

    state = const [];

    _subscription?.cancel();
    _subscription = _service
        .watchQuizzes(creatorId: creatorId, courseId: courseId)
        .listen((quizzes) => state = quizzes);

    ref.onDispose(() => _subscription?.cancel());

    return state;
  }

  Future<String> generate({
    required List<String> materialIds,
    required int numQuestions,
    String? instructions,
    String? difficulty,
    bool? includeExplanations,
    double? temperature,
    bool? allowMultipleCorrect,
  }) async {
    final creatorId = arg.$1;
    final courseId = arg.$2;
    return _service.generateQuiz(
      creatorId: creatorId,
      courseId: courseId,
      materialIds: materialIds,
      numQuestions: numQuestions,
      instructions: instructions,
      difficulty: difficulty,
      includeExplanations: includeExplanations,
      temperature: temperature,
      allowMultipleCorrect: allowMultipleCorrect,
    );
  }

  Future<void> remove({required String quizId}) async {
    final creatorId = arg.$1;
    final courseId = arg.$2;
    await _service.deleteQuiz(
      creatorId: creatorId,
      courseId: courseId,
      quizId: quizId,
    );
  }
}

class QuizAttemptsNotifier
    extends
        FamilyNotifier<
          List<QuizAttempt>,
          (String creatorId, String courseId, String quizId)
        > {
  late final QuizService _service;
  StreamSubscription<List<QuizAttempt>>? _subscription;

  @override
  List<QuizAttempt> build((String, String, String) args) {
    final creatorId = args.$1;
    final courseId = args.$2;
    final quizId = args.$3;

    _service = QuizService(FirebaseFirestore.instance);

    state = const [];

    _subscription?.cancel();
    _subscription = _service
        .watchAttempts(creatorId: creatorId, courseId: courseId, quizId: quizId)
        .listen((attempts) => state = attempts);

    ref.onDispose(() => _subscription?.cancel());
    return state;
  }

  Future<QuizAttempt> startAttempt({required String userId}) async {
    final creatorId = arg.$1;
    final courseId = arg.$2;
    final quizId = arg.$3;
    return _service.createAttempt(
      creatorId: creatorId,
      courseId: courseId,
      quizId: quizId,
      userId: userId,
    );
  }

  Future<void> submit({
    required Quiz quiz,
    required QuizAttempt attempt,
    required List<QuizAnswer> answers,
  }) async {
    final creatorId = arg.$1;
    final courseId = arg.$2;
    await _service.submitAttempt(
      creatorId: creatorId,
      courseId: courseId,
      quiz: quiz,
      attempt: attempt,
      answers: answers,
    );
  }
}
