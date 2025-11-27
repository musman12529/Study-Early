import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../views/home_page.dart';
import '../views/role_selection_page.dart';
import '../views/auth/sign_in_screen.dart';
import '../views/auth/sign_up_screen.dart';
import '../views/auth/error_screen.dart';
import '../controllers/providers/auth_providers.dart';
import '../views/course_detail_page.dart';
import '../views/quiz/quiz_list_page.dart';
import '../views/quiz/quiz_take_page.dart';
import '../views/quiz/quiz_attempts_page.dart';
import '../views/quiz/quiz_attempt_detail_page.dart';

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
      final goingToSignUp = state.matchedLocation == '/signup';
      final goingToRoleSelection = state.matchedLocation == '/';

      if (!loggedIn) {
        if (goingToLogin || goingToSignUp || goingToRoleSelection) {
          return null;
        }
        return '/login';
      }

      if (goingToLogin || goingToSignUp || goingToRoleSelection) {
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
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        name: 'signup',
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        name: 'courseDetail',
        path: '/course/:courseId',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId']!;
          final title = state.uri.queryParameters['title'] ?? courseId;
          return CourseDetailPage(
            courseId: courseId,
            courseTitle: title,
          );
        },
      ),
      GoRoute(
        name: 'quizTake',
        path: '/course/:courseId/quiz/:quizId',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId']!;
          final quizId = state.pathParameters['quizId']!;
          return QuizTakePage(courseId: courseId, quizId: quizId);
        },
      ),
      GoRoute(
        name: 'quizAttempts',
        path: '/course/:courseId/quiz/:quizId/attempts',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId']!;
          final quizId = state.pathParameters['quizId']!;
          return QuizAttemptsPage(courseId: courseId, quizId: quizId);
        },
      ),
      GoRoute(
        name: 'quizAttemptDetail',
        path: '/course/:courseId/quiz/:quizId/attempt/:attemptId',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId']!;
          final quizId = state.pathParameters['quizId']!;
          final attemptId = state.pathParameters['attemptId']!;
          return QuizAttemptDetailPage(
            courseId: courseId,
            quizId: quizId,
            attemptId: attemptId,
          );
        },
      ),
    ],

    errorBuilder: (context, state) => ErrorScreen(error: state.error),
  );
});
