import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifiers/profile_photo_notifier.dart';

final profilePhotoProvider =
    NotifierProvider<ProfilePhotoNotifier, ProfilePhotoState>(
      ProfilePhotoNotifier.new,
    );
