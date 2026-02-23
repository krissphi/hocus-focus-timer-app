import 'package:hive_ce/hive_ce.dart';

import '../model/time_segment.dart';

class TimeSegmentRepository {
  TimeSegmentRepository(this._box);

  static const String boxName = 'time_segments';

  final Box<TimeSegment> _box;

  List<TimeSegment> getAll() {
    return _box.values.toList();
  }

  Future<void> upsert(TimeSegment segment) {
    return _box.put(segment.id, segment);
  }

  Future<void> upsertAll(Iterable<TimeSegment> segments) async {
    for (final segment in segments) {
      await _box.put(segment.id, segment);
    }
  }

  Future<void> delete(String id) {
    return _box.delete(id);
  }

  Future<void> deleteBySessionId(String sessionId) async {
    final keysToDelete = <dynamic>[];
    for (final entry in _box.toMap().entries) {
      final segment = entry.value;
      if (segment.sessionId == sessionId) {
        keysToDelete.add(entry.key);
      }
    }
    if (keysToDelete.isNotEmpty) {
      await _box.deleteAll(keysToDelete);
    }
  }

  Future<void> deleteBySessionIds(Iterable<String> sessionIds) async {
    final ids = sessionIds.toSet();
    if (ids.isEmpty) {
      return;
    }
    final keysToDelete = <dynamic>[];
    for (final entry in _box.toMap().entries) {
      final segment = entry.value;
      if (ids.contains(segment.sessionId)) {
        keysToDelete.add(entry.key);
      }
    }
    if (keysToDelete.isNotEmpty) {
      await _box.deleteAll(keysToDelete);
    }
  }
}
