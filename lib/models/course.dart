import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class Course {
  final String id;
  final String creatorId;
  final String title;
  final String? vectorStoreId;

  final DateTime createdAt;
  final DateTime updatedAt;

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
      'vectorStoreId': vectorStoreId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static Course fromMap(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data();
    return Course(
      id: map['id'],
      creatorId: map['creatorId'],
      title: map['title'],
      vectorStoreId: map['vectorStoreId'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Course copyWith({String? title, String? vectorStoreId}) {
    return Course(
      id: id,
      creatorId: creatorId,
      title: title ?? this.title,
      vectorStoreId: vectorStoreId ?? this.vectorStoreId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
