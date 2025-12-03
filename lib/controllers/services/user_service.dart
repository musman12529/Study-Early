import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:studyearly/models/user_profile.dart';

class UserService {
  UserService(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String userId) {
    return _firestore.collection('users').doc(userId);
  }

  Future<void> createProfile({
    required String userId,
    required String email,
    required UserRole role,
    String? displayName,
    String? photoUrl,
  }) async {
    final now = DateTime.now();
    final profile = UserProfile(
      id: userId,
      email: email,
      role: role,
      displayName: displayName,
      photoUrl: photoUrl,
      createdAt: now,
      updatedAt: now,
    );
    await _userDoc(userId).set(profile.toMap(), SetOptions(merge: true));
  }

  Future<void> updateBasicProfile({
    required String userId,
    String? displayName,
    String? photoUrl,
  }) async {
    final now = DateTime.now();
    final data = <String, dynamic>{
      if (displayName != null) 'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'updatedAt': Timestamp.fromDate(now),
    };
    await _userDoc(userId).set(data, SetOptions(merge: true));
  }

  Stream<UserProfile?> watchProfile(String userId) {
    return _userDoc(userId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return UserProfile.fromDoc(snap);
    });
  }

  Future<UserProfile?> fetchProfile(String userId) async {
    final snap = await _userDoc(userId).get();
    if (!snap.exists || snap.data() == null) return null;
    return UserProfile.fromDoc(snap);
  }
}
