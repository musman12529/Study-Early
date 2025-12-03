import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyearly/controllers/providers/auth_providers.dart';
import 'package:studyearly/controllers/services/user_service.dart';
import 'package:studyearly/models/user_profile.dart';

final userProfileStreamProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream<UserProfile?>.value(null);
  }
  final service = UserService(FirebaseFirestore.instance);
  return service.watchProfile(user.uid);
});

final hasUserProfileProvider = Provider<bool>((ref) {
  final profileAsync = ref.watch(userProfileStreamProvider);
  return profileAsync.asData?.value != null;
});
