import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/course_material.dart';
import '../notifiers/course_material_notifier.dart';

final courseMaterialListProvider =
    NotifierProvider.family<
      CourseMaterialListNotifier,
      List<CourseMaterial>,
      (String creatorId, String courseId)
    >(CourseMaterialListNotifier.new);
