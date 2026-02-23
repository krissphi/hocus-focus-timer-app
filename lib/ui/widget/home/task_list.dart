import 'package:flutter/material.dart';
import 'package:timtam/ui/widget/empty_list.dart';

import '../../../data/model/task.dart';
import '../../../state/view_providers.dart';
import '../../utils/date_time_utils.dart';
import 'task_list_item.dart';

class TaskList extends StatefulWidget {
  const TaskList({
    super.key,
    required this.data,
    required this.day,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.onDelete,
    required this.onEdit,
    required this.onReset,
    this.onTargetReached,
    this.isDesktop,
  });

  final TaskListData data;
  final DateTime day;
  final void Function(String) onStart;
  final void Function(String) onPause;
  final void Function(String) onResume;
  final void Function(String) onStop;
  final void Function(String) onDelete;
  final void Function(Task) onEdit;
  final void Function(String) onReset;
  final void Function(Task task)? onTargetReached;
  final bool? isDesktop;

  @override
  State<TaskList> createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
  DateTime? _trackedDay;
  final Map<String, bool> _wasAtTargetByTaskId = {};
  final Set<String> _notifiedTaskIds = <String>{};

  void _ensureDayState(DateTime day) {
    if (_trackedDay != null && AppDateUtils.isSameDay(_trackedDay!, day)) {
      return;
    }
    _trackedDay = day;
    _wasAtTargetByTaskId.clear();
    _notifiedTaskIds.clear();
  }

  void _handleTargetProgress({
    required Task task,
    required int elapsedSeconds,
    required DateTime day,
  }) {
    _ensureDayState(day);

    final targetSeconds = task.targetDurationMinutes * 60;
    if (targetSeconds <= 0) {
      _wasAtTargetByTaskId.remove(task.id);
      _notifiedTaskIds.remove(task.id);
      return;
    }

    final reachedTarget = elapsedSeconds >= targetSeconds;
    final previousReached = _wasAtTargetByTaskId[task.id] ?? false;

    if (reachedTarget &&
        !previousReached &&
        !_notifiedTaskIds.contains(task.id)) {
      _notifiedTaskIds.add(task.id);
      if (widget.onTargetReached != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          widget.onTargetReached!(task);
        });
      }
    }

    if (!reachedTarget) {
      _notifiedTaskIds.remove(task.id);
    }

    _wasAtTargetByTaskId[task.id] = reachedTarget;
  }

  @override
  Widget build(BuildContext context) {
    _ensureDayState(widget.day);

    final tasks = [...widget.data.activeTasks, ...widget.data.completedTasks];

    if (tasks.isEmpty) {
      return const EmptyList();
    }

    final hasRunningSegment = widget.data.hasRunningSegment;
    final tickerStream = hasRunningSegment
        ? Stream<int>.periodic(const Duration(seconds: 1), (tick) => tick)
        : Stream<int>.value(0);

    return StreamBuilder<int>(
      stream: tickerStream,
      builder: (context, snapshot) {
        final elapsedByTaskId = _elapsedByTaskIdNow(tasks);

        final items = <_TaskListEntry>[];
        for (final task in widget.data.activeTasks) {
          items.add(_TaskListEntry.task(task));
        }

        if (widget.data.completedTasks.isNotEmpty) {
          items.add(_TaskListEntry.divider());
          for (final task in widget.data.completedTasks) {
            items.add(_TaskListEntry.task(task));
          }
        }

        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (context, index) {
            final entry = items[index];
            if (entry.isDivider) {
              return const SizedBox(height: 12);
            }
            return const SizedBox(height: 8);
          },
          itemBuilder: (context, index) {
            final entry = items[index];
            if (entry.isDivider) {
              return _CompletedHeader();
            }

            final task = entry.task!;
            final isCompleted = widget.data.completedByTaskId[task.id] ?? false;
            final activeSessionId =
                widget.data.activeSessionIdByTaskId[task.id];
            final isRunning =
                activeSessionId != null &&
                widget.data.activeSegmentSessionIds.contains(activeSessionId);
            final isPaused = activeSessionId != null && !isRunning;
            final elapsedSeconds = elapsedByTaskId[task.id] ?? 0;
            final remainingSeconds = _remainingSecondsForTask(
              task,
              elapsedSeconds,
            );

            _handleTargetProgress(
              task: task,
              elapsedSeconds: elapsedSeconds,
              day: widget.day,
            );

            return TaskListItem(
              isDesktop: widget.isDesktop,
              task: task,
              isRunning: isRunning,
              isPaused: isPaused,
              isCompleted: isCompleted,
              elapsedSeconds: elapsedSeconds,
              remainingSeconds: remainingSeconds,
              onStart: widget.onStart,
              onPause: widget.onPause,
              onResume: widget.onResume,
              onStop: widget.onStop,
              onDelete: widget.onDelete,
              onEdit: widget.onEdit,
              onReset: widget.onReset,
            );
          },
        );
      },
    );
  }

  Map<String, int> _elapsedByTaskIdNow(List<Task> tasks) {
    final now = DateTime.now();
    final elapsedByTaskId = <String, int>{
      for (final task in tasks)
        task.id: widget.data.baseElapsedByTaskId[task.id] ?? 0,
    };

    for (final task in tasks) {
      final activeStarts = widget.data.activeSegmentStartsByTaskId[task.id];
      if (activeStarts == null || activeStarts.isEmpty) {
        continue;
      }

      var runningSeconds = 0;
      for (final start in activeStarts) {
        runningSeconds += now.difference(start).inSeconds;
      }
      elapsedByTaskId[task.id] =
          (elapsedByTaskId[task.id] ?? 0) + runningSeconds;
    }

    return elapsedByTaskId;
  }

  int _remainingSecondsForTask(Task task, int elapsedSeconds) {
    final targetSeconds = task.targetDurationMinutes * 60;
    if (targetSeconds <= 0) {
      return 0;
    }
    return targetSeconds - elapsedSeconds;
  }
}

class _TaskListEntry {
  const _TaskListEntry._({this.task, this.isDivider = false});

  final Task? task;
  final bool isDivider;

  factory _TaskListEntry.task(Task task) => _TaskListEntry._(task: task);

  factory _TaskListEntry.divider() => const _TaskListEntry._(isDivider: true);
}

class _CompletedHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: const Color(0xFFE2DDD2), thickness: 1)),
        const SizedBox(width: 12),
        Text(
          'Completed task',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: const Color(0xFF7B7568),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Divider(color: const Color(0xFFE2DDD2), thickness: 1)),
      ],
    );
  }
}
