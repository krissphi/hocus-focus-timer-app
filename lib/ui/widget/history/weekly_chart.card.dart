import 'package:flutter/material.dart';
import 'package:timtam/ui/utils/task_schedule_utils.dart';

class WeeklyChartCard extends StatelessWidget {
  const WeeklyChartCard({super.key, required this.secondsByDay});

  final List<int> secondsByDay;

  @override
  Widget build(BuildContext context) {
    final labels = TaskScheduleUtils.dayLabels.values.toList(growable: false);
    final maxSeconds = secondsByDay.fold<int>(0, (m, v) => v > m ? v : m);

    return Container(
      height: 190,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(210),
        border: Border.all(color: const Color(0xFFE7E3DB)),
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final seconds = secondsByDay[index];
                final barFactor = maxSeconds == 0
                    ? 0.08
                    : (seconds / maxSeconds).clamp(0.08, 1.0).toDouble();
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        height: 110 * barFactor,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Theme.of(context).colorScheme.primary
                              .withAlpha(seconds == 0 ? 30 : 130),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final label in labels)
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
