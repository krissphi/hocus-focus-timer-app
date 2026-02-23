class Session {
  final String id;
  final String taskId;
  final String taskTitle;
  final int taskColorValue;
  final DateTime startAt;
  final DateTime? endAt;

  Session({
    required this.id,
    required this.taskId,
    required this.taskTitle,
    required this.taskColorValue,
    required this.startAt,
    this.endAt,
  });

  bool get isActive => endAt == null;
}
