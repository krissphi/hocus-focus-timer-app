import 'package:intl/intl.dart';

import '../../data/model/session.dart';
import '../../data/model/time_segment.dart';
import 'date_time_utils.dart';

enum HistoryFilter { all, today, thisWeek }

class HistoryUtils {
  static Map<String, int> segmentSecondsBySessionId(
    List<TimeSegment> segments,
  ) {
    final map = <String, int>{};
    for (final segment in segments) {
      map[segment.sessionId] =
          (map[segment.sessionId] ?? 0) + segment.durationInSeconds;
    }
    return map;
  }

  static DateTime startOfWeek(DateTime date) {
    final normalized = AppDateUtils.dateOnly(date);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  static String weekRangeLabel(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    return '${DateFormat('MMM d').format(weekStart)} — ${DateFormat('MMM d').format(weekEnd)}';
  }

  static bool isInSameWeek(DateTime date, DateTime weekStart) {
    final normalizedDate = AppDateUtils.dateOnly(date);
    final weekEnd = weekStart.add(const Duration(days: 7));
    return !normalizedDate.isBefore(weekStart) &&
        normalizedDate.isBefore(weekEnd);
  }

  static String dateSectionLabel(DateTime date, DateTime now) {
    final today = AppDateUtils.dateOnly(now);
    final yesterday = today.subtract(const Duration(days: 1));
    if (date == yesterday) {
      return 'YESTERDAY';
    }
    if (date == today) {
      return 'TODAY';
    }
    return DateFormat('MMM d, y').format(date).toUpperCase();
  }

  static List<Session> applyFilter(
    List<Session> sessions, {
    required DateTime now,
    required HistoryFilter filter,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final thisWeekStart = startOfWeek(now);

    switch (filter) {
      case HistoryFilter.all:
        return sessions;
      case HistoryFilter.today:
        return sessions.where((session) {
          final endAt = session.endAt;
          if (endAt == null) {
            return false;
          }
          final date = DateTime(endAt.year, endAt.month, endAt.day);
          return date == today;
        }).toList();
      case HistoryFilter.thisWeek:
        return sessions.where((session) {
          final endAt = session.endAt;
          if (endAt == null) {
            return false;
          }
          return isInSameWeek(endAt, thisWeekStart);
        }).toList();
    }
  }

  static String filterLabel(HistoryFilter filter) {
    switch (filter) {
      case HistoryFilter.all:
        return 'Filter';
      case HistoryFilter.today:
        return 'Today';
      case HistoryFilter.thisWeek:
        return 'This Week';
    }
  }
}
