import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { student, professor }

extension UserRoleHelper on UserRole {
  static UserRole fromString(String? value) {
    switch (value) {
      case 'professor':
        return UserRole.professor;
      case 'student':
      default:
        return UserRole.student;
    }
  }

  String get asString => toString().split('.').last;
}

class UserProfile {
  UserProfile({
    required this.id,
    required this.email,
    required this.role,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String email;
  final UserRole role;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile copyWith({
    String? email,
    UserRole? role,
    String? displayName,
    String? photoUrl,
  }) {
    return UserProfile(
      id: id,
      email: email ?? this.email,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'role': role.asString,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static UserProfile fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final now = DateTime.now();
    final created = data['createdAt'];
    final updated = data['updatedAt'];
    return UserProfile(
      id: (data['id'] as String?) ?? doc.id,
      email: (data['email'] as String?) ?? '',
      role: UserRoleHelper.fromString(data['role'] as String?),
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      createdAt: created is Timestamp ? created.toDate() : now,
      updatedAt: updated is Timestamp ? updated.toDate() : now,
    );
  }
}
