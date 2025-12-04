import 'package:flutter/material.dart';

enum CourseReminderFrequency { daily, weekly, biWeekly }

class CourseReminderSettings {
  CourseReminderSettings({
    required this.userId,
    required this.courseId,
    required this.courseTitle,
    required this.enabled,
    required this.frequency,
    required this.time,
  });

  final String userId;
  final String courseId;
  final String courseTitle;
  final bool enabled;
  final CourseReminderFrequency frequency;
  final TimeOfDay time;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'courseId': courseId,
      'courseTitle': courseTitle,
      'pushNotificationsEnabled': enabled,
      'frequency': frequency.name,
      'hour': time.hour,
      'minute': time.minute,
    };
  }

  static CourseReminderSettings fromMap(
    String userId,
    String courseId,
    String courseTitle,
    Map<String, dynamic> map,
  ) {
    return CourseReminderSettings(
      userId: userId,
      courseId: courseId,
      courseTitle: courseTitle,
      enabled: map['pushNotificationsEnabled'] as bool? ?? false,
      frequency: _frequencyFromString(map['frequency'] as String?),
      time: TimeOfDay(
        hour: map['hour'] as int? ?? 10,
        minute: map['minute'] as int? ?? 0,
      ),
    );
  }

  static CourseReminderFrequency _frequencyFromString(String? raw) {
    return CourseReminderFrequency.values.firstWhere(
      (f) => f.name == raw,
      orElse: () => CourseReminderFrequency.daily,
    );
  }

  CourseReminderSettings copyWith({
    bool? enabled,
    CourseReminderFrequency? frequency,
    TimeOfDay? time,
  }) {
    return CourseReminderSettings(
      userId: userId,
      courseId: courseId,
      courseTitle: courseTitle,
      enabled: enabled ?? this.enabled,
      frequency: frequency ?? this.frequency,
      time: time ?? this.time,
    );
  }
}


