import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

enum MaterialStatus { pendingUpload, uploaded, indexing, indexed, error }

extension MaterialStatusHelper on MaterialStatus {
  static MaterialStatus fromString(String? value) {
    switch (value) {
      case 'uploaded':
        return MaterialStatus.uploaded;
      case 'indexing':
        return MaterialStatus.indexing;
      case 'indexed':
        return MaterialStatus.indexed;
      case 'error':
        return MaterialStatus.error;
      default:
        return MaterialStatus.pendingUpload;
    }
  }

  String get asString => toString().split('.').last;
}

class CourseMaterial {
  final String id;
  final String courseId;
  final String fileName;
  final String downloadUrl;
  final String? storagePath;
  final String? uploadedByUserId;
  final String? openAiFileId;

  final MaterialStatus status;

  final DateTime createdAt;
  final DateTime updatedAt;

  CourseMaterial({
    String? id,
    required this.courseId,
    required this.fileName,
    required this.downloadUrl,
    this.storagePath,
    this.uploadedByUserId,
    this.openAiFileId,
    this.status = MaterialStatus.pendingUpload,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'fileName': fileName,
      'downloadUrl': downloadUrl,
      'storagePath': storagePath,
      'uploadedByUserId': uploadedByUserId,
      'openAiFileId': openAiFileId,
      'status': status.asString,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static CourseMaterial fromMap(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final map = doc.data();
    return CourseMaterial(
      id: map['id'],
      courseId: map['courseId'],
      fileName: map['fileName'],
      downloadUrl: map['downloadUrl'],
      storagePath: map['storagePath'],
      uploadedByUserId: map['uploadedByUserId'],
      openAiFileId: map['openAiFileId'],
      status: MaterialStatusHelper.fromString(map['status']),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  CourseMaterial copyWith({
    String? fileName,
    String? downloadUrl,
    String? storagePath,
    String? uploadedByUserId,
    String? openAiFileId,
    MaterialStatus? status,
  }) {
    return CourseMaterial(
      id: id,
      courseId: courseId,
      fileName: fileName ?? this.fileName,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      storagePath: storagePath ?? this.storagePath,
      uploadedByUserId: uploadedByUserId ?? this.uploadedByUserId,
      openAiFileId: openAiFileId ?? this.openAiFileId,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
