import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/notification_item.dart';
import '../services/notification_repository.dart';

class NotificationState {
  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  final List<NotificationItem> notifications;
  final bool isLoading;
  final Object? error;

  int get unreadCount =>
      notifications.where((item) => item.isUnread).length;

  NotificationState copyWith({
    List<NotificationItem>? notifications,
    bool? isLoading,
    Object? error = _sentinel,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error == _sentinel ? this.error : error,
    );
  }
}

const _sentinel = Object();

class NotificationListNotifier
    extends FamilyNotifier<NotificationState, String> {
  StreamSubscription<List<NotificationItem>>? _subscription;
  final NotificationRepository _repository = NotificationRepository();

  @override
  NotificationState build(String userId) {
    _subscription?.cancel();
    state = const NotificationState(isLoading: true);
    _subscription = _repository.watchNotifications(userId).listen(
      (items) {
        state = NotificationState(notifications: items, isLoading: false);
      },
      onError: (error, stackTrace) {
        state = state.copyWith(isLoading: false, error: error);
      },
    );

    ref.onDispose(() => _subscription?.cancel());
    return state;
  }

  Future<void> markAllAsRead() async {
    final userId = arg;
    await _repository.markAllRead(userId);
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => n.isUnread ? n.markAsRead() : n)
          .toList(),
    );
  }

  Future<void> markAsRead(String id) async {
    final userId = arg;
    await _repository.markRead(userId, id);
    state = state.copyWith(
      notifications: state.notifications.map((notification) {
        if (notification.id != id) return notification;
        return notification.isUnread
            ? notification.markAsRead()
            : notification;
      }).toList(),
    );
  }

  /// Permanently removes all notifications that are already marked as read.
  Future<void> clearRead() async {
    final userId = arg;
    await _repository.clearRead(userId);
    state = state.copyWith(
      notifications:
          state.notifications.where((n) => n.isUnread).toList(),
    );
  }
}

