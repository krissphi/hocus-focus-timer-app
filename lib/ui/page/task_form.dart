import 'package:flutter/material.dart';
import 'package:timtam/ui/widget/form/bottom_sheet_layout.dart';
import 'package:timtam/ui/widget/form/color_picker.dart';
import 'package:timtam/ui/widget/form/day_picker.dart';
import 'package:timtam/ui/widget/form/dialog_layout.dart';

import '../../data/model/task.dart';
import '../utils/task_color_palette.dart';
import '../utils/type_device_utils.dart';

class TaskFormDialog extends StatefulWidget {
  const TaskFormDialog({super.key, this.initialTask});

  final Task? initialTask;

  @override
  State<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<TaskFormDialog> {
  final formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _hourController = TextEditingController();
  final _minuteController = TextEditingController();

  TaskScheduleType _scheduleType = TaskScheduleType.daily;
  final Set<int> _selectedDays = <int>{};
  int _selectedColorValue = TaskColorPalette.defaultColor().toARGB32();

  bool get _isEditing => widget.initialTask != null;

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    if (task == null) {
      return;
    }

    _titleController.text = task.title;
    final hours = task.targetDurationMinutes ~/ 60;
    final minutes = task.targetDurationMinutes % 60;
    _hourController.text = hours == 0 ? '' : hours.toString();
    _minuteController.text = minutes == 0 ? '' : minutes.toString();
    _scheduleType = task.scheduleType;
    _selectedDays
      ..clear()
      ..addAll(task.customDays);
    _selectedColorValue = task.colorValue;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    final hours = int.tryParse(_hourController.text.trim()) ?? 0;
    final minutes = int.tryParse(_minuteController.text.trim()) ?? 0;
    final duration = (hours * 60) + minutes;

    final taskId =
        widget.initialTask?.id ??
        DateTime.now().microsecondsSinceEpoch.toString();

    if ((hours * 60) + minutes == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set a target duration.')),
      );
      return;
    }

    final task = Task(
      id: taskId,
      title: title,
      targetDurationMinutes: duration,
      colorValue: _selectedColorValue,
      scheduleType: _scheduleType,
      customDays: _selectedDays.toList()..sort(),
    );

    Navigator.of(context).pop(task);
  }

  void _handleSave() {
    if (formKey.currentState!.validate()) {
      _submit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompactLayout = TypeDeviceUtils.isCompact(context);

    return Form(
      key: formKey,
      child: isCompactLayout
          ? BottomSheetLayout(
              buildFormFields: (context) => _buildFormFields(context),
              handleSave: _handleSave,
              isEditing: _isEditing,
            )
          : DialogLayout(
              isEditing: _isEditing,
              onSave: _handleSave,
              buildFormFields: (context) => _buildFormFields(context),
            ),
    );
  }

  Widget _buildFormFields(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(labelText: 'Activity'),
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Activity title is required.';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _hourController,
                decoration: const InputDecoration(labelText: 'Hours'),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null;
                  }
                  final hours = int.tryParse(value);
                  if (hours == null || hours < 0 || hours > 23) {
                    return 'Hours must be between 0 and 23.';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _minuteController,
                decoration: const InputDecoration(labelText: 'Minutes'),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null;
                  }
                  final minutes = int.tryParse(value);
                  if (minutes == null || minutes < 0 || minutes > 59) {
                    return 'Minutes must be between 0 and 59.';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ColorPickerWidget(
          selectedColorValue: _selectedColorValue,
          onColorChanged: (newColorValue) {
            setState(() {
              _selectedColorValue = newColorValue;
            });
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<TaskScheduleType>(
          initialValue: _scheduleType,
          decoration: const InputDecoration(labelText: 'Schedule'),
          items: const [
            DropdownMenuItem(
              value: TaskScheduleType.today,
              child: Text('Today'),
            ),
            DropdownMenuItem(
              value: TaskScheduleType.daily,
              child: Text('Every Day'),
            ),
            DropdownMenuItem(
              value: TaskScheduleType.customDays,
              child: Text('Custom Days'),
            ),
          ],
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() {
              _scheduleType = value;
            });
          },
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _scheduleType == TaskScheduleType.customDays
              ? DayPickerWidget(
                  selectedDays: _selectedDays,
                  onSelectedDaysChanged: (newSelectedDays) {
                    setState(() {
                      _selectedDays
                        ..clear()
                        ..addAll(newSelectedDays);
                    });
                  },
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
