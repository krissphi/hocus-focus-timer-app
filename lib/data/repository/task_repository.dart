import 'package:hive_ce/hive.dart';

import '../model/task.dart';

class TaskRepository {
  TaskRepository(this._box);

  static const String boxName = 'tasks';

  final Box<Task> _box;

  List<Task> getAll() {
    return _box.values.toList();
  }

  Future<void> upsert(Task task) {
    return _box.put(task.id, task);
  }

  Future<void> upsertAll(Iterable<Task> tasks) async {
    for (final task in tasks) {
      await _box.put(task.id, task);
    }
  }

  Future<void> delete(String id) {
    return _box.delete(id);
  }
}
