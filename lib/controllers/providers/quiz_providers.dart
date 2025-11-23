import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyearly/models/quiz/quiz.dart';
import 'package:studyearly/models/quiz/quiz_attempt.dart';
import 'package:studyearly/controllers/notifiers/quiz_notifiers.dart';

final quizListProvider = NotifierProvider.family<
  QuizListNotifier,
  List<Quiz>,
  (String creatorId, String courseId)
>(QuizListNotifier.new);

final quizAttemptsProvider = NotifierProvider.family<
  QuizAttemptsNotifier,
  List<QuizAttempt>,
  (String creatorId, String courseId, String quizId)
>(QuizAttemptsNotifier.new);


