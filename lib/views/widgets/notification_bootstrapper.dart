import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers/auth_providers.dart';
import '../../controllers/providers/notification_providers.dart';

class NotificationBootstrapper extends ConsumerStatefulWidget {
  const NotificationBootstrapper({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationBootstrapper> createState() =>
      _NotificationBootstrapperState();
}

class _NotificationBootstrapperState
    extends ConsumerState<NotificationBootstrapper> {
  @override
  void initState() {
    super.initState();
    ref.listen<AsyncValue<User?>>(
      authStateChangesProvider,
      (previous, next) => _handleAuthChange(next),
    );
    Future.microtask(() {
      final current = ref.read(authStateChangesProvider);
      _handleAuthChange(current);
    });
  }

  Future<void> _handleAuthChange(AsyncValue<User?> authValue) async {
    final service = ref.read(notificationServiceProvider);

    await authValue.when(
      data: (user) async {
        if (user != null) {
          await service.startForUser(user.uid);
        } else {
          await service.stop();
        }
      },
      loading: () async {},
      error: (_, __) async => service.stop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

