import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/providers/auth_providers.dart';
import '../controllers/providers/course_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

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
          appBar: AppBar(
            title: const Text('Home Page'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
              ),
            ],
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return Card(
                child: ListTile(
                  title: Text(course.title),
                  leading: const Icon(Icons.school),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("Delete Course?"),
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
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  "Delete",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirm != true) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: _DeletingSnackBar(label: "Deleting course…"),
                        ),
                      );

                      try {
                        await ref
                            .read(courseListProvider(user.uid).notifier)
                            .remove(course.id);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Course deleted successfully."),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Failed to delete course: $e"),
                          ),
                        );
                      }
                    },
                  ),
                  onTap: () {
                    context.pushNamed(
                      'courseDetail',
                      pathParameters: {'courseId': course.id},
                    );
                  },
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
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
            child: const Icon(Icons.add),
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
      children: const [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: 8),
        // Use a Flexible Text to avoid overflow in some locales
        Expanded(child: Text("Deleting course…")),
      ],
    );
  }
}
