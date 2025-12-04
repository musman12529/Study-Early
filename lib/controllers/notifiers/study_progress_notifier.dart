import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/study_progress.dart';
import '../services/study_progress_service.dart';

class StudyProgressNotifier extends FamilyNotifier<AsyncValue<StudyProgress>, String> {
  StreamSubscription<StudyProgress>? _subscription;
  final StudyProgressService _service = StudyProgressService();

  @override
  AsyncValue<StudyProgress> build(String userId) {
    _subscription?.cancel();

    state = const AsyncValue.loading();

    _subscription = _service.watchProgress(userId).listen(
      (progress) {
        state = AsyncValue.data(progress);
      },
      onError: (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      },
    );

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return state;
  }
}

