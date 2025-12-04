import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/study_progress.dart';
import '../../models/course_material.dart';

class StudyProgressService {
  StudyProgressService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Calculate study progress for a user across all courses
  Future<StudyProgress> calculateProgress(String userId) async {
    // Get all courses
    final coursesSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('courses')
        .get();

      int totalCourses = coursesSnapshot.docs.length;
      int totalMaterials = 0;
      int totalQuizzes = 0;
      int completedQuizzes = 0;
      int totalQuizAttempts = 0;
      int totalQuizScore = 0; // Sum of scores for average calculation

    // Iterate through each course
    for (final courseDoc in coursesSnapshot.docs) {
      final courseId = courseDoc.id;

      // Count materials (uploaded or indexed)
      final materialsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('courses')
          .doc(courseId)
          .collection('materials')
          .get();

      for (final materialDoc in materialsSnapshot.docs) {
        final status = materialDoc.data()['status'] as String?;
        // Count materials that are uploaded or indexed (not pending)
        if (status != MaterialStatus.pendingUpload.asString) {
          totalMaterials++;
        }
      }

      // Count quizzes and completed quizzes
      final quizzesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('courses')
          .doc(courseId)
          .collection('quizzes')
          .get();

      for (final quizDoc in quizzesSnapshot.docs) {
        totalQuizzes++;

        // Check if this quiz has any completed attempts
        final attemptsSnapshot = await quizDoc.reference
            .collection('attempts')
            .where('completedAt', isNotEqualTo: null)
            .get();

        if (attemptsSnapshot.docs.isNotEmpty) {
          completedQuizzes++;

          // Calculate average score for this quiz
          for (final attemptDoc in attemptsSnapshot.docs) {
            final attemptData = attemptDoc.data();
            final numCorrect = (attemptData['numCorrect'] as num?)?.toInt() ?? 0;
            final numTotal = (attemptData['numTotal'] as num?)?.toInt() ?? 0;

            if (numTotal > 0) {
              totalQuizAttempts++;
              final score = (numCorrect / numTotal) * 100;
              totalQuizScore += score.toInt();
            }
          }
        }
      }
    }

    // Calculate average quiz score
    final averageQuizScore = totalQuizAttempts > 0
        ? (totalQuizScore / totalQuizAttempts)
        : 0.0;

    return StudyProgress(
      totalCourses: totalCourses,
      totalMaterials: totalMaterials,
      totalQuizzes: totalQuizzes,
      completedQuizzes: completedQuizzes,
      totalQuizAttempts: totalQuizAttempts,
      averageQuizScore: averageQuizScore,
    );
  }

  /// Watch study progress (stream version for real-time updates)
  Stream<StudyProgress> watchProgress(String userId) {
    // Watch courses stream
    final coursesStream = _firestore
        .collection('users')
        .doc(userId)
        .collection('courses')
        .snapshots();

    // Helper function to calculate progress
    Future<StudyProgress> _calculateProgress() async {
      final coursesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('courses')
          .get();

      int totalCourses = coursesSnapshot.docs.length;
      int totalMaterials = 0;
      int totalQuizzes = 0;
      int completedQuizzes = 0;
      int totalQuizAttempts = 0;
      int totalQuizScore = 0;
      final Set<String> quizzesWithCompletions = {};

      for (final courseDoc in coursesSnapshot.docs) {
        final courseId = courseDoc.id;

        // Count materials (uploaded or indexed)
        final materialsSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('courses')
            .doc(courseId)
            .collection('materials')
            .get();

        for (final materialDoc in materialsSnapshot.docs) {
          final status = materialDoc.data()['status'] as String?;
          // Count materials that are uploaded or indexed (not pending)
          if (status != MaterialStatus.pendingUpload.asString) {
            totalMaterials++;
          }
        }

        // Count quizzes
        final quizzesSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('courses')
            .doc(courseId)
            .collection('quizzes')
            .get();

        totalQuizzes += quizzesSnapshot.docs.length;

        // Check completed attempts for each quiz
        for (final quizDoc in quizzesSnapshot.docs) {
          final quizId = quizDoc.id;
          final attemptsSnapshot = await quizDoc.reference
              .collection('attempts')
              .where('completedAt', isNotEqualTo: null)
              .get();

          if (attemptsSnapshot.docs.isNotEmpty) {
            if (!quizzesWithCompletions.contains(quizId)) {
              quizzesWithCompletions.add(quizId);
              completedQuizzes++;
            }

            // Calculate average score
            for (final attemptDoc in attemptsSnapshot.docs) {
              final attemptData = attemptDoc.data();
              final numCorrect = (attemptData['numCorrect'] as num?)?.toInt() ?? 0;
              final numTotal = (attemptData['numTotal'] as num?)?.toInt() ?? 0;

              if (numTotal > 0) {
                totalQuizAttempts++;
                final score = (numCorrect / numTotal) * 100;
                totalQuizScore += score.toInt();
              }
            }
          }
        }
      }

      final averageQuizScore = totalQuizAttempts > 0
          ? (totalQuizScore / totalQuizAttempts)
          : 0.0;

      return StudyProgress(
        totalCourses: totalCourses,
        totalMaterials: totalMaterials,
        totalQuizzes: totalQuizzes,
        completedQuizzes: completedQuizzes,
        totalQuizAttempts: totalQuizAttempts,
        averageQuizScore: averageQuizScore,
      );
    }

    // Watch courses, quiz attempts, and materials - recalculate when any changes
    final attemptsStream = _firestore
        .collectionGroup('attempts')
        .where('completedAt', isNotEqualTo: null)
        .snapshots();

    final materialsStream = _firestore
        .collectionGroup('materials')
        .snapshots();

    // Combine all streams using asyncExpand
    // When courses change, set up a stream that also watches attempts and materials
    return coursesStream.asyncMap((_) async {
      // Calculate immediately when courses change
      return await _calculateProgress();
    }).asyncExpand((_) {
      // After calculating from courses, also watch attempts
      return attemptsStream.asyncMap((_) => _calculateProgress()).asyncExpand((_) {
        // Also watch materials
        return materialsStream.asyncMap((_) => _calculateProgress());
      });
    });
  }
}

