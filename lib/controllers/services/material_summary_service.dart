import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../models/material_summary.dart';

class MaterialSummaryService {
  MaterialSummaryService(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _courseRef(
    String creatorId,
    String courseId,
  ) {
    return _firestore
        .collection('users')
        .doc(creatorId)
        .collection('courses')
        .doc(courseId);
  }

  CollectionReference<Map<String, dynamic>> _summariesRef(
    String creatorId,
    String courseId,
  ) {
    return _courseRef(creatorId, courseId).collection('summaries');
  }

  Stream<MaterialSummary?> watchSummaryForMaterial({
    required String creatorId,
    required String courseId,
    required String materialId,
  }) {
    return _summariesRef(creatorId, courseId)
        .where('materialId', isEqualTo: materialId)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return MaterialSummary.fromMap(snap.docs.first);
    });
  }

  Stream<MaterialSummary?> watchSummaryForMaterials({
    required String creatorId,
    required String courseId,
    required List<String> materialIds,
  }) {
    final sortedIds = [...materialIds]..sort();
    return _summariesRef(creatorId, courseId).snapshots().map((snap) {
      // Find summary with matching materialIds (exact array match)
      for (final doc in snap.docs) {
        final summary = MaterialSummary.fromMap(doc);
        final summaryIds = [...summary.materialIds]..sort();
        
        // Compare arrays
        if (summaryIds.length == sortedIds.length) {
          bool matches = true;
          for (int i = 0; i < summaryIds.length; i++) {
            if (summaryIds[i] != sortedIds[i]) {
              matches = false;
              break;
            }
          }
          if (matches) {
            return summary;
          }
        }
      }
      return null;
    });
  }

  Future<MaterialSummary> generateSummary({
    required String creatorId,
    required String courseId,
    required List<String> materialIds,
    required String vectorStoreId,
  }) async {
    final result = await FirebaseFunctions.instanceFor(
      region: 'northamerica-northeast2',
    ).httpsCallable('generateSummary').call({
      'userId': creatorId,
      'courseId': courseId,
      'materialIds': materialIds,
      'vectorStoreId': vectorStoreId,
    });

    final resultData = result.data as Map<String, dynamic>;
    final summaryText = resultData['summaryText'] as String;
    final summaryMaterialIds = List<String>.from(resultData['materialIds'] ?? []);
    final summaryId = resultData['id'] as String;

    // Fetch the created summary from Firestore
    final summaryDoc = await _summariesRef(creatorId, courseId)
        .doc(summaryId)
        .get();

    if (!summaryDoc.exists) {
      throw StateError('Summary was created but not found in Firestore');
    }

    // Convert DocumentSnapshot to QueryDocumentSnapshot-like structure
    final docData = summaryDoc.data()!;
    return MaterialSummary(
      id: summaryId,
      courseId: docData['courseId'] as String,
      materialId: docData['materialId'] as String,
      summaryText: docData['summaryText'] as String,
      materialIds: List<String>.from(docData['materialIds'] ?? []),
      createdAt: (docData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (docData['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

