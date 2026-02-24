import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hocusfocus/ui/utils/date_time_utils.dart';
import 'package:uuid/uuid.dart';

import '../data/model/session.dart';
import '../data/model/time_segment.dart';
import 'entity_providers.dart';

final taskTimerControllerProvider = Provider<TaskTimerController>((ref) {
  return TaskTimerController(ref);
});

class TaskTimerController {
  TaskTimerController(this._ref);

  final Ref _ref;
  DateTime? _lastNormalizedDay;

  List<Session> get _sessions => _ref.read(sessionNotifierProvider).items;
  List<TimeSegment> get _segments => _ref.read(segmentNotifierProvider).items;

  SessionNotifier get _sessionNotifier =>
      _ref.read(sessionNotifierProvider.notifier);
  SegmentNotifier get _segmentNotifier =>
      _ref.read(segmentNotifierProvider.notifier);

  final Uuid _uuid = const Uuid();

  _TaskTimerQuery _query() => _TaskTimerQuery(_sessions, _segments);
  _TaskTimerMutator _mutator() =>
      _TaskTimerMutator(_sessionNotifier, _segmentNotifier);

  ({String title, int colorValue})? _getTaskInfo(String taskId) {
    try {
      final task = _ref
          .read(taskNotifierProvider)
          .items
          .firstWhere((t) => t.id == taskId);
      return (title: task.title, colorValue: task.colorValue);
    } catch (_) {
      return null;
    }
  }

  void ensureNormalized({DateTime? now}) {
    final current = now ?? DateTime.now();
    _normalizeDay(current);
    _enforceSingleRunningSegment(current);
  }

  void startTask(String taskId) {
    final now = DateTime.now();
    ensureNormalized(now: now);
    _pauseOtherRunning(taskId, now);

    final existingSession = _query().activeSession(taskId: taskId, day: now);
    if (existingSession != null) {
      _startSegmentIfMissing(existingSession.id, now);
      return;
    }

    _createSessionWithSegment(taskId, now);
  }

  void pauseTask(String taskId) {
    final now = DateTime.now();
    ensureNormalized(now: now);
    final session = _query().activeSession(taskId: taskId, day: now);
    if (session == null) {
      return;
    }
    _closeSegmentIfAny(session.id, now);
  }

  void resumeTask(String taskId) {
    final now = DateTime.now();
    ensureNormalized(now: now);
    _pauseOtherRunning(taskId, now);

    final session = _query().activeSession(taskId: taskId, day: now);
    if (session == null) {
      _createSessionWithSegment(taskId, now);
      return;
    }
    _startSegmentIfMissing(session.id, now);
  }

  void stopTask(String taskId) {
    final now = DateTime.now();
    ensureNormalized(now: now);
    final activeSession = _query().activeSession(taskId: taskId, day: now);
    if (activeSession == null) {
      return;
    }
    _stopSession(activeSession, now);
  }

  void completeTask(String taskId) {
    final now = DateTime.now();
    ensureNormalized(now: now);
    final activeSession = _query().activeSession(taskId: taskId, day: now);
    if (activeSession != null) {
      _stopSession(activeSession, now);
      return;
    }

    if (_isTaskCompletedToday(taskId, now)) {
      return;
    }

    final taskInfo = _getTaskInfo(taskId);
    if (taskInfo == null) {
      return;
    }

    final session = Session(
      id: _newId(),
      taskId: taskId,
      taskTitle: taskInfo.title,
      taskColorValue: taskInfo.colorValue,
      startAt: now,
      endAt: now,
    );
    _mutator().upsertSession(session);
  }

  void clearCompletion(String taskId, DateTime date) {
    final now = DateTime.now();
    ensureNormalized(now: now);
    final sessionsToRemove = _query().sessionsForTaskOnDay(
      taskId: taskId,
      day: date,
    );
    if (sessionsToRemove.isEmpty) {
      return;
    }

    final sessionIds = sessionsToRemove.map((session) => session.id).toList();
    _mutator().removeSessionsByIds(sessionIds);
    _mutator().removeSegmentsBySessionIds(sessionIds);
  }

  void _stopSession(Session session, DateTime now) {
    _closeSegmentIfAny(session.id, now);
    _mutator().upsertSession(_withEndAt(session, now));
  }

  String _newId() => _uuid.v4();

  DateTime _startOfDay(DateTime date) {
    return AppDateUtils.startOfDay(date);
  }

  bool _isAlreadyNormalized(DateTime now) {
    return _lastNormalizedDay != null &&
        AppDateUtils.isSameDay(_lastNormalizedDay!, now);
  }

  void _normalizeDay(DateTime now) {
    final dayStart = _startOfDay(now);
    if (_isAlreadyNormalized(now)) {
      return;
    }

    final staleSessions = _query().staleSessions(dayStart);
    for (final session in staleSessions) {
      _closeStaleSession(session, dayStart, now);
    }

    _lastNormalizedDay = dayStart;
  }

  void _closeStaleSession(Session session, DateTime dayStart, DateTime now) {
    final activeSegment = _query().activeSegment(session.id);
    final hadActive = activeSegment != null;
    if (activeSegment != null) {
      _mutator().upsertSegment(_withSegmentEnd(activeSegment, dayStart));
    }

    final endAt = _resolveSessionEnd(
      session,
      dayStart,
      activeSegment,
      _query(),
    );
    _mutator().upsertSession(_withEndAt(session, endAt));

    if (hadActive &&
        _query().activeSession(taskId: session.taskId, day: now) == null) {
      _createSessionWithSegment(session.taskId, dayStart);
    }
  }

  DateTime _resolveSessionEnd(
    Session session,
    DateTime dayStart,
    TimeSegment? activeSegment,
    _TaskTimerQuery query,
  ) {
    final lastEnd = query.latestSegmentEnd(session.id) ?? session.startAt;
    final clampedEnd = lastEnd.isAfter(dayStart) ? dayStart : lastEnd;
    return activeSegment == null ? clampedEnd : dayStart;
  }

  void _pauseOtherRunning(String taskId, DateTime now) {
    final query = _query();
    final activeSegments = query.activeSegments;
    if (activeSegments.isEmpty) {
      return;
    }

    for (final segment in activeSegments) {
      final session = query.sessionById[segment.sessionId];
      if (session == null || session.taskId == taskId) {
        continue;
      }
      _closeSegmentIfAny(session.id, now);
    }
  }

  void _startSegmentIfMissing(String sessionId, DateTime now) {
    if (_query().activeSegment(sessionId) == null) {
      _mutator().upsertSegment(_newSegment(sessionId, now));
    }
  }

  void _createSessionWithSegment(String taskId, DateTime now) {
    final taskInfo = _getTaskInfo(taskId);
    if (taskInfo == null) {
      return; // Task not found
    }

    final session = Session(
      id: _newId(),
      taskId: taskId,
      taskTitle: taskInfo.title,
      taskColorValue: taskInfo.colorValue,
      startAt: now,
      endAt: null,
    );
    _mutator().upsertSession(session);
    _mutator().upsertSegment(_newSegment(session.id, now));
  }

  void _closeSegmentIfAny(String sessionId, DateTime endTime) {
    final active = _query().activeSegment(sessionId);
    if (active != null) {
      _mutator().upsertSegment(_withSegmentEnd(active, endTime));
    }
  }

  bool _isTaskCompletedToday(String taskId, DateTime day) {
    return _query().isTaskCompletedToday(taskId: taskId, day: day);
  }

  void _enforceSingleRunningSegment(DateTime now) {
    final query = _query();
    final activeSegments = query.activeSegments;
    if (activeSegments.length <= 1) {
      return;
    }

    activeSegments.sort((a, b) => a.startTime.compareTo(b.startTime));
    final keep = activeSegments.last;
    for (final segment in activeSegments) {
      if (segment.id == keep.id) {
        continue;
      }
      _mutator().upsertSegment(_withSegmentEnd(segment, now));
    }
  }

  Session _withEndAt(Session session, DateTime endAt) {
    return Session(
      id: session.id,
      taskId: session.taskId,
      taskTitle: session.taskTitle,
      taskColorValue: session.taskColorValue,
      startAt: session.startAt,
      endAt: endAt,
    );
  }

  TimeSegment _newSegment(String sessionId, DateTime startTime) {
    return TimeSegment(
      id: _newId(),
      sessionId: sessionId,
      startTime: startTime,
      endTime: null,
    );
  }

  TimeSegment _withSegmentEnd(TimeSegment segment, DateTime endTime) {
    return TimeSegment(
      id: segment.id,
      sessionId: segment.sessionId,
      startTime: segment.startTime,
      endTime: endTime,
    );
  }
}

class _TaskTimerMutator {
  _TaskTimerMutator(this._sessionNotifier, this._segmentNotifier);

  final SessionNotifier _sessionNotifier;
  final SegmentNotifier _segmentNotifier;

  void upsertSession(Session session) => _sessionNotifier.upsert(session);

  void upsertSegment(TimeSegment segment) => _segmentNotifier.upsert(segment);

  void removeSessionsByIds(Iterable<String> ids) =>
      _sessionNotifier.removeByIds(ids);

  void removeSegmentsBySessionIds(Iterable<String> sessionIds) =>
      _segmentNotifier.removeBySessionIds(sessionIds);
}

class _TaskTimerQuery {
  _TaskTimerQuery(this.sessions, this.segments) {
    for (final session in sessions) {
      sessionById[session.id] = session;
      sessionsByTaskId.putIfAbsent(session.taskId, () => []).add(session);
    }

    for (final segment in segments) {
      segmentsBySessionId.putIfAbsent(segment.sessionId, () => []).add(segment);
      if (segment.isActive) {
        activeSegments.add(segment);
        activeSegmentBySessionId[segment.sessionId] = segment;
      }
    }
  }

  final List<Session> sessions;
  final List<TimeSegment> segments;
  final Map<String, Session> sessionById = {};
  final Map<String, List<Session>> sessionsByTaskId = {};
  final Map<String, List<TimeSegment>> segmentsBySessionId = {};
  final Map<String, TimeSegment> activeSegmentBySessionId = {};
  final List<TimeSegment> activeSegments = [];

  Session? activeSession({String? taskId, DateTime? day}) {
    final candidates = taskId == null
        ? sessions
        : (sessionsByTaskId[taskId] ?? const <Session>[]);
    for (final session in candidates) {
      final matchesDay =
          day == null || AppDateUtils.isSameDay(session.startAt, day);
      if (session.isActive && matchesDay) {
        return session;
      }
    }
    return null;
  }

  TimeSegment? activeSegment(String sessionId) {
    return activeSegmentBySessionId[sessionId];
  }

  DateTime? latestSegmentEnd(String sessionId) {
    final segments = segmentsBySessionId[sessionId];
    if (segments == null || segments.isEmpty) {
      return null;
    }
    DateTime? lastEnd;
    for (final segment in segments) {
      final endTime = segment.endTime;
      if (endTime == null) {
        continue;
      }
      if (lastEnd == null || endTime.isAfter(lastEnd)) {
        lastEnd = endTime;
      }
    }
    return lastEnd;
  }

  List<Session> sessionsForTaskOnDay({
    required String taskId,
    required DateTime day,
  }) {
    return (sessionsByTaskId[taskId] ?? const <Session>[])
        .where((session) => AppDateUtils.isSameDay(session.startAt, day))
        .toList();
  }

  Iterable<Session> staleSessions(DateTime dayStart) {
    return sessions.where(
      (session) => session.isActive && session.startAt.isBefore(dayStart),
    );
  }

  bool isTaskCompletedToday({required String taskId, required DateTime day}) {
    return (sessionsByTaskId[taskId] ?? const <Session>[]).any(
      (session) =>
          session.endAt != null && AppDateUtils.isSameDay(session.startAt, day),
    );
  }
}
