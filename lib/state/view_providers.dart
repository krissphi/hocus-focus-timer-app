import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/model/session.dart';
import '../data/model/task.dart';
import '../ui/utils/date_time_utils.dart';
import '../ui/utils/history_utils.dart';
import '../ui/utils/task_schedule_utils.dart';
import 'entity_providers.dart';

final appIsLoadingProvider = Provider<bool>((ref) {
  final taskState = ref.watch(taskNotifierProvider);
  final sessionState = ref.watch(sessionNotifierProvider);
  final segmentState = ref.watch(segmentNotifierProvider);

  return taskState.isLoading ||
      sessionState.isLoading ||
      segmentState.isLoading;
});

final tasksForDayProvider = Provider.family<List<Task>, DateTime>((ref, day) {
  final tasks = ref.watch(taskNotifierProvider).items;
  final sessions = ref.watch(sessionNotifierProvider).items;

  final scheduledTasks =
      tasks
          .where(
            (task) => TaskScheduleUtils.isScheduledForDate(
              task,
              day,
              sessions: sessions,
            ),
          )
          .toList()
        ..sort((a, b) => a.title.compareTo(b.title));

  return scheduledTasks;
});

final homeDailyStatsProvider = Provider.family<HomeDailyStats, DateTime>((
  ref,
  day,
) {
  final tasksForDay = ref.watch(tasksForDayProvider(day));
  final sessions = ref.watch(sessionNotifierProvider).items;
  final segments = ref.watch(segmentNotifierProvider).items;

  final taskIdsForDay = tasksForDay.map((task) => task.id).toSet();
  final sessionIdsForDay = sessions
      .where((session) => taskIdsForDay.contains(session.taskId))
      .map((session) => session.id)
      .toSet();

  final totalFocusSeconds = segments
      .where(
        (segment) =>
            sessionIdsForDay.contains(segment.sessionId) &&
            AppDateUtils.isSameDay(segment.startTime, day),
      )
      .fold<int>(0, (total, segment) => total + segment.durationInSeconds);

  final completedTaskCount = tasksForDay
      .where(
        (task) => TaskScheduleUtils.isCompletedForDate(task.id, day, sessions),
      )
      .length;

  return HomeDailyStats(
    totalFocusSeconds: totalFocusSeconds,
    completedTaskCount: completedTaskCount,
    remainingTaskCount: tasksForDay.length - completedTaskCount,
  );
});

final taskListDataProvider = Provider.family<TaskListData, DateTime>((
  ref,
  day,
) {
  final tasksForDay = ref.watch(tasksForDayProvider(day));
  final sessions = ref.watch(sessionNotifierProvider).items;
  final segments = ref.watch(segmentNotifierProvider).items;

  final completedByTaskId = <String, bool>{
    for (final task in tasksForDay)
      task.id: TaskScheduleUtils.isCompletedForDate(task.id, day, sessions),
  };

  final activeSessionIdByTaskId = <String, String>{
    for (final session in sessions)
      if (session.endAt == null && AppDateUtils.isSameDay(session.startAt, day))
        session.taskId: session.id,
  };

  final activeSegmentSessionIds = {
    for (final segment in segments)
      if (segment.endTime == null) segment.sessionId,
  };

  final sessionTaskIdBySessionId = <String, String>{
    for (final session in sessions) session.id: session.taskId,
  };

  final baseElapsedByTaskId = <String, int>{
    for (final task in tasksForDay) task.id: 0,
  };

  final activeSegmentStartsByTaskId = <String, List<DateTime>>{
    for (final task in tasksForDay) task.id: <DateTime>[],
  };

  for (final segment in segments) {
    if (!AppDateUtils.isSameDay(segment.startTime, day)) {
      continue;
    }

    final taskId = sessionTaskIdBySessionId[segment.sessionId];
    if (taskId == null || !baseElapsedByTaskId.containsKey(taskId)) {
      continue;
    }

    if (segment.endTime == null) {
      activeSegmentStartsByTaskId[taskId]!.add(segment.startTime);
      continue;
    }

    baseElapsedByTaskId[taskId] =
        (baseElapsedByTaskId[taskId] ?? 0) + segment.durationInSeconds;
  }

  final activeTasks = <Task>[];
  final completedTasks = <Task>[];
  for (final task in tasksForDay) {
    if (completedByTaskId[task.id] ?? false) {
      completedTasks.add(task);
    } else {
      activeTasks.add(task);
    }
  }

  final hasRunningSegment = activeSegmentStartsByTaskId.values.any(
    (starts) => starts.isNotEmpty,
  );

  return TaskListData(
    activeTasks: activeTasks,
    completedTasks: completedTasks,
    completedByTaskId: completedByTaskId,
    activeSessionIdByTaskId: activeSessionIdByTaskId,
    activeSegmentSessionIds: activeSegmentSessionIds,
    baseElapsedByTaskId: baseElapsedByTaskId,
    activeSegmentStartsByTaskId: activeSegmentStartsByTaskId,
    hasRunningSegment: hasRunningSegment,
  );
});

final historyPageDataProvider = Provider.family<HistoryPageData, HistoryFilter>(
  (ref, filter) {
    final tasks = ref.watch(taskNotifierProvider).items;
    final sessions = ref.watch(sessionNotifierProvider).items;
    final segments = ref.watch(segmentNotifierProvider).items;

    final tasksById = {for (final task in tasks) task.id: task};
    final endedSessions =
        sessions.where((session) => session.endAt != null).toList()
          ..sort((a, b) => b.startAt.compareTo(a.startAt));

    final now = DateTime.now();
    final filteredSessions = HistoryUtils.applyFilter(
      endedSessions,
      now: now,
      filter: filter,
    );

    final segmentSecondsBySessionId = HistoryUtils.segmentSecondsBySessionId(
      segments,
    );

    final weekStart = HistoryUtils.startOfWeek(now);
    final weekRangeLabel = HistoryUtils.weekRangeLabel(weekStart);

    final weekSecondsByDay = List<int>.filled(7, 0);
    for (final segment in segments) {
      if (!HistoryUtils.isInSameWeek(segment.startTime, weekStart)) {
        continue;
      }
      final dayIndex = segment.startTime.weekday - DateTime.monday;
      weekSecondsByDay[dayIndex] += segment.durationInSeconds;
    }

    final totalWeekSeconds = weekSecondsByDay.fold<int>(0, (sum, v) => sum + v);

    final groupedSessions = <DateTime, List<Session>>{};
    for (final session in filteredSessions) {
      final endAt = session.endAt;
      if (endAt == null) {
        continue;
      }
      final dateKey = DateTime(endAt.year, endAt.month, endAt.day);
      groupedSessions.putIfAbsent(dateKey, () => []).add(session);
    }

    final orderedDates = groupedSessions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return HistoryPageData(
      now: now,
      tasksById: tasksById,
      segmentSecondsBySessionId: segmentSecondsBySessionId,
      weekRangeLabel: weekRangeLabel,
      weekSecondsByDay: weekSecondsByDay,
      totalWeekHours: totalWeekSeconds / 3600,
      groupedSessions: groupedSessions,
      orderedDates: orderedDates,
    );
  },
);

class HomeDailyStats {
  const HomeDailyStats({
    required this.totalFocusSeconds,
    required this.completedTaskCount,
    required this.remainingTaskCount,
  });

  final int totalFocusSeconds;
  final int completedTaskCount;
  final int remainingTaskCount;
}

class TaskListData {
  const TaskListData({
    required this.activeTasks,
    required this.completedTasks,
    required this.completedByTaskId,
    required this.activeSessionIdByTaskId,
    required this.activeSegmentSessionIds,
    required this.baseElapsedByTaskId,
    required this.activeSegmentStartsByTaskId,
    required this.hasRunningSegment,
  });

  final List<Task> activeTasks;
  final List<Task> completedTasks;
  final Map<String, bool> completedByTaskId;
  final Map<String, String> activeSessionIdByTaskId;
  final Set<String> activeSegmentSessionIds;
  final Map<String, int> baseElapsedByTaskId;
  final Map<String, List<DateTime>> activeSegmentStartsByTaskId;
  final bool hasRunningSegment;
}

class HistoryPageData {
  const HistoryPageData({
    required this.now,
    required this.tasksById,
    required this.segmentSecondsBySessionId,
    required this.weekRangeLabel,
    required this.weekSecondsByDay,
    required this.totalWeekHours,
    required this.groupedSessions,
    required this.orderedDates,
  });

  final DateTime now;
  final Map<String, Task> tasksById;
  final Map<String, int> segmentSecondsBySessionId;
  final String weekRangeLabel;
  final List<int> weekSecondsByDay;
  final double totalWeekHours;
  final Map<DateTime, List<Session>> groupedSessions;
  final List<DateTime> orderedDates;
}
