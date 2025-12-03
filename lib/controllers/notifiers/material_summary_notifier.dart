import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/material_summary.dart';
import '../services/material_summary_service.dart';

class MaterialSummaryNotifier extends FamilyNotifier<
    AsyncValue<MaterialSummary?>,
    (String creatorId, String courseId, List<String> materialIds)> {
  late final MaterialSummaryService _service;
  StreamSubscription<MaterialSummary?>? _subscription;

  @override
  AsyncValue<MaterialSummary?> build(
      (String creatorId, String courseId, List<String> materialIds) args) {
    final creatorId = args.$1;
    final courseId = args.$2;
    final materialIds = args.$3;

    _service = MaterialSummaryService(FirebaseFirestore.instance);

    state = const AsyncValue.loading();

    _subscription?.cancel();
    _subscription = _service
        .watchSummaryForMaterials(
          creatorId: creatorId,
          courseId: courseId,
          materialIds: materialIds,
        )
        .listen(
          (summary) => state = AsyncValue.data(summary),
          onError: (error, stack) => state = AsyncValue.error(error, stack),
        );

    ref.onDispose(() => _subscription?.cancel());

    return state;
  }

  Future<void> generate({
    required String vectorStoreId,
  }) async {
    final creatorId = arg.$1;
    final courseId = arg.$2;
    final materialIds = arg.$3;

    state = const AsyncValue.loading();

    try {
      final summary = await _service.generateSummary(
        creatorId: creatorId,
        courseId: courseId,
        materialIds: materialIds,
        vectorStoreId: vectorStoreId,
      );
      state = AsyncValue.data(summary);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }
}

