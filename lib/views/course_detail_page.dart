import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/providers/auth_providers.dart';
import '../controllers/providers/course_material_provider.dart';
import '../models/course_material.dart';

class CourseDetailPage extends ConsumerWidget {
  const CourseDetailPage({super.key, required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: Text('Not logged in')));
        }

        final materials = ref.watch(
          courseMaterialListProvider((user.uid, courseId)),
        );

        return Scaffold(
          appBar: AppBar(title: const Text('Course Materials')),
          body: materials.isEmpty
              ? const Center(child: Text('No materials yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: materials.length,
                  itemBuilder: (context, index) {
                    final m = materials[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.picture_as_pdf),
                        title: Text(m.fileName),
                        subtitle: Text('Status: ${m.status.asString}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (m.status == MaterialStatus.error)
                              IconButton(
                                tooltip: 'Retry indexing',
                                icon: const Icon(Icons.refresh),
                                onPressed: () async {
                                  // Optional: quick feedback
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Retrying indexing...'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                  await ref
                                      .read(
                                        courseMaterialListProvider((
                                          user.uid,
                                          courseId,
                                        )).notifier,
                                      )
                                      .retry(m);
                                },
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                if (m.status == MaterialStatus.indexing) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Cannot delete while indexing.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                await ref
                                    .read(
                                      courseMaterialListProvider((
                                        user.uid,
                                        courseId,
                                      )).notifier,
                                    )
                                    .remove(m.id);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              await _pickUploadAndIndex(context, ref, user, courseId);
            },
            icon: const Icon(Icons.upload_file),
            label: const Text('Add PDF'),
          ),
        );
      },
    );
  }

  Future<void> _pickUploadAndIndex(
    BuildContext context,
    WidgetRef ref,
    User user,
    String courseId,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );

    if (result == null) return;

    final picked = result.files.single;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await ref
          .read(courseMaterialListProvider((user.uid, courseId)).notifier)
          .uploadAndIndex(fileName: picked.name, filePath: picked.path!);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload + indexing complete.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      Navigator.of(context).pop();
    }
  }
}
