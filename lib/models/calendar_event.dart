import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

enum EventType { lecture, exam, assignment }

extension EventTypeHelper on EventType {
  static EventType fromString(String? value) {
    switch (value) {
      case 'exam':
        return EventType.exam;
      case 'assignment':
        return EventType.assignment;
      default:
        return EventType.lecture;
    }
  }

  String get asString => toString().split('.').last;
}

class CalendarEvent {
  final String id;
  final String courseId;
  final String title;
  final DateTime date;
  final DateTime? time;
  final EventType type;
  final String? materialId; // For assignment due dates
  final DateTime createdAt;
  final DateTime updatedAt;

  CalendarEvent({
    String? id,
    required this.courseId,
    required this.title,
    required this.date,
    this.time,
    this.type = EventType.lecture,
    this.materialId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  DateTime get eventDateTime {
    if (time != null) {
      return DateTime(
        date.year,
        date.month,
        date.day,
        time!.hour,
        time!.minute,
      );
    }
    return DateTime(date.year, date.month, date.day);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'date': Timestamp.fromDate(date),
      'time': time != null ? Timestamp.fromDate(time!) : null,
      'type': type.asString,
      'materialId': materialId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static CalendarEvent fromMap(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final map = doc.data();
    return CalendarEvent(
      id: map['id'] ?? doc.id,
      courseId: map['courseId'],
      title: map['title'],
      date: (map['date'] as Timestamp).toDate(),
      time: map['time'] != null ? (map['time'] as Timestamp).toDate() : null,
      type: EventTypeHelper.fromString(map['type']),
      materialId: map['materialId'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  CalendarEvent copyWith({
    String? title,
    DateTime? date,
    DateTime? time,
    EventType? type,
    String? materialId,
  }) {
    return CalendarEvent(
      id: id,
      courseId: courseId,
      title: title ?? this.title,
      date: date ?? this.date,
      time: time ?? this.time,
      type: type ?? this.type,
      materialId: materialId ?? this.materialId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

