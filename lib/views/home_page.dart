import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/providers/auth_providers.dart';
import '../controllers/providers/course_providers.dart';
import '../controllers/providers/user_providers.dart';
import 'widgets/notification_bell_button.dart';
import 'widgets/study_progress_overview.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const Color _brandBlue = Color(0xFF1A73E8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text("Error: $err"))),
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: Text("Not logged in")));
        }

        final courses = ref.watch(courseListProvider(user.uid));

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset('asset/logo.png', height: 32),
                          const SizedBox(width: 8),
                        ],
                      ),
                      Row(
                        children: [
                          Consumer(
                            builder: (context, ref, _) {
                              final profile = ref
                                  .watch(userProfileStreamProvider)
                                  .asData
                                  ?.value;
                              final photoUrl = profile?.photoUrl;
                              final displayName = profile?.displayName ?? '';
                              String initials = '';
                              if (displayName.isNotEmpty) {
                                final parts = displayName.trim().split(
                                  RegExp(r'\s+'),
                                );
                                if (parts.isNotEmpty) {
                                  initials = parts
                                      .take(2)
                                      .map(
                                        (p) => p.isNotEmpty
                                            ? p[0].toUpperCase()
                                            : '',
                                      )
                                      .join();
                                }
                              } else if (user.email != null &&
                                  user.email!.isNotEmpty) {
                                initials = user.email![0].toUpperCase();
                              }
                              return GestureDetector(
                                onTap: () => context.pushNamed('profileEdit'),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundImage:
                                          (photoUrl != null &&
                                              photoUrl.isNotEmpty)
                                          ? NetworkImage(photoUrl)
                                          : null,
                                      child:
                                          (photoUrl == null || photoUrl.isEmpty)
                                          ? Text(
                                              initials,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.calendar_today),
                            tooltip: 'Calendar',
                            onPressed: () {
                              context.pushNamed('calendar');
                            },
                          ),
                          NotificationBellButton(
                            userId: user.uid,
                            onPressed: () {
                              context.pushNamed('notifications');
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout),
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Friendly greeting with first name (prominent)
                  Consumer(
                    builder: (context, ref, _) {
                      final profile = ref
                          .watch(userProfileStreamProvider)
                          .asData
                          ?.value;
                      final displayName = profile?.displayName ?? '';
                      String firstName = '';
                      if (displayName.isNotEmpty) {
                        firstName = displayName
                            .trim()
                            .split(RegExp(r'\s+'))
                            .first;
                      } else if (user.email != null && user.email!.isNotEmpty) {
                        firstName = user.email!.split('@').first;
                      }
                      if (firstName.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          'Hey, $firstName',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF101828),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Study Progress Overview
                  StudyProgressOverview(userId: user.uid),

                  const SizedBox(height: 24),
                  const Text(
                    'Your Courses',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF101828),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Course list
                  Expanded(
                    child: courses.isEmpty
                        ? const Center(
                            child: Text(
                              'No courses yet. Tap "+ New Course" to add one.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: courses.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final course = courses[index];
                              return InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () {
                                  context.pushNamed(
                                    'courseDetail',
                                    pathParameters: {'courseId': course.id},
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
                                        color: Colors.black.withOpacity(0.03),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          course.title,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF101828),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: const Text(
                                                  "Delete Course?",
                                                ),
                                                content: const Text(
                                                  "This will permanently delete:\n"
                                                  "• All materials and their PDF files\n"
                                                  "• OpenAI vector store data\n"
                                                  "• All quizzes in this course\n"
                                                  "• All attempts for those quizzes\n\n"
                                                  "This action cannot be undone.",
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          context,
                                                          false,
                                                        ),
                                                    child: const Text("Cancel"),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          context,
                                                          true,
                                                        ),
                                                    child: const Text(
                                                      "Delete",
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );

                                          if (confirm != true) return;

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: _DeletingSnackBar(
                                                label: "Deleting course…",
                                              ),
                                            ),
                                          );

                                          try {
                                            await ref
                                                .read(
                                                  courseListProvider(
                                                    user.uid,
                                                  ).notifier,
                                                )
                                                .remove(course.id);

                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Course deleted successfully.",
                                                ),
                                              ),
                                            );
                                          } catch (e) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  "Failed to delete course: $e",
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 16),

                  // + New Course button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        final controller = TextEditingController();
                        final result = await showDialog<String>(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Add Course'),
                              content: TextField(
                                controller: controller,
                                decoration: const InputDecoration(
                                  labelText: 'Course name',
                                  hintText: 'e.g. COMP 101',
                                ),
                                autofocus: true,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    final title = controller.text.trim();
                                    Navigator.of(context).pop(title);
                                  },
                                  child: const Text('Add'),
                                ),
                              ],
                            );
                          },
                        );

                        final title = result?.trim();
                        if (title != null && title.isNotEmpty) {
                          await ref
                              .read(courseListProvider(user.uid).notifier)
                              .add(title: title);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brandBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '+ New Course',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
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

class _DeletingSnackBar extends StatelessWidget {
  const _DeletingSnackBar({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
