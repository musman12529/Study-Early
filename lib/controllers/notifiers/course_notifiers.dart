import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:studyearly/controllers/services/course_service.dart';
import 'package:studyearly/models/course.dart';

class CourseListNotifier extends FamilyNotifier<List<Course>, String> {
  late final CourseService _service;
  StreamSubscription<List<Course>>? _subscription;

  @override
  List<Course> build(String creatorId) {
    _service = CourseService(FirebaseFirestore.instance);

    state = const [];
    _subscription?.cancel();
    _subscription = _service
        .watchCoursesForCreator(creatorId)
        .listen((courses) => state = courses);

    ref.onDispose(() => _subscription?.cancel());
    return state;
  }

  Future<void> add({required String title, String? vectorStoreId}) async {
    await _service.createCourse(
      creatorId: arg,
      title: title,
      vectorStoreId: vectorStoreId,
    );
  }

  Future<void> update(Course course) async {
    await _service.updateCourse(course);
  }

  Future<void> remove(String courseId) async {
    await _service.deleteCourse(courseId);
  }
}
