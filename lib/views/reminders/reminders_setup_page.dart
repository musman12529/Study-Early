import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/providers/auth_providers.dart';
import '../../controllers/providers/reminder_providers.dart';
import '../../models/reminder_settings.dart';

class RemindersSetupPage extends ConsumerStatefulWidget {
  const RemindersSetupPage({super.key});

  @override
  ConsumerState<RemindersSetupPage> createState() =>
      _RemindersSetupPageState();
}

class _RemindersSetupPageState extends ConsumerState<RemindersSetupPage> {
  static const Color _accentRed = Color(0xFFFF6B6B);
  static const Color _navy = Color(0xFF101828);

  bool _pushNotificationsEnabled = false;
  ReminderFrequency _frequency = ReminderFrequency.daily;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isSaving = false;
  bool _hasHydratedFromSettings = false;

  @override
  void initState() {
    super.initState();
    // Settings will be loaded reactively via ref.watch in build method
  }

  Future<void> _saveSettings() async {
    final authState = ref.read(authStateChangesProvider);
    final user = authState.asData?.value;
    if (user == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final settings = ReminderSettings(
        userId: user.uid,
        pushNotificationsEnabled: _pushNotificationsEnabled,
        frequency: _frequency,
        time: _selectedTime,
      );

      await ref
          .read(reminderSettingsProvider(user.uid).notifier)
          .saveSettings(settings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reminder settings saved successfully'),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateChangesProvider);
    
    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(child: Text('Error: $err')),
      ),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Not logged in')),
          );
        }

        // Watch reminder settings and update local state when they change
        final settingsAsync = ref.watch(reminderSettingsProvider(user.uid));
        
        // Listen for changes and update local state
        ref.listen<AsyncValue<ReminderSettings?>>(
          reminderSettingsProvider(user.uid),
          (previous, next) {
            final settings = next.value;
            if (settings != null && mounted) {
              // Only update if values actually changed to avoid unnecessary rebuilds
              if (_pushNotificationsEnabled != settings.pushNotificationsEnabled ||
                  _frequency != settings.frequency ||
                  _selectedTime.hour != settings.time.hour ||
                  _selectedTime.minute != settings.time.minute) {
                setState(() {
                  _pushNotificationsEnabled = settings.pushNotificationsEnabled;
                  _frequency = settings.frequency;
                  _selectedTime = settings.time;
                });
              }
            }
          },
        );
        
        // Also check current value on first load only
        final currentSettings = settingsAsync.value;
        if (!_hasHydratedFromSettings &&
            currentSettings != null &&
            mounted) {
          _hasHydratedFromSettings = true;
          // Use a post-frame callback to avoid setState during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _pushNotificationsEnabled =
                  currentSettings.pushNotificationsEnabled;
              _frequency = currentSettings.frequency;
              _selectedTime = currentSettings.time;
            });
          });
        }

        return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),

              const SizedBox(height: 24),

              // Title
              const Text(
                'Reminders',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: _navy,
                ),
              ),

              const SizedBox(height: 8),

              // Description
              Text(
                'Setting reminders on your courses helps you stay up to date.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 32),

              // Push notifications section
              const Text(
                'Push notifications',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _navy,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                'Real time alerts on your device.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox.shrink(),
                  Switch(
                    value: _pushNotificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _pushNotificationsEnabled = value;
                      });
                    },
                    activeColor: Colors.green,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Frequency section
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
                      isSelected: _frequency == ReminderFrequency.daily,
                      onTap: () {
                        setState(() {
                          _frequency = ReminderFrequency.daily;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FrequencyButton(
                      label: 'Weekly',
                      isSelected: _frequency == ReminderFrequency.weekly,
                      onTap: () {
                        setState(() {
                          _frequency = ReminderFrequency.weekly;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FrequencyButton(
                      label: 'BiWeekly',
                      isSelected: _frequency == ReminderFrequency.biWeekly,
                      onTap: () {
                        setState(() {
                          _frequency = ReminderFrequency.biWeekly;
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Time section
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

              // Save button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveSettings,
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
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
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

