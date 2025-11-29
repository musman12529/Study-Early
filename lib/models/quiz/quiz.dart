import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'quiz_question.dart';

enum QuizDifficulty { easy, medium, hard, mixed }

extension QuizDifficultyHelper on QuizDifficulty {
  static QuizDifficulty fromString(String? value) {
    switch (value) {
      case 'Easy':
        return QuizDifficulty.easy;
      case 'Medium':
        return QuizDifficulty.medium;
      case 'Hard':
        return QuizDifficulty.hard;
      case 'Mixed':
      default:
        return QuizDifficulty.mixed;
    }
  }

  String get asString {
    switch (this) {
      case QuizDifficulty.easy:
        return 'Easy';
      case QuizDifficulty.medium:
        return 'Medium';
      case QuizDifficulty.hard:
        return 'Hard';
      case QuizDifficulty.mixed:
        return 'Mixed';
    }
  }
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
  final List<QuizQuestion> questions;

  // Generation options
  final String? instructions;
  final QuizDifficulty difficulty;
  final bool includeExplanations;
  final double temperature;

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
    this.questions = const [],
    this.instructions,
    this.difficulty = QuizDifficulty.mixed,
    this.includeExplanations = true,
    this.temperature = 0.5,
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
      'questions': questions.map((q) => q.toMap()).toList(),
      'instructions': instructions,
      'difficulty': difficulty.asString,
      'includeExplanations': includeExplanations,
      'temperature': temperature,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static Quiz fromMap(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data();
    final rawQuestions = (map['questions'] as List<dynamic>? ?? []);
    final createdAtRaw = map['createdAt'];
    final updatedAtRaw = map['updatedAt'];
    final createdAtTs = createdAtRaw is Timestamp
        ? createdAtRaw
        : Timestamp.fromDate(DateTime.now());
    final updatedAtTs = updatedAtRaw is Timestamp
        ? updatedAtRaw
        : Timestamp.fromDate(DateTime.now());
    return Quiz(
      id: map['id'],
      courseId: map['courseId'],
      creatorId: map['creatorId'],
      title: (map['title'] as String?) ?? 'Untitled Quiz',
      vectorStoreId: map['vectorStoreId'],
      materialIds: ((map['materialIds'] as List<dynamic>? ?? []).map(
        (e) => e.toString(),
      )).toList(),
      numQuestions: (map['numQuestions'] as num?)?.toInt() ?? 0,
      questions: rawQuestions
          .map((q) => QuizQuestion.fromMap((q as Map<String, dynamic>)))
          .toList(),
      instructions: map['instructions'] as String?,
      difficulty: QuizDifficultyHelper.fromString(map['difficulty'] as String?),
      includeExplanations: (map['includeExplanations'] as bool?) ?? true,
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.5,
      createdAt: createdAtTs.toDate(),
      updatedAt: updatedAtTs.toDate(),
    );
  }

  Quiz copyWith({
    String? title,
    String? vectorStoreId,
    List<String>? materialIds,
    int? numQuestions,
    List<QuizQuestion>? questions,
    String? instructions,
    QuizDifficulty? difficulty,
    bool? includeExplanations,
    double? temperature,
  }) {
    return Quiz(
      id: id,
      courseId: courseId,
      creatorId: creatorId,
      title: title ?? this.title,
      vectorStoreId: vectorStoreId ?? this.vectorStoreId,
      materialIds: materialIds ?? this.materialIds,
      numQuestions: numQuestions ?? this.numQuestions,
      questions: questions ?? this.questions,
      instructions: instructions ?? this.instructions,
      difficulty: difficulty ?? this.difficulty,
      includeExplanations: includeExplanations ?? this.includeExplanations,
      temperature: temperature ?? this.temperature,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
