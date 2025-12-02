import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfilePhotoState {
  const ProfilePhotoState({
    this.isUploading = false,
    this.photoUrl,
    this.previewBytes,
    this.fileName,
    this.path,
  });

  final bool isUploading;
  final String? photoUrl;
  final Uint8List? previewBytes;
  final String? fileName;
  final String? path;

  ProfilePhotoState copyWith({
    bool? isUploading,
    String? photoUrl,
    Uint8List? previewBytes,
    String? fileName,
    String? path,
  }) {
    return ProfilePhotoState(
      isUploading: isUploading ?? this.isUploading,
      photoUrl: photoUrl ?? this.photoUrl,
      previewBytes: previewBytes ?? this.previewBytes,
      fileName: fileName ?? this.fileName,
      path: path ?? this.path,
    );
  }
}

class ProfilePhotoNotifier extends Notifier<ProfilePhotoState> {
  @override
  ProfilePhotoState build() => const ProfilePhotoState();

  void clear() {
    state = const ProfilePhotoState();
  }

  void setSelected({
    required String fileName,
    Uint8List? previewBytes,
    String? path,
  }) {
    state = state.copyWith(
      fileName: fileName,
      previewBytes: previewBytes,
      path: path,
    );
  }

  Future<String?> upload(String userId, {String? previousUrl}) async {
    if (state.previewBytes == null && state.path == null) return state.photoUrl;

    final fileName = state.fileName ?? 'photo';
    final sanitized = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
    final storagePath =
        'users/$userId/profile/${DateTime.now().millisecondsSinceEpoch}-$sanitized';

    state = state.copyWith(isUploading: true);
    try {
      final ref = FirebaseStorage.instance.ref(storagePath);
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      if (kIsWeb) {
        if (state.previewBytes == null) return state.photoUrl;
        await ref.putData(state.previewBytes!, metadata);
      } else {
        if (state.path != null) {
          await ref.putFile(File(state.path!), metadata);
        } else if (state.previewBytes != null) {
          await ref.putData(state.previewBytes!, metadata);
        }
      }
      final url = await ref.getDownloadURL();
      state = state.copyWith(isUploading: false, photoUrl: url);
      if (previousUrl != null && previousUrl.isNotEmpty && previousUrl != url) {
        try {
          final oldRef = FirebaseStorage.instance.refFromURL(previousUrl);
          await oldRef.delete();
        } catch (_) {
          // ignore best-effort delete failures
        }
      }
      return url;
    } catch (_) {
      state = state.copyWith(isUploading: false);
      rethrow;
    }
  }
}
