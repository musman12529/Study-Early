import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:studyearly/models/course.dart';
import 'package:cloud_functions/cloud_functions.dart';

class CourseService {
  CourseService(FirebaseFirestore firestore) : _firestore = firestore;

  final FirebaseFirestore _firestore;
  CollectionReference<Map<String, dynamic>> _userCourses(String userId) {
    return _firestore.collection('users').doc(userId).collection('courses');
  }

  Stream<List<Course>> watchCoursesForCreator(String creatorId) {
    return _userCourses(creatorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Course.fromMap).toList());
  }

  Future<List<Course>> fetchCoursesForCreator(String creatorId) async {
    final snap = await _userCourses(
      creatorId,
    ).orderBy('createdAt', descending: true).get();
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
    await _userCourses(creatorId).doc(course.id).set(course.toMap());
    return course;
  }

  Future<void> updateCourse(Course course) async {
    await _userCourses(course.creatorId).doc(course.id).update({
      'title': course.title,
      'vectorStoreId': course.vectorStoreId,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteCourse({
    required String creatorId,
    required String courseId,
  }) async {
    await FirebaseFunctions.instanceFor(region: 'northamerica-northeast2')
        .httpsCallable('deleteCourse')
        .call({'userId': creatorId, 'courseId': courseId});
  }
}
