import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/study_progress.dart';
import '../notifiers/study_progress_notifier.dart';
import '../services/study_progress_service.dart';

final studyProgressServiceProvider = Provider<StudyProgressService>((ref) {
  return StudyProgressService();
});

final studyProgressProvider =
    NotifierProvider.family<StudyProgressNotifier, AsyncValue<StudyProgress>, String>(
  StudyProgressNotifier.new,
);

