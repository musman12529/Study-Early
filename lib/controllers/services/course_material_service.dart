import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/course_material.dart';

class CourseMaterialService {
  CourseMaterialService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _materialsRef(
    String creatorId,
    String courseId,
  ) {
    return _firestore
        .collection('users')
        .doc(creatorId)
        .collection('courses')
        .doc(courseId)
        .collection('materials');
  }

  Stream<List<CourseMaterial>> watchMaterials({
    required String creatorId,
    required String courseId,
  }) {
    return _materialsRef(creatorId, courseId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(CourseMaterial.fromMap).toList());
  }

  Future<List<CourseMaterial>> fetchMaterials({
    required String creatorId,
    required String courseId,
  }) async {
    final snap = await _materialsRef(
      creatorId,
      courseId,
    ).orderBy('createdAt', descending: true).get();
    return snap.docs.map(CourseMaterial.fromMap).toList();
  }

  Future<CourseMaterial> createMaterial({
    required String creatorId,
    required String courseId,
    required String fileName,
    required String downloadUrl,
    String? storagePath,
    String? uploadedByUserId,
  }) async {
    final material = CourseMaterial(
      courseId: courseId,
      fileName: fileName,
      downloadUrl: downloadUrl,
      storagePath: storagePath,
      uploadedByUserId: uploadedByUserId,
    );

    await _materialsRef(
      creatorId,
      courseId,
    ).doc(material.id).set(material.toMap());

    return material;
  }

  Future<void> updateMaterial({
    required String creatorId,
    required CourseMaterial material,
  }) async {
    await _materialsRef(creatorId, material.courseId).doc(material.id).update({
      'fileName': material.fileName,
      'downloadUrl': material.downloadUrl,
      'storagePath': material.storagePath,
      'uploadedByUserId': material.uploadedByUserId,
      'openAiFileId': material.openAiFileId,
      'status': material.status.asString,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteMaterial({
    required String creatorId,
    required String courseId,
    required String materialId,
  }) async {
    await _materialsRef(creatorId, courseId).doc(materialId).delete();
  }
}
