import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers/auth_providers.dart';
import '../../controllers/providers/calendar_provider.dart';
import '../../controllers/providers/course_providers.dart';
import '../../models/calendar_event.dart';
import '../../models/course_material.dart';
import '../../controllers/providers/course_material_provider.dart';

class AddEventDialog extends ConsumerStatefulWidget {
  const AddEventDialog({
    super.key,
    required this.userId,
    this.event,
    this.courseId,
  });

  final String userId;
  final CalendarEvent? event; // If provided, we're editing
  final String? courseId; // Required if creating new event

  @override
  ConsumerState<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends ConsumerState<AddEventDialog> {
  static const Color _brandBlue = Color(0xFF1A73E8);

  final _titleController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  EventType _selectedType = EventType.lecture;
  String? _selectedCourseId;
  String? _selectedMaterialId;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.event != null;
    if (_isEditing && widget.event != null) {
      _titleController.text = widget.event!.title;
      _selectedDate = widget.event!.date;
      _selectedTime = widget.event!.time != null
          ? TimeOfDay.fromDateTime(widget.event!.time!)
          : null;
      _selectedType = widget.event!.type;
      _selectedCourseId = widget.event!.courseId;
      _selectedMaterialId = widget.event!.materialId;
    } else {
      _selectedDate = DateTime.now();
      _selectedCourseId = widget.courseId;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courses = ref.watch(courseListProvider(widget.userId));

    return AlertDialog(
      title: Text(_isEditing ? 'Edit Event' : 'Add Event'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Event type
            const Text('Type', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<EventType>(
                    title: const Text('Lecture'),
                    value: EventType.lecture,
                    groupValue: _selectedType,
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value!;
                        if (_selectedType != EventType.assignment) {
                          _selectedMaterialId = null;
                        }
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<EventType>(
                    title: const Text('Exam'),
                    value: EventType.exam,
                    groupValue: _selectedType,
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value!;
                        if (_selectedType != EventType.assignment) {
                          _selectedMaterialId = null;
                        }
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<EventType>(
                    title: const Text('Assignment'),
                    value: EventType.assignment,
                    groupValue: _selectedType,
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Course selection (disabled when editing)
            const Text('Course', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCourseId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select course',
              ),
              items: courses.map((course) {
                return DropdownMenuItem(
                  value: course.id,
                  child: Text(course.title),
                );
              }).toList(),
              onChanged: _isEditing
                  ? null
                  : (value) {
                      setState(() {
                        _selectedCourseId = value;
                        _selectedMaterialId = null;
                      });
                    },
            ),
            const SizedBox(height: 16),

            // Material selection (only for assignments)
            if (_selectedType == EventType.assignment && _selectedCourseId != null)
              _buildMaterialSelector(),

            const SizedBox(height: 16),

            // Date picker
            Row(
              children: [
                const Text('Date: ', style: TextStyle(fontWeight: FontWeight.w600)),
                TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDate = date;
                      });
                    }
                  },
                  child: Text(
                    _selectedDate != null
                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                        : 'Select date',
                  ),
                ),
              ],
            ),

            // Time picker (optional)
            Row(
              children: [
                const Text('Time: ', style: TextStyle(fontWeight: FontWeight.w600)),
                TextButton(
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime ?? TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() {
                        _selectedTime = time;
                      });
                    }
                  },
                  child: Text(
                    _selectedTime != null
                        ? _selectedTime!.format(context)
                        : 'Optional',
                  ),
                ),
                if (_selectedTime != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedTime = null;
                      });
                    },
                    child: const Text('Clear'),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
          ElevatedButton(
          onPressed: _canSave() ? _saveEvent : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _brandBlue,
            foregroundColor: Colors.white,
          ),
          child: Text(_isEditing ? 'Update' : 'Save'),
        ),
      ],
    );
  }

  Widget _buildMaterialSelector() {
    if (_selectedCourseId == null) return const SizedBox.shrink();

    final materials = ref.watch(
      courseMaterialListProvider((widget.userId, _selectedCourseId!)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Material (Optional)',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedMaterialId,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Select material',
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('None'),
            ),
            ...materials
                .where((m) => m.status == MaterialStatus.indexed)
                .map((material) {
              return DropdownMenuItem(
                value: material.id,
                child: Text(material.fileName),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _selectedMaterialId = value;
            });
          },
        ),
      ],
    );
  }

  bool _canSave() {
    return _titleController.text.isNotEmpty &&
        _selectedDate != null &&
        _selectedCourseId != null;
  }

  Future<void> _saveEvent() async {
    if (!_canSave()) return;

    try {
      final date = _selectedDate!;
      DateTime? time;
      if (_selectedTime != null) {
        time = DateTime(
          date.year,
          date.month,
          date.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
      }

      if (_isEditing && widget.event != null) {
        // Update existing event
        final updatedEvent = widget.event!.copyWith(
          title: _titleController.text,
          date: date,
          time: time,
          type: _selectedType,
          materialId: _selectedMaterialId,
        );

        await ref
            .read(
              calendarEventListProvider((
                widget.userId,
                _selectedCourseId!,
              )).notifier,
            )
            .updateEvent(updatedEvent);

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event updated successfully')),
          );
        }
      } else {
        // Create new event
        await ref
            .read(
              calendarEventListProvider((
                widget.userId,
                _selectedCourseId!,
              )).notifier,
            )
            .createEvent(
              title: _titleController.text,
              date: date,
              time: time,
              type: _selectedType,
              materialId: _selectedMaterialId,
            );

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event added successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Error updating event: $e'
                  : 'Error adding event: $e',
            ),
          ),
        );
      }
    }
  }
}

