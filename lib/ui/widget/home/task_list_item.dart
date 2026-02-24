import 'package:flutter/material.dart';

import '../../../data/model/task.dart';
import '../../utils/date_time_utils.dart';

class TaskListItem extends StatelessWidget {
  const TaskListItem({
    super.key,
    this.isDesktop,
    required this.task,
    required this.isRunning,
    required this.isPaused,
    required this.isCompleted,
    required this.elapsedSeconds,
    required this.remainingSeconds,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.onDelete,
    required this.onEdit,
    required this.onReset,
  });

  final Task task;
  final bool isRunning;
  final bool isPaused;
  final bool isCompleted;
  final int elapsedSeconds;
  final int remainingSeconds;
  final void Function(String) onStart;
  final void Function(String) onPause;
  final void Function(String) onResume;
  final void Function(String) onStop;
  final void Function(String) onDelete;
  final void Function(Task) onEdit;
  final void Function(String) onReset;
  final bool? isDesktop;

  Future<void> _confirmAndDelete(BuildContext context) async {
    final theme = Theme.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Task'),
          content: Text(
            'Are you sure you want to permanently delete "${task.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      onDelete(task.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Color(task.colorValue);
    final hasTarget = task.targetDurationMinutes > 0;
    final targetSeconds = task.targetDurationMinutes * 60;
    final isOvertime = hasTarget && remainingSeconds < 0;
    final progressRatio = hasTarget && targetSeconds > 0
        ? elapsedSeconds / targetSeconds
        : 0.0;
    final progressPercent = progressRatio * 100;
    final progressLabel = hasTarget
        ? '${progressPercent.toStringAsFixed(0)}%'
        : null;
    final timerLabel = isCompleted
        ? 'Total ${TimeFormatUtils.formatClockHms(elapsedSeconds)}'
        : hasTarget
        ? isOvertime
              ? '+ ${TimeFormatUtils.formatClockHms(remainingSeconds.abs())}'
              : '${TimeFormatUtils.formatClock(remainingSeconds)} remaining'
        : 'Durasi ${TimeFormatUtils.formatClock(elapsedSeconds)}';

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      tween: Tween<double>(begin: 0.96, end: 1),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(color: accentColor),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                      child: Row(
                        children: [
                          IconButton.filled(
                            onPressed: isCompleted
                                ? null
                                : isRunning
                                ? () => onPause(task.id)
                                : isPaused
                                ? () => onResume(task.id)
                                : () => onStart(task.id),
                            icon: Icon(
                              isRunning
                                  ? Icons.pause
                                  : isPaused
                                  ? Icons.play_arrow
                                  : Icons.play_arrow,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  task.title,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      timerLabel,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: isRunning
                                                ? isOvertime
                                                      ? Colors.redAccent
                                                      : Colors.green
                                                : Colors.black87,
                                          ),
                                    ),
                                    if (progressLabel != null) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '•',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black45,
                                            ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        progressLabel,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: isRunning
                                                  ? isOvertime
                                                        ? Colors.redAccent
                                                        : Colors.green
                                                  : Colors.black87,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),

                          if (isDesktop == true) ...[
                            IconButton(
                              onPressed: () => onEdit(task),
                              icon: const Icon(Icons.edit, size: 18),
                            ),
                            IconButton(
                              onPressed: isCompleted
                                  ? null
                                  : () => onStop(task.id),
                              icon: const Icon(
                                Icons.check_circle_outline,
                                size: 18,
                              ),
                            ),
                            IconButton(
                              onPressed: () => onReset(task.id),
                              icon: const Icon(Icons.refresh, size: 18),
                            ),
                            IconButton(
                              onPressed: () => _confirmAndDelete(context),
                              icon: const Icon(Icons.delete, size: 18),
                            ),
                          ],
                          if (isDesktop == false) ...[
                            PopupMenuButton<String>(
                              onSelected: (value) async {
                                switch (value) {
                                  case 'edit':
                                    onEdit(task);
                                    break;
                                  case 'stop':
                                    if (!isCompleted) {
                                      onStop(task.id);
                                    }
                                    break;
                                  case 'reset':
                                    onReset(task.id);
                                    break;
                                  case 'delete':
                                    await _confirmAndDelete(context);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                PopupMenuItem(
                                  value: 'stop',
                                  enabled: !isCompleted,
                                  child: const Text('Mark as Completed'),
                                ),
                                const PopupMenuItem(
                                  value: 'reset',
                                  child: Text('Reset Timer'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete Task'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (hasTarget)
              SizedBox(
                height: 2,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final clampedRatio = progressRatio.clamp(0.0, 1.0);
                    return Stack(
                      children: [
                        Container(color: Colors.black12),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          width: constraints.maxWidth * clampedRatio,
                          color: accentColor.withAlpha(153),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
