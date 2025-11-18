import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.asData?.value;
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});
