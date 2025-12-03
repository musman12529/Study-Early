import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/calendar_event.dart';
import '../services/calendar_service.dart';

class CalendarEventListNotifier
    extends FamilyNotifier<List<CalendarEvent>, (String creatorId, String courseId)> {
  late final CalendarService _service;
  StreamSubscription<List<CalendarEvent>>? _subscription;

  @override
  List<CalendarEvent> build((String creatorId, String courseId) args) {
    final creatorId = args.$1;
    final courseId = args.$2;

    _service = CalendarService(FirebaseFirestore.instance);

    state = const [];

    _subscription?.cancel();
    _subscription = _service
        .watchEvents(creatorId: creatorId, courseId: courseId)
        .listen((events) => state = events);

    ref.onDispose(() => _subscription?.cancel());

    return state;
  }

  Future<void> createEvent({
    required String title,
    required DateTime date,
    DateTime? time,
    required EventType type,
    String? materialId,
  }) async {
    final creatorId = arg.$1;
    final courseId = arg.$2;

    await _service.createEvent(
      creatorId: creatorId,
      courseId: courseId,
      title: title,
      date: date,
      time: time,
      type: type,
      materialId: materialId,
    );
  }

  Future<void> updateEvent(CalendarEvent event) async {
    final creatorId = arg.$1;
    await _service.updateEvent(creatorId: creatorId, event: event);
  }

  Future<void> deleteEvent(String eventId) async {
    final creatorId = arg.$1;
    final courseId = arg.$2;
    await _service.deleteEvent(
      creatorId: creatorId,
      courseId: courseId,
      eventId: eventId,
    );
  }
}

class AllCalendarEventsNotifier
    extends Notifier<AsyncValue<List<CalendarEvent>>> {
  CalendarService? _service;
  StreamSubscription<List<CalendarEvent>>? _subscription;

  @override
  AsyncValue<List<CalendarEvent>> build() {
    _service = CalendarService(FirebaseFirestore.instance);
    
    ref.onDispose(() {
      _subscription?.cancel();
    });
    
    return const AsyncValue.loading();
  }

  void watchForUser(String userId) {
    if (_service == null) {
      _service = CalendarService(FirebaseFirestore.instance);
    }
    
    _subscription?.cancel();
    _subscription = _service!
        .watchAllEvents(creatorId: userId)
        .listen(
          (events) => state = AsyncValue.data(events),
          onError: (error, stack) => state = AsyncValue.error(error, stack),
        );
  }
}

