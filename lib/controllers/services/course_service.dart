import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:studyearly/models/course.dart';

class CourseService {
  CourseService(FirebaseFirestore firestore)
    : _collection = firestore.collection('courses');

  final CollectionReference<Map<String, dynamic>> _collection;

  Stream<List<Course>> watchCoursesForCreator(String creatorId) {
    return _collection
        .where('creatorId', isEqualTo: creatorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Course.fromMap).toList());
  }

  Future<List<Course>> fetchCoursesForCreator(String creatorId) async {
    final snap = await _collection
        .where('creatorId', isEqualTo: creatorId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map(Course.fromMap).toList();
  }

  Future<Course> createCourse({
    required String creatorId,
    required String title,
    String? vectorStoreId,
  }) async {
    final course = Course(
      creatorId: creatorId,
      title: title,
      vectorStoreId: vectorStoreId,
    );
    await _collection.doc(course.id).set(course.toMap());
    return course;
  }

  Future<void> updateCourse(Course course) async {
    await _collection.doc(course.id).update({
      ...course.toMap(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteCourse(String courseId) async {
    await _collection.doc(courseId).delete();
  }
}
