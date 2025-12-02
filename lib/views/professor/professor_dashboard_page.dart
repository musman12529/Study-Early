import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers/auth_providers.dart';
import '../../controllers/providers/course_providers.dart';
import '../../controllers/providers/user_providers.dart';
import '../../models/user_profile.dart';
import '../widgets/notification_bell_button.dart';
import 'package:go_router/go_router.dart';

class ProfessorDashboardPage extends ConsumerStatefulWidget {
  const ProfessorDashboardPage({super.key});

  @override
  ConsumerState<ProfessorDashboardPage> createState() =>
      _ProfessorDashboardPageState();
}

class _ProfessorDashboardPageState
    extends ConsumerState<ProfessorDashboardPage> {
  static const Color _navy = Color(0xFF101828);

  String? _selectedCourseId;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateChangesProvider);
    final profileState = ref.watch(userProfileStreamProvider);

    return authState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: Text('Not logged in')));
        }
        final profile = profileState.asData?.value;
        if (profile == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (profile.role != UserRole.professor) {
          return const Scaffold(
            body: Center(child: Text('Professor access only')),
          );
        }

        final courses = ref.watch(courseListProvider(user.uid));
        _selectedCourseId ??= courses.isNotEmpty ? courses.first.id : null;

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
                          NotificationBellButton(
                            userId: user.uid,
                            onPressed: () {
                              if (context.mounted) {
                                Navigator.of(
                                  context,
                                ).pushNamed('notifications');
                              }
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
                  const Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF101828),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(height: 8),
                  const Text(
                    'Students',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Add student (coming soon)'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add student'),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Your Courses',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: courses.isEmpty
                        ? const Center(
                            child: Text(
                              'No courses yet. Tap "+ New Course" to add one.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                              textAlign: TextAlign.center,
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
                                  // Navigate to course detail (materials + quizzes)
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

                                          final messenger =
                                              ScaffoldMessenger.of(context);
                                          messenger.showSnackBar(
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
                                            messenger.showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Course deleted successfully.",
                                                ),
                                              ),
                                            );
                                          } catch (e) {
                                            messenger.showSnackBar(
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
                        backgroundColor: const Color(0xFF1A73E8),
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

  // (Material upload removed; professors can manage materials inside course pages)
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
