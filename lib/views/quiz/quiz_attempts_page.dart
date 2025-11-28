import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/providers/auth_providers.dart';
import '../../controllers/providers/quiz_providers.dart';

class QuizAttemptsPage extends ConsumerWidget {
  const QuizAttemptsPage({
    super.key,
    required this.courseId,
    required this.quizId,
  });

  final String courseId;
  final String quizId;

  static const Color _brandBlue = Color(0xFF1A73E8);
  static const Color _navy = Color(0xFF101828);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) =>
          Scaffold(body: Center(child: Text('Error: $err'))),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Not logged in')),
          );
        }

        final attempts =
            ref.watch(quizAttemptsProvider((user.uid, courseId, quizId)));

        final myAttempts = attempts
            .where((a) => a.userId == user.uid)
            .toList()
          ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER: back + StudyEarly logo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'asset/logo.png',
                            height: 26,
                          ),
                          const SizedBox(width: 6),
                        ],
                      ),
                      const SizedBox(width: 48), // spacer
                    ],
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'My Attempts',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: _navy,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Expanded(
                    child: myAttempts.isEmpty
                        ? const Center(
                            child: Text(
                              'No attempts yet.\nTake the quiz to see your results here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: myAttempts.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final a = myAttempts[index];
                              final when =
                                  _formatDateTime(a.completedAt ?? a.startedAt);
                              final score =
                                  '${a.numCorrect}/${a.numTotal}';

                              return InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () {
                                  context.pushNamed(
                                    'quizAttemptDetail',
                                    pathParameters: {
                                      'courseId': courseId,
                                      'quizId': quizId,
                                      'attemptId': a.id,
                                    },
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                        color:
                                            Colors.black.withOpacity(0.03),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.history,
                                        color: _navy,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Attempt ${index + 1}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: _navy,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              when,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Score: $score',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: _navy,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

String _two(int v) => v.toString().padLeft(2, '0');
String _formatDateTime(DateTime d) {
  final local = d.toLocal();
  final y = local.year.toString();
  final m = _two(local.month);
  final day = _two(local.day);
  final hh = _two(local.hour);
  final mm = _two(local.minute);
  return '$y-$m-$day $hh:$mm';
}
