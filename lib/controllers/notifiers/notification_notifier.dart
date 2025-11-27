import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/notification_item.dart';

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
  bool _initialized = false;

  @override
  NotificationState build(String userId) {
    _subscription?.cancel();

    state = const NotificationState(isLoading: true);

    /// Placeholder stream until Firestore-backed implementation arrives.
    if (!_initialized) {
      _initialized = true;
      _primeMockNotifications();
    }

    ref.onDispose(() => _subscription?.cancel());
    return state;
  }

  void _primeMockNotifications() {
    final mockStream = Stream<List<NotificationItem>>.fromFuture(
      Future<List<NotificationItem>>.delayed(
        const Duration(milliseconds: 250),
        () => _buildMockNotifications(),
      ),
    );

    _subscription = mockStream.listen(
      (items) => state = NotificationState(
        notifications: items,
        isLoading: false,
      ),
      onError: (error, _) =>
          state = state.copyWith(isLoading: false, error: error),
    );
  }

  List<NotificationItem> _buildMockNotifications() {
    final now = DateTime.now();
    return [
      NotificationItem(
        id: 'preview-material-indexed',
        title: 'Material indexed',
        body: '“Week 02 Slides.pdf” is ready for chat and quiz generation.',
        type: NotificationType.materialIndexed,
        status: NotificationStatus.unread,
        createdAt: now.subtract(const Duration(minutes: 4)),
        courseId: 'course-demo',
        materialId: 'material-1',
      ),
      NotificationItem(
        id: 'preview-quiz-ready',
        title: 'Quiz ready to publish',
        body: 'Auto-generated quiz for “Midterm Prep” is ready for review.',
        type: NotificationType.quizReady,
        status: NotificationStatus.unread,
        createdAt: now.subtract(const Duration(hours: 1, minutes: 12)),
        quizId: 'quiz-demo',
        courseId: 'course-demo',
      ),
      NotificationItem(
        id: 'preview-upload-complete',
        title: 'Upload complete',
        body: '“Lab instructions.pdf” finished uploading and is queued.',
        type: NotificationType.system,
        status: NotificationStatus.read,
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
    ];
  }

  void markAllAsRead() {
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => n.isUnread ? n.markAsRead() : n)
          .toList(),
    );
  }

  void markAsRead(String id) {
    state = state.copyWith(
      notifications: state.notifications.map((notification) {
        if (notification.id != id) return notification;
        return notification.isUnread
            ? notification.markAsRead()
            : notification;
      }).toList(),
    );
  }
}

