class TimeSegment {
  final String id;
  final String sessionId;
  final DateTime startTime;
  DateTime? endTime;

  TimeSegment({
    required this.id,
    required this.sessionId,
    required this.startTime,
    this.endTime,
  });

  bool get isActive => endTime == null;

  int get durationInSeconds =>
      (endTime ?? DateTime.now()).difference(startTime).inSeconds;
}
