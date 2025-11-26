import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../views/home_page.dart';
import '../views/role_selection_page.dart';
import '../views/auth/login_screen.dart';
import '../views/auth/error_screen.dart';
import 'controllers/providers/auth_providers.dart';
import 'views/course_detail_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.asData?.value;

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,

    redirect: (context, state) {
      if (authState.isLoading) return null;

      final loggedIn = user != null;
      final goingToLogin = state.matchedLocation == '/login';
      final goingToRoleSelection = state.matchedLocation == '/';

      if (!loggedIn) {
        if (goingToLogin || goingToRoleSelection) return null;
        return '/login';
      }

      if (goingToLogin || goingToRoleSelection) {
        return '/home';
      }

      return null;
    },

    routes: [
      GoRoute(
        name: 'roleSelection',
        path: '/',
        builder: (context, state) => const RoleSelectionPage(),
      ),
      GoRoute(
        name: 'home',
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        name: 'login',
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        name: 'courseDetail',
        path: '/course/:courseId',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId']!;
          return CourseDetailPage(courseId: courseId);
        },
      ),
    ],

    errorBuilder: (context, state) => ErrorScreen(error: state.error),
  );
});
