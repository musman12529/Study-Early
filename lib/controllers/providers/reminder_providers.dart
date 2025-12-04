import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/reminder_settings.dart';

final reminderSettingsProvider = NotifierProvider.family<
    ReminderSettingsNotifier,
    AsyncValue<ReminderSettings?>,
    String>(ReminderSettingsNotifier.new);

class ReminderSettingsNotifier
    extends FamilyNotifier<AsyncValue<ReminderSettings?>, String> {
  StreamSubscription<DocumentSnapshot>? _subscription;

  @override
  AsyncValue<ReminderSettings?> build(String userId) {
    _subscription?.cancel();
    _subscription = FirebaseFirestore.instance
        .collection('reminderSettings')
        .doc(userId)
        .snapshots()
        .listen(
      (snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data()!;
          final settings = ReminderSettings.fromMap(userId, data);
          state = AsyncValue.data(settings);
        } else {
          state = AsyncValue.data(null);
        }
      },
      onError: (error, stack) {
        state = AsyncValue.error(error, stack);
      },
    );

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return const AsyncValue.loading();
  }

  Future<void> saveSettings(ReminderSettings settings) async {
    try {
      await FirebaseFirestore.instance
          .collection('reminderSettings')
          .doc(settings.userId)
          .set(settings.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save reminder settings: $e');
    }
  }
}

