import 'package:flutter/material.dart';
import 'package:hocusfocus/data/model/session.dart';
import 'package:hocusfocus/data/model/task.dart';
import 'package:hocusfocus/ui/utils/date_time_utils.dart';

class HistoryItemCard extends StatelessWidget {
  const HistoryItemCard({
    super.key,
    required this.session,
    required this.task,
    required this.focusSeconds,
  });

  final Session session;
  final Task? task;
  final int focusSeconds;

  @override
  Widget build(BuildContext context) {
    final title = task?.title ?? session.taskTitle;
    final startLabel = TimeFormatUtils.formatTime12h(session.startAt);
    final endLabel = TimeFormatUtils.formatTime12h(session.endAt!);
    final accentColor = Color(task?.colorValue ?? session.taskColorValue);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: Colors.white.withAlpha(225)),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$startLabel — $endLabel',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            TimeFormatUtils.formatMinutes((focusSeconds / 60).round()),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.check_circle,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
