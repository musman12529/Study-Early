import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/providers/auth_providers.dart';
import '../../controllers/providers/course_reminder_providers.dart';
import '../../models/course_reminder_settings.dart';

class CourseReminderSetupPage extends ConsumerStatefulWidget {
  const CourseReminderSetupPage({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  final String courseId;
  final String courseTitle;

  @override
  ConsumerState<CourseReminderSetupPage> createState() =>
      _CourseReminderSetupPageState();
}

class _CourseReminderSetupPageState
    extends ConsumerState<CourseReminderSetupPage> {
  static const Color _accentRed = Color(0xFFFF6B6B);
  static const Color _navy = Color(0xFF101828);

  bool _enabled = false;
  CourseReminderFrequency _frequency = CourseReminderFrequency.daily;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isSaving = false;
  bool _hydrated = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        body: Center(child: Text('Error: $err')),
      ),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Not logged in')),
          );
        }

        final key = (
          userId: user.uid,
          courseId: widget.courseId,
          courseTitle: widget.courseTitle,
        );
        final settingsAsync = ref.watch(courseReminderSettingsProvider(key));

        settingsAsync.whenData((settings) {
          if (!_hydrated && settings != null && mounted) {
            _hydrated = true;
            setState(() {
              _enabled = settings.enabled;
              _frequency = settings.frequency;
              _selectedTime = settings.time;
            });
          }
        });

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => context.pop(),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset('asset/logo.png', height: 26),
                          const SizedBox(width: 6),
                        ],
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Text(
                    widget.courseTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Course reminder',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: _navy,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Get a reminder to review this course on your schedule.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    'Enable reminder',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _enabled ? 'On' : 'Off',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Switch(
                        value: _enabled,
                        onChanged: (value) {
                          setState(() {
                            _enabled = value;
                          });
                        },
                        activeColor: Colors.green,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    'Frequency',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _FrequencyButton(
                          label: 'Daily',
                          isSelected:
                              _frequency == CourseReminderFrequency.daily,
                          onTap: () {
                            setState(() {
                              _frequency = CourseReminderFrequency.daily;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FrequencyButton(
                          label: 'Weekly',
                          isSelected:
                              _frequency == CourseReminderFrequency.weekly,
                          onTap: () {
                            setState(() {
                              _frequency = CourseReminderFrequency.weekly;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FrequencyButton(
                          label: 'BiWeekly',
                          isSelected:
                              _frequency == CourseReminderFrequency.biWeekly,
                          onTap: () {
                            setState(() {
                              _frequency = CourseReminderFrequency.biWeekly;
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    'Time',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 12),

                  InkWell(
                    onTap: _selectTime,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTime(_selectedTime),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: _navy,
                            ),
                          ),
                          Icon(
                            Icons.access_time,
                            color: Colors.grey.shade600,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : () => _save(user.uid),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentRed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Save',
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

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _accentRed,
              onPrimary: Colors.white,
              onSurface: _navy,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour == 0
        ? 12
        : time.hour > 12
            ? time.hour - 12
            : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Future<void> _save(String userId) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final settings = CourseReminderSettings(
        userId: userId,
        courseId: widget.courseId,
        courseTitle: widget.courseTitle,
        enabled: _enabled,
        frequency: _frequency,
        time: _selectedTime,
      );

      final key = (
        userId: userId,
        courseId: widget.courseId,
        courseTitle: widget.courseTitle,
      );

      await ref
          .read(courseReminderSettingsProvider(key).notifier)
          .saveSettings(settings);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Course reminder saved.'),
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save reminder: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

class _FrequencyButton extends StatelessWidget {
  const _FrequencyButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  static const Color _accentRed = Color(0xFFFF6B6B);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? _accentRed : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? _accentRed : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}


