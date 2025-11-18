import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/course_material.dart';
import '../services/course_material_service.dart';

class CourseMaterialListNotifier
    extends
        FamilyNotifier<
          List<CourseMaterial>,
          (String creatorId, String courseId)
        > {
  late final CourseMaterialService _service;
  StreamSubscription<List<CourseMaterial>>? _subscription;

  @override
  List<CourseMaterial> build((String creatorId, String courseId) args) {
    final creatorId = args.$1;
    final courseId = args.$2;

    _service = CourseMaterialService(FirebaseFirestore.instance);

    state = const [];

    _subscription?.cancel();
    _subscription = _service
        .watchMaterials(creatorId: creatorId, courseId: courseId)
        .listen((materials) => state = materials);

    ref.onDispose(() => _subscription?.cancel());

    return state;
  }

  Future<void> uploadAndIndex({
    required String fileName,
    required String filePath,
  }) async {
    final creatorId = arg.$1;
    final courseId = arg.$2;

    await _service.uploadAndIndex(
      creatorId: creatorId,
      courseId: courseId,
      fileName: fileName,
      filePath: filePath,
    );
  }

  Future<void> update(CourseMaterial material) async {
    final creatorId = arg.$1;
    await _service.updateMaterial(creatorId: creatorId, material: material);
  }

  Future<void> remove(String materialId) async {
    final creatorId = arg.$1;
    final courseId = arg.$2;

    await _service.deleteMaterial(
      creatorId: creatorId,
      courseId: courseId,
      materialId: materialId,
    );
  }

  Future<void> retry(CourseMaterial material) async {
    final creatorId = arg.$1;
    await _service.retryIndex(creatorId: creatorId, material: material);
  }
}
