import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifiers/notification_notifier.dart';
import '../services/notification_service.dart';

final notificationListProvider =
    NotifierProvider.family<NotificationListNotifier, NotificationState, String>(
  NotificationListNotifier.new,
);

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  ref.onDispose(() => service.dispose());
  return service;
});

