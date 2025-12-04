class StudyProgress {
  StudyProgress({
    required this.totalCourses,
    required this.totalMaterials,
    required this.totalQuizzes,
    required this.completedQuizzes,
    required this.totalQuizAttempts,
    required this.averageQuizScore,
  });

  final int totalCourses;
  final int totalMaterials; // Count of uploaded/indexed materials
  final int totalQuizzes;
  final int completedQuizzes;
  final int totalQuizAttempts;
  final double averageQuizScore; // 0-100

  /// Overall progress percentage (0-100)
  /// Calculated as quiz completion percentage
  double get overallProgress {
    if (totalQuizzes == 0) return 0.0;
    return (completedQuizzes / totalQuizzes) * 100;
  }

  /// Quiz completion percentage (0-100)
  double get quizCompletionProgress {
    if (totalQuizzes == 0) return 0.0;
    return (completedQuizzes / totalQuizzes) * 100;
  }

  StudyProgress copyWith({
    int? totalCourses,
    int? totalMaterials,
    int? totalQuizzes,
    int? completedQuizzes,
    int? totalQuizAttempts,
    double? averageQuizScore,
  }) {
    return StudyProgress(
      totalCourses: totalCourses ?? this.totalCourses,
      totalMaterials: totalMaterials ?? this.totalMaterials,
      totalQuizzes: totalQuizzes ?? this.totalQuizzes,
      completedQuizzes: completedQuizzes ?? this.completedQuizzes,
      totalQuizAttempts: totalQuizAttempts ?? this.totalQuizAttempts,
      averageQuizScore: averageQuizScore ?? this.averageQuizScore,
    );
  }
}

