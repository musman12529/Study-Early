import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/course_reminder_settings.dart';

typedef CourseReminderKey = ({String userId, String courseId, String courseTitle});

final courseReminderSettingsProvider = NotifierProvider.family<
    CourseReminderSettingsNotifier,
    AsyncValue<CourseReminderSettings?>,
    CourseReminderKey>(CourseReminderSettingsNotifier.new);

class CourseReminderSettingsNotifier
    extends FamilyNotifier<AsyncValue<CourseReminderSettings?>, CourseReminderKey> {
  StreamSubscription<DocumentSnapshot>? _subscription;

  @override
  AsyncValue<CourseReminderSettings?> build(CourseReminderKey key) {
    final userId = key.userId;
    final courseId = key.courseId;
    final courseTitle = key.courseTitle;

    _subscription?.cancel();

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('courses')
        .doc(courseId)
        .collection('reminderSettings')
        .doc('config');

    // Prime with loading state
    state = const AsyncValue.loading();

    _subscription = docRef.snapshots().listen(
      (snapshot) {
        if (!snapshot.exists) {
          state = const AsyncValue.data(null);
        } else {
          final data = snapshot.data()!;
          final settings = CourseReminderSettings.fromMap(
            userId,
            courseId,
            courseTitle,
            data,
          );
          state = AsyncValue.data(settings);
        }
      },
      onError: (error, stack) {
        state = AsyncValue.error(error, stack);
      },
    );

    ref.onDispose(() => _subscription?.cancel());

    return state;
  }

  Future<void> saveSettings(CourseReminderSettings settings) async {
    final userId = settings.userId;
    final courseId = settings.courseId;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('courses')
        .doc(courseId)
        .collection('reminderSettings')
        .doc('config');

    await docRef.set(settings.toMap(), SetOptions(merge: true));
  }
}


