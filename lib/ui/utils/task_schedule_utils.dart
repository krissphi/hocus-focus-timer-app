import '../../data/model/session.dart';
import '../../data/model/task.dart';
import 'date_time_utils.dart';

class TaskScheduleUtils {
  static const Map<int, String> dayLabels = {
    1: 'Mon',
    2: 'Tue',
    3: 'Wed',
    4: 'Thu',
    5: 'Fri',
    6: 'Sat',
    7: 'Sun',
  };

  static bool isScheduledForDate(
    Task task,
    DateTime date, {
    List<Session> sessions = const [],
  }) {
    switch (task.scheduleType) {
      case TaskScheduleType.today:
        return !isCompletedOnce(task.id, sessions);
      case TaskScheduleType.daily:
        return true;
      case TaskScheduleType.customDays:
        return task.customDays.contains(date.weekday);
    }
  }

  static bool isCompletedForDate(
    String taskId,
    DateTime date,
    List<Session> sessions,
  ) {
    return sessions.any(
      (session) =>
          session.taskId == taskId &&
          session.endAt != null &&
          AppDateUtils.isSameDay(session.startAt, date),
    );
  }

  static bool isCompletedOnce(String taskId, List<Session> sessions) {
    return sessions.any(
      (session) => session.taskId == taskId && session.endAt != null,
    );
  }
}
