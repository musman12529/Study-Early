import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/providers/auth_providers.dart';
import '../../controllers/providers/notification_providers.dart';
import '../../models/notification_item.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  static const Color _navy = Color(0xFF101828);
  static const Color _brandBlue = Color(0xFF1A73E8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateChangesProvider);

    return auth.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Sign in to view notifications.')),
          );
        }

        final state = ref.watch(notificationListProvider(user.uid));
        final notifier =
            ref.read(notificationListProvider(user.uid).notifier);

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER: back + StudyEarly logo + "mark all read"
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'asset/logo.png',
                            height: 26,
                          ),
                          const SizedBox(width: 6),
                        ],
                      ),
                      IconButton(
                        tooltip: 'Mark all read',
                        onPressed: state.unreadCount == 0
                            ? null
                            : notifier.markAllAsRead,
                        icon: const Icon(Icons.done_all_outlined),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: _navy,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Expanded(
                    child: state.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : state.error != null
                            ? _ErrorNotice(error: state.error!)
                            : state.notifications.isEmpty
                                ? const _EmptyNotifications()
                                : ListView.separated(
                                    padding: EdgeInsets.zero,
                                    itemCount: state.notifications.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final notification =
                                          state.notifications[index];
                                      return _NotificationTile(
                                        notification: notification,
                                        markAsRead: () => notifier.markAsRead(
                                          notification.id,
                                        ),
                                      );
                                    },
                                  ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.markAsRead,
  });

  final NotificationItem notification;
  final VoidCallback markAsRead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final titleStyle = notification.isUnread
        ? theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          )
        : theme.textTheme.titleMedium;

    final bool unread = notification.isUnread;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          markAsRead();
          _handleNavigation(context, notification);
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: unread
                ? theme.colorScheme.primaryContainer.withOpacity(0.18)
                : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                blurRadius: 10,
                offset: const Offset(0, 4),
                color: Colors.black.withOpacity(0.03),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _iconForType(notification.type),
                    color: unread
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(notification.title, style: titleStyle),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(notification.body),
              const SizedBox(height: 8),
              Text(
                _relativeTime(notification.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.materialIndexed:
        return Icons.file_present_outlined;
      case NotificationType.materialIndexFailed:
        return Icons.error_outline;
      case NotificationType.quizReady:
        return Icons.quiz_outlined;
      case NotificationType.quizAttemptGraded:
        return Icons.school_outlined;
      case NotificationType.chatUpdate:
        return Icons.chat_bubble_outline;
      case NotificationType.system:
        return Icons.notifications_outlined;
    }
  }

  String _relativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }
}

void _handleNavigation(BuildContext context, NotificationItem notification) {
  final courseId = notification.courseId;
  switch (notification.type) {
    case NotificationType.materialIndexed:
    case NotificationType.materialIndexFailed:
    case NotificationType.system:
      if (courseId != null) {
        context.pushNamed(
          'courseDetail',
          pathParameters: {'courseId': courseId},
        );
      }
      break;
    case NotificationType.quizReady:
      if (courseId != null) {
        context.pushNamed(
          'quizList',
          pathParameters: {'courseId': courseId},
        );
      }
      break;
    case NotificationType.quizAttemptGraded:
      if (courseId != null && notification.quizId != null) {
        context.pushNamed(
          'quizAttempts',
          pathParameters: {
            'courseId': courseId,
            'quizId': notification.quizId!,
          },
        );
      }
      break;
    case NotificationType.chatUpdate:
      if (courseId != null) {
        context.pushNamed(
          'chat',
          pathParameters: {'courseId': courseId},
        );
      }
      break;
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.notifications_none, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'You are all caught up!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              'Failed to load notifications',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
