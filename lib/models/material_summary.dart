import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class MaterialSummary {
  final String id;
  final String courseId;
  final String materialId;
  final String summaryText;
  final List<String> materialIds; // For multi-material summaries
  final DateTime createdAt;
  final DateTime updatedAt;

  MaterialSummary({
    String? id,
    required this.courseId,
    required this.materialId,
    required this.summaryText,
    this.materialIds = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'materialId': materialId,
      'summaryText': summaryText,
      'materialIds': materialIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static MaterialSummary fromMap(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final map = doc.data();
    return MaterialSummary(
      id: map['id'] ?? doc.id,
      courseId: map['courseId'],
      materialId: map['materialId'],
      summaryText: map['summaryText'],
      materialIds: List<String>.from(map['materialIds'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  MaterialSummary copyWith({
    String? summaryText,
    List<String>? materialIds,
  }) {
    return MaterialSummary(
      id: id,
      courseId: courseId,
      materialId: materialId,
      summaryText: summaryText ?? this.summaryText,
      materialIds: materialIds ?? this.materialIds,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

