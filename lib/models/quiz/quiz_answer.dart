class QuizAnswer {
  final String questionId;
  final List<String> selectedOptionIds;
  final bool isCorrect;

  QuizAnswer({
    required this.questionId,
    required this.selectedOptionIds,
    this.isCorrect = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'selectedOptionIds': selectedOptionIds,
      'isCorrect': isCorrect,
    };
  }

  static QuizAnswer fromMap(Map<String, dynamic> map) {
    return QuizAnswer(
      questionId: map['questionId'],
      selectedOptionIds: (map['selectedOptionIds'] as List<dynamic>? ?? [])
          .cast<String>(),
      isCorrect: map['isCorrect'] ?? false,
    );
  }

  QuizAnswer copyWith({List<String>? selectedOptionIds, bool? isCorrect}) {
    return QuizAnswer(
      questionId: questionId,
      selectedOptionIds: selectedOptionIds ?? this.selectedOptionIds,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }
}
