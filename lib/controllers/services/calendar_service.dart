import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/calendar_event.dart';

class CalendarService {
  CalendarService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _eventsRef(
    String creatorId,
    String courseId,
  ) {
    return _firestore
        .collection('users')
        .doc(creatorId)
        .collection('courses')
        .doc(courseId)
        .collection('events');
  }

  Stream<List<CalendarEvent>> watchEvents({
    required String creatorId,
    required String courseId,
  }) {
    return _eventsRef(creatorId, courseId)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(CalendarEvent.fromMap).toList());
  }

  Stream<List<CalendarEvent>> watchAllEvents({
    required String creatorId,
  }) {
    // Get all courses for the user and watch their events
    return _firestore
        .collection('users')
        .doc(creatorId)
        .collection('courses')
        .snapshots()
        .asyncMap((coursesSnap) async {
      final allEvents = <CalendarEvent>[];
      
      for (final courseDoc in coursesSnap.docs) {
        final eventsSnap = await courseDoc.reference
            .collection('events')
            .orderBy('date', descending: false)
            .get();
        
        allEvents.addAll(
          eventsSnap.docs.map(CalendarEvent.fromMap),
        );
      }
      
      allEvents.sort((a, b) => a.eventDateTime.compareTo(b.eventDateTime));
      return allEvents;
    });
  }

  Future<CalendarEvent> createEvent({
    required String creatorId,
    required String courseId,
    required String title,
    required DateTime date,
    DateTime? time,
    required EventType type,
    String? materialId,
  }) async {
    final event = CalendarEvent(
      courseId: courseId,
      title: title,
      date: date,
      time: time,
      type: type,
      materialId: materialId,
    );

    await _eventsRef(creatorId, courseId).doc(event.id).set(event.toMap());

    return event;
  }

  Future<void> updateEvent({
    required String creatorId,
    required CalendarEvent event,
  }) async {
    await _eventsRef(creatorId, event.courseId)
        .doc(event.id)
        .update({
      'title': event.title,
      'date': Timestamp.fromDate(event.date),
      'time': event.time != null ? Timestamp.fromDate(event.time!) : null,
      'type': event.type.asString,
      'materialId': event.materialId,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteEvent({
    required String creatorId,
    required String courseId,
    required String eventId,
  }) async {
    await _eventsRef(creatorId, courseId).doc(eventId).delete();
  }
}

