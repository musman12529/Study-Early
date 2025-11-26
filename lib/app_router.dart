import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../views/home_page.dart';
import '../views/auth/login_screen.dart';
import '../views/auth/error_screen.dart';
import 'controllers/providers/auth_providers.dart';
import 'views/course_detail_page.dart';
import 'views/quiz/quiz_list_page.dart';
import 'views/quiz/quiz_take_page.dart';
import 'views/quiz/quiz_attempts_page.dart';
import 'views/quiz/quiz_attempt_detail_page.dart';
import 'views/chat/chat_page.dart';

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
      GoRoute(
        name: 'courseDetail',
        path: '/course/:courseId',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId']!;
          return CourseDetailPage(courseId: courseId);
        },
      ),
      GoRoute(
        name: 'quizList',
        path: '/course/:courseId/quizzes',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId']!;
          return QuizListPage(courseId: courseId);
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
      GoRoute(
        name: 'chat',
        path: '/course/:courseId/chat',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId']!;
          return ChatPage(courseId: courseId);
        },
      ),
    ],

    errorBuilder: (context, state) => ErrorScreen(error: state.error),
  );
});
