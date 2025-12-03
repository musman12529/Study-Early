import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/material_summary.dart';
import '../notifiers/material_summary_notifier.dart';

final materialSummaryProvider = NotifierProvider.family<
    MaterialSummaryNotifier,
    AsyncValue<MaterialSummary?>,
    (String creatorId, String courseId, List<String> materialIds)>(
  MaterialSummaryNotifier.new,
);

