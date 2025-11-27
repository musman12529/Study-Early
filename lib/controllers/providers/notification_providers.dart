import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifiers/notification_notifier.dart';

final notificationListProvider =
    NotifierProvider.family<NotificationListNotifier, NotificationState, String>(
  NotificationListNotifier.new,
);

