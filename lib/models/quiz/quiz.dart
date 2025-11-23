import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'quiz_question.dart';

enum QuizStatus { pending, generating, ready, error }

extension QuizStatusHelper on QuizStatus {
  static QuizStatus fromString(String? value) {
    switch (value) {
      case 'generating':
        return QuizStatus.generating;
      case 'ready':
        return QuizStatus.ready;
      case 'error':
        return QuizStatus.error;
      default:
        return QuizStatus.pending;
    }
  }

  String get asString => toString().split('.').last;
}

class Quiz {
  final String id;
  final String courseId;
  final String creatorId;
  final String title;

  /// Snapshot of the vector store used for generation (from Course.vectorStoreId)
  final String? vectorStoreId;

  /// CourseMaterial IDs used to generate this quiz
  final List<String> materialIds;

  final int numQuestions;
  final QuizStatus status;
  final List<QuizQuestion> questions;

  final DateTime createdAt;
  final DateTime updatedAt;

  Quiz({
    String? id,
    required this.courseId,
    required this.creatorId,
    String? title,
    required this.vectorStoreId,
    required this.materialIds,
    required this.numQuestions,
    this.status = QuizStatus.pending,
    this.questions = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       title = title ?? 'Untitled Quiz',
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'creatorId': creatorId,
      'title': title,
      'vectorStoreId': vectorStoreId,
      'materialIds': materialIds,
      'numQuestions': numQuestions,
      'status': status.asString,
      'questions': questions.map((q) => q.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static Quiz fromMap(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data();
    final rawQuestions = (map['questions'] as List<dynamic>? ?? []);
    return Quiz(
      id: map['id'],
      courseId: map['courseId'],
      creatorId: map['creatorId'],
      title: (map['title'] as String?) ?? 'Untitled Quiz',
      vectorStoreId: map['vectorStoreId'],
      materialIds: (map['materialIds'] as List<dynamic>? ?? []).cast<String>(),
      numQuestions: map['numQuestions'] ?? 0,
      status: QuizStatusHelper.fromString(map['status']),
      questions: rawQuestions
          .map((q) => QuizQuestion.fromMap((q as Map<String, dynamic>)))
          .toList(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Quiz copyWith({
    String? title,
    String? vectorStoreId,
    List<String>? materialIds,
    int? numQuestions,
    QuizStatus? status,
    List<QuizQuestion>? questions,
  }) {
    return Quiz(
      id: id,
      courseId: courseId,
      creatorId: creatorId,
      title: title ?? this.title,
      vectorStoreId: vectorStoreId ?? this.vectorStoreId,
      materialIds: materialIds ?? this.materialIds,
      numQuestions: numQuestions ?? this.numQuestions,
      status: status ?? this.status,
      questions: questions ?? this.questions,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
