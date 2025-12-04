class StudyProgress {
  StudyProgress({
    required this.totalCourses,
    required this.totalMaterials,
    required this.indexedMaterials,
    required this.totalQuizzes,
    required this.completedQuizzes,
    required this.totalQuizAttempts,
    required this.averageQuizScore,
  });

  final int totalCourses;
  final int totalMaterials;
  final int indexedMaterials;
  final int totalQuizzes;
  final int completedQuizzes;
  final int totalQuizAttempts;
  final double averageQuizScore; // 0-100

  /// Overall progress percentage (0-100)
  /// Calculated as weighted average of:
  /// - Materials progress: indexedMaterials / totalMaterials (40% weight)
  /// - Quiz completion: completedQuizzes / totalQuizzes (60% weight)
  double get overallProgress {
    if (totalMaterials == 0 && totalQuizzes == 0) return 0.0;

    double materialsProgress = 0.0;
    if (totalMaterials > 0) {
      materialsProgress = (indexedMaterials / totalMaterials) * 100;
    }

    double quizProgress = 0.0;
    if (totalQuizzes > 0) {
      quizProgress = (completedQuizzes / totalQuizzes) * 100;
    }

    // Weighted average: 40% materials, 60% quizzes
    if (totalMaterials > 0 && totalQuizzes > 0) {
      return (materialsProgress * 0.4) + (quizProgress * 0.6);
    } else if (totalMaterials > 0) {
      return materialsProgress;
    } else {
      return quizProgress;
    }
  }

  /// Materials progress percentage (0-100)
  double get materialsProgress {
    if (totalMaterials == 0) return 0.0;
    return (indexedMaterials / totalMaterials) * 100;
  }

  /// Quiz completion percentage (0-100)
  double get quizCompletionProgress {
    if (totalQuizzes == 0) return 0.0;
    return (completedQuizzes / totalQuizzes) * 100;
  }

  StudyProgress copyWith({
    int? totalCourses,
    int? totalMaterials,
    int? indexedMaterials,
    int? totalQuizzes,
    int? completedQuizzes,
    int? totalQuizAttempts,
    double? averageQuizScore,
  }) {
    return StudyProgress(
      totalCourses: totalCourses ?? this.totalCourses,
      totalMaterials: totalMaterials ?? this.totalMaterials,
      indexedMaterials: indexedMaterials ?? this.indexedMaterials,
      totalQuizzes: totalQuizzes ?? this.totalQuizzes,
      completedQuizzes: completedQuizzes ?? this.completedQuizzes,
      totalQuizAttempts: totalQuizAttempts ?? this.totalQuizAttempts,
      averageQuizScore: averageQuizScore ?? this.averageQuizScore,
    );
  }
}

