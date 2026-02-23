import 'package:hive_ce/hive.dart';

import '../model/session.dart';

class TaskSessionRepository {
  TaskSessionRepository(this._box);

  static const String boxName = 'task_sessions';

  final Box<Session> _box;

  List<Session> getAll() {
    return _box.values.toList();
  }

  Future<void> upsert(Session session) {
    return _box.put(session.id, session);
  }

  Future<void> upsertAll(Iterable<Session> sessions) async {
    for (final session in sessions) {
      await _box.put(session.id, session);
    }
  }

  Future<void> delete(String id) {
    return _box.delete(id);
  }

  Future<void> deleteByTaskId(String taskId) async {
    final keysToDelete = <dynamic>[];
    for (final entry in _box.toMap().entries) {
      final session = entry.value;
      if (session.taskId == taskId) {
        keysToDelete.add(entry.key);
      }
    }
    if (keysToDelete.isNotEmpty) {
      await _box.deleteAll(keysToDelete);
    }
  }
}
