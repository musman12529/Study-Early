import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'quiz_answer.dart';

class QuizAttempt {
  final String id;
  final String quizId;
  final String userId;

  /// Answers selected by the user for this attempt
  final List<QuizAnswer> answers;

  /// Aggregate results for quick display
  final int numCorrect;
  final int numTotal;

  final DateTime startedAt;
  final DateTime? completedAt;
  final DateTime updatedAt;

  QuizAttempt({
    String? id,
    required this.quizId,
    required this.userId,
    this.answers = const [],
    this.numCorrect = 0,
    this.numTotal = 0,
    DateTime? startedAt,
    this.completedAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       startedAt = startedAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quizId': quizId,
      'userId': userId,
      'answers': answers.map((a) => a.toMap()).toList(),
      'numCorrect': numCorrect,
      'numTotal': numTotal,
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static QuizAttempt fromMap(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data();
    final rawAnswers = (map['answers'] as List<dynamic>? ?? []);
    return QuizAttempt(
      id: map['id'],
      quizId: map['quizId'],
      userId: map['userId'],
      answers: rawAnswers
          .map((a) => QuizAnswer.fromMap((a as Map<String, dynamic>)))
          .toList(),
      numCorrect: map['numCorrect'] ?? 0,
      numTotal: map['numTotal'] ?? 0,
      startedAt: (map['startedAt'] as Timestamp).toDate(),
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  QuizAttempt copyWith({
    List<QuizAnswer>? answers,
    int? numCorrect,
    int? numTotal,
    DateTime? completedAt,
  }) {
    return QuizAttempt(
      id: id,
      quizId: quizId,
      userId: userId,
      answers: answers ?? this.answers,
      numCorrect: numCorrect ?? this.numCorrect,
      numTotal: numTotal ?? this.numTotal,
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: DateTime.now(),
    );
  }
}
