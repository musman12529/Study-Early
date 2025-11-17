import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:studyearly/models/course.dart';

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

    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'createVectorStore',
      );
      final resp = await callable.call(<String, dynamic>{
        'userId': creatorId,
        'courseId': course.id,
        'courseName': title,
      });
      final data = resp.data;
      if (data is Map && data['vectorStoreId'] is String) {
        await _userCourses(creatorId).doc(course.id).update({
          'vectorStoreId': data['vectorStoreId'] as String,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
    } catch (_) {
      // handle errors with creating vector store
    }
    return course;
  }

  Future<void> updateCourse(Course course) async {
    await _userCourses(course.creatorId).doc(course.id).update({
      ...course.toMap(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteCourse({
    required String creatorId,
    required String courseId,
  }) async {
    await _userCourses(creatorId).doc(courseId).delete();
  }
}
