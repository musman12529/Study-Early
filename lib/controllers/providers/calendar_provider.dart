import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/calendar_event.dart';
import '../notifiers/calendar_notifier.dart';

final calendarEventListProvider = NotifierProvider.family<
    CalendarEventListNotifier,
    List<CalendarEvent>,
    (String creatorId, String courseId)>(CalendarEventListNotifier.new);

final allCalendarEventsProvider =
    NotifierProvider<AllCalendarEventsNotifier, AsyncValue<List<CalendarEvent>>>(
        AllCalendarEventsNotifier.new);

