import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class Course {
  final String id;
  final String creatorId;
  String title;
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
  String? vectorStoreId;

  Course({
    String? id,
    required this.creatorId,
    required this.title,
    this.vectorStoreId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'creatorId': creatorId,
      'title': title,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'vectorStoreId': vectorStoreId,
    };
  }

  static Course fromMap(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data();
    return Course(
      id: map['id'] as String,
      creatorId: map['creatorId'] as String,
      title: map['title'] as String,
      vectorStoreId: map['vectorStoreId'] as String?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }
}
