import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../views/home_page.dart';
import '../views/auth/login_screen.dart';
import '../views/auth/error_screen.dart';
import 'controllers/providers/auth_providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.asData?.value;

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,

    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/login';

      if (user == null) {
        return loggingIn ? null : '/login';
      }

      if (loggingIn) {
        return '/';
      }

      return null;
    },

    routes: [
      GoRoute(
        name: 'home',
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        name: 'login',
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
    ],

    errorBuilder: (context, state) => ErrorScreen(error: state.error),
  );
});
