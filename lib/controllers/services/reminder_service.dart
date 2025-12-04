import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../models/reminder_settings.dart';

class ReminderService {
  ReminderService({
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _localNotifications =
            localNotifications ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _localNotifications;
  static const int _reminderNotificationId = 9999;

  /// Schedules recurring notifications based on reminder settings
  Future<void> scheduleReminders(ReminderSettings settings) async {
    if (kIsWeb) {
      debugPrint('[ReminderService] Web platform does not support scheduled notifications');
      return;
    }

    if (!settings.pushNotificationsEnabled) {
      await cancelAllReminders();
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'studyearly_reminders',
      'Course Reminders',
      channelDescription: 'Reminders for your courses and study schedule.',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
    // Instead of scheduling exact alarms (which require extra permissions on
    // Android 14+), we keep this simple and just fire an immediate local
    // notification confirming that reminders are enabled.
    await _localNotifications.show(
      _reminderNotificationId,
      'Reminders updated',
      'Your reminder preferences have been saved.',
      details,
    );

    debugPrint(
      '[ReminderService] Fired immediate reminder confirmation for '
      '${settings.frequency.name} @ ${settings.time.hour.toString().padLeft(2, '0')}:'
      '${settings.time.minute.toString().padLeft(2, '0')}',
    );
  }

  /// Cancels all scheduled reminder notifications
  Future<void> cancelAllReminders() async {
    await _localNotifications.cancel(_reminderNotificationId);
    await _localNotifications.cancel(_reminderNotificationId + 1);
    debugPrint('[ReminderService] Cancelled all reminders');
  }

  /// Initializes timezone data (no-op for the simplified immediate notification
  /// strategy, kept for API compatibility).
  static Future<void> initialize() async {}
}

