import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../views/home_page.dart';
import '../views/role_selection_page.dart';
import '../views/auth/sign_in_screen.dart';
import '../views/auth/sign_up_screen.dart';
import '../views/auth/error_screen.dart';
import '../views/notifications/notifications_page.dart';
import 'controllers/providers/auth_providers.dart';
import 'controllers/providers/user_providers.dart';
import 'models/user_profile.dart';
import 'views/course_detail_page.dart';
import 'views/quiz/quiz_list_page.dart';
import 'views/quiz/quiz_take_page.dart';
import 'views/quiz/quiz_attempts_page.dart';
import 'views/quiz/quiz_attempt_detail_page.dart';
import 'views/chat/chat_page.dart';
import 'views/auth/onboarding_screen.dart';
import 'views/professor/professor_dashboard_page.dart';
import 'views/professor/professor_quiz_view_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.asData?.value;
  final profileState = ref.watch(userProfileStreamProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,

    redirect: (context, state) {
      if (authState.isLoading) return null;
      final profileLoading = profileState.isLoading;

      final loggedIn = user != null;
      final goingToLogin = state.matchedLocation == '/login';
      final goingToSignUp = state.matchedLocation == '/signup';
      final goingToStudentSignUp = state.matchedLocation == '/signup/student';
      final goingToProfessorSignUp =
          state.matchedLocation == '/signup/professor';
      final goingToOnboarding = state.matchedLocation == '/onboarding';
      final goingToProfessorDashboard = state.matchedLocation == '/professor';
      final goingToHome = state.matchedLocation == '/home';
      final goingToRoleSelection = state.matchedLocation == '/';

      if (!loggedIn) {
        if (goingToLogin ||
            goingToSignUp ||
            goingToStudentSignUp ||
            goingToProfessorSignUp ||
            goingToRoleSelection) {
          return null;
        }
        return '/login';
      }

      if (profileLoading) {
        return null;
      }

      final profile = profileState.asData?.value;
      final needsOnboarding =
          profile == null || ((profile.displayName ?? '').trim().isEmpty);
      final isProfessor = profile != null && profile.role == UserRole.professor;
      if (needsOnboarding && !goingToOnboarding) {
        return '/onboarding';
      }

      if (!needsOnboarding && goingToOnboarding) {
        return isProfessor ? '/professor' : '/home';
      }

      // Gate professor dashboard to professors only
      if (goingToProfessorDashboard &&
          profile != null &&
          profile.role != UserRole.professor) {
        return '/home';
      }

      // Route professors to their dashboard by default from generic pages
      if (isProfessor &&
          (goingToRoleSelection ||
              goingToLogin ||
              goingToSignUp ||
              goingToStudentSignUp ||
              goingToProfessorSignUp ||
              goingToHome)) {
        return '/professor';
      }

      if (goingToLogin ||
          goingToSignUp ||
          goingToStudentSignUp ||
          goingToProfessorSignUp ||
          goingToRoleSelection) {
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
        name: 'signupStudent',
        path: '/signup/student',
        builder: (context, state) => const SignUpScreen(role: UserRole.student),
      ),
      GoRoute(
        name: 'signupProfessor',
        path: '/signup/professor',
        builder: (context, state) =>
            const SignUpScreen(role: UserRole.professor),
      ),
      GoRoute(
        name: 'onboarding',
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        name: 'professorDashboard',
        path: '/professor',
        builder: (context, state) => const ProfessorDashboardPage(),
      ),
      GoRoute(
        name: 'professorQuizView',
        path: '/course/:courseId/quiz/:quizId/professor',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId']!;
          final quizId = state.pathParameters['quizId']!;
          return ProfessorQuizViewPage(courseId: courseId, quizId: quizId);
        },
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
      GoRoute(
        name: 'notifications',
        path: '/notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
    ],

    errorBuilder: (context, state) => ErrorScreen(error: state.error),
  );
});
