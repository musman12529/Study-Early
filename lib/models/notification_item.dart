import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  materialIndexed,
  materialIndexFailed,
  quizReady,
  quizAttemptGraded,
  chatUpdate,
  system,
}

enum NotificationStatus { unread, read }

class NotificationItem {
  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.status,
    required this.createdAt,
    this.readAt,
    this.courseId,
    this.materialId,
    this.quizId,
    this.metadata,
  });

  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationStatus status;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? courseId;
  final String? materialId;
  final String? quizId;
  final Map<String, dynamic>? metadata;

  bool get isUnread => status == NotificationStatus.unread;

  NotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    NotificationStatus? status,
    DateTime? createdAt,
    DateTime? readAt,
    String? courseId,
    String? materialId,
    String? quizId,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      courseId: courseId ?? this.courseId,
      materialId: materialId ?? this.materialId,
      quizId: quizId ?? this.quizId,
      metadata: metadata ?? this.metadata,
    );
  }

  NotificationItem markAsRead({DateTime? readTime}) {
    return copyWith(
      status: NotificationStatus.read,
      readAt: readTime ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'type': type.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'courseId': courseId,
      'materialId': materialId,
      'quizId': quizId,
      'metadata': metadata,
    };
  }

  static NotificationItem fromMap(
    String id,
    Map<String, dynamic> map, {
    DateTime? defaultCreatedAt,
  }) {
    final createdField = map['createdAt'];
    final readField = map['readAt'];

    return NotificationItem(
      id: id,
      title: map['title'] as String? ?? 'Notification',
      body: map['body'] as String? ?? '',
      type: _typeFromString(map['type'] as String?),
      status: _statusFromString(map['status'] as String?),
      createdAt: createdField is Timestamp
          ? createdField.toDate()
          : defaultCreatedAt ?? DateTime.now(),
      readAt: readField is Timestamp ? readField.toDate() : null,
      courseId: map['courseId'] as String?,
      materialId: map['materialId'] as String?,
      quizId: map['quizId'] as String?,
      metadata: (map['metadata'] as Map<String, dynamic>?) ??
          (map['metadata'] is Map ? Map<String, dynamic>.from(map['metadata']) : null),
    );
  }

  static NotificationType _typeFromString(String? raw) {
    return NotificationType.values.firstWhere(
      (t) => t.name == raw,
      orElse: () => NotificationType.system,
    );
  }

  static NotificationStatus _statusFromString(String? raw) {
    return NotificationStatus.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => NotificationStatus.unread,
    );
  }
}

