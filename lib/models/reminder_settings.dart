import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ReminderFrequency {
  daily,
  weekly,
  biWeekly,
}

class ReminderSettings {
  ReminderSettings({
    required this.userId,
    required this.pushNotificationsEnabled,
    required this.frequency,
    required this.time,
    this.createdAt,
    this.updatedAt,
  });

  final String userId;
  final bool pushNotificationsEnabled;
  final ReminderFrequency frequency;
  final TimeOfDay time;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'pushNotificationsEnabled': pushNotificationsEnabled,
      'frequency': frequency.name,
      'hour': time.hour,
      'minute': time.minute,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static ReminderSettings fromMap(String userId, Map<String, dynamic> map) {
    final createdField = map['createdAt'];
    final updatedField = map['updatedAt'];

    return ReminderSettings(
      userId: userId,
      pushNotificationsEnabled: map['pushNotificationsEnabled'] as bool? ?? false,
      frequency: _frequencyFromString(map['frequency'] as String?),
      time: TimeOfDay(
        hour: map['hour'] as int? ?? 10,
        minute: map['minute'] as int? ?? 0,
      ),
      createdAt: createdField is Timestamp
          ? createdField.toDate()
          : (createdField is DateTime ? createdField : null),
      updatedAt: updatedField is Timestamp
          ? updatedField.toDate()
          : (updatedField is DateTime ? updatedField : null),
    );
  }

  static ReminderFrequency _frequencyFromString(String? raw) {
    return ReminderFrequency.values.firstWhere(
      (f) => f.name == raw,
      orElse: () => ReminderFrequency.daily,
    );
  }

  ReminderSettings copyWith({
    bool? pushNotificationsEnabled,
    ReminderFrequency? frequency,
    TimeOfDay? time,
  }) {
    return ReminderSettings(
      userId: userId,
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      frequency: frequency ?? this.frequency,
      time: time ?? this.time,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

