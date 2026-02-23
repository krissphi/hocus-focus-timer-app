import 'package:flutter/material.dart';
import 'package:timtam/ui/utils/task_schedule_utils.dart';

class DayPickerWidget extends StatelessWidget {
  final Set<int> selectedDays;
  final Function(Set<int>) onSelectedDaysChanged;

  const DayPickerWidget({
    super.key,
    required this.selectedDays,
    required this.onSelectedDaysChanged,
  });

  @override
  Widget build(BuildContext context) {
    final labels = TaskScheduleUtils.dayLabels;

    return Column(
      key: const ValueKey('day-picker'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choose Days', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: labels.entries.map((entry) {
            final isSelected = selectedDays.contains(entry.key);
            return FilterChip(
              label: Text(entry.value),
              selected: isSelected,
              onSelected: (value) {
                final newSelectedDays = Set<int>.from(selectedDays);
                if (value) {
                  newSelectedDays.add(entry.key);
                } else {
                  newSelectedDays.remove(entry.key);
                }
                onSelectedDaysChanged(newSelectedDays);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
