import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers/auth_providers.dart';
import '../../controllers/providers/notification_providers.dart';

class NotificationBootstrapper extends ConsumerWidget {
  const NotificationBootstrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<User?>>(
      authStateChangesProvider,
      (previous, next) {
        final service = ref.read(notificationServiceProvider);
        next.when(
          data: (user) {
            if (user != null) {
              service.startForUser(user.uid);
            } else {
              service.stop();
            }
          },
          loading: () {},
          error: (_, __) => service.stop(),
        );
      },
    );
    return child;
  }
}

