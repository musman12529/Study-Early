import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyearly/models/course.dart';
import 'package:studyearly/controllers/notifiers/course_notifiers.dart';

final courseListProvider =
    NotifierProvider.family<CourseListNotifier, List<Course>, String>(
      CourseListNotifier.new,
    );
