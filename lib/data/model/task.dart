enum TaskScheduleType {
  daily("Daily"),
  today("One Time"),
  customDays("Scheduled");

  final String label;
  const TaskScheduleType(this.label);
}

class Task {
  final String id;
  final String title;
  final int targetDurationMinutes;
  final int colorValue;
  final TaskScheduleType scheduleType;
  final List<int> customDays;

  Task({
    required this.id,
    required this.title,
    required this.targetDurationMinutes,
    required this.colorValue,
    required this.scheduleType,
    this.customDays = const [],
  });

  bool isDueToday(DateTime date) {
    switch (scheduleType) {
      case TaskScheduleType.daily || TaskScheduleType.today:
        return true;

      case TaskScheduleType.customDays:
        return customDays.contains(date.weekday);
    }
  }
}
