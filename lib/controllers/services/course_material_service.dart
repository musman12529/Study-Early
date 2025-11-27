import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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

  Future<CourseMaterial> createMaterial({
    required String creatorId,
    required String courseId,
    required String fileName,
    required String downloadUrl,
    required String storagePath,
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
    bool deleteQuizzes = false,
  }) async {
    await FirebaseFunctions.instanceFor(
      region: 'northamerica-northeast2',
    ).httpsCallable('deleteMaterial').call({
      'userId': creatorId,
      'courseId': courseId,
      'materialId': materialId,
      'deleteQuizzes': deleteQuizzes,
    });
  }

  Future<void> uploadAndIndex({
    required String creatorId,
    required String courseId,
    required String fileName,
    String? filePath,
    Uint8List? fileBytes,
  }) async {
    final sanitized = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
    final storagePath =
        'users/$creatorId/courses/$courseId/materials/${DateTime.now().millisecondsSinceEpoch}-$sanitized';

    final storageRef = FirebaseStorage.instance.ref(storagePath);
    final metadata = SettableMetadata(contentType: 'application/pdf');

    if (kIsWeb) {
      // Web: use bytes
      if (fileBytes == null) {
        throw ArgumentError('fileBytes is required for web platform');
      }
      await storageRef.putData(fileBytes, metadata);
    } else {
      // Mobile: use file path
      if (filePath == null) {
        throw ArgumentError('filePath is required for mobile platform');
      }
      await storageRef.putFile(File(filePath), metadata);
    }

    final downloadUrl = await storageRef.getDownloadURL();

    final material = await createMaterial(
      creatorId: creatorId,
      courseId: courseId,
      fileName: fileName,
      downloadUrl: downloadUrl,
      storagePath: storagePath,
      uploadedByUserId: creatorId,
    );

    await FirebaseFunctions.instanceFor(
      region: 'northamerica-northeast2',
    ).httpsCallable('indexMaterial').call({
      'userId': creatorId,
      'courseId': courseId,
      'materialId': material.id,
      'storagePath': storagePath,
    });
  }

  Future<void> retryIndex({
    required String creatorId,
    required CourseMaterial material,
  }) async {
    final storagePath = material.storagePath;
    if (storagePath == null || storagePath.isEmpty) {
      throw StateError('Missing storagePath for material ${material.id}');
    }

    await _materialsRef(creatorId, material.courseId).doc(material.id).update({
      'status': MaterialStatus.indexing.asString,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    await FirebaseFunctions.instanceFor(
      region: 'northamerica-northeast2',
    ).httpsCallable('indexMaterial').call({
      'userId': creatorId,
      'courseId': material.courseId,
      'materialId': material.id,
      'storagePath': storagePath,
    });
  }
}
