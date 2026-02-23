import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/model/session.dart';
import '../data/model/task.dart';
import '../data/model/time_segment.dart';
import '../data/repository/task_repository.dart';
import '../data/repository/task_session_repository.dart';
import '../data/repository/time_segment_repository.dart';

class ListState<T> {
  const ListState({required this.items, required this.isLoading});

  final List<T> items;
  final bool isLoading;

  factory ListState.initial() {
    return ListState(items: const [], isLoading: true);
  }

  ListState<T> copyWith({List<T>? items, bool? isLoading}) {
    return ListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  throw UnimplementedError('TaskRepository must be provided');
});

final taskSessionRepositoryProvider = Provider<TaskSessionRepository>((ref) {
  throw UnimplementedError('TaskSessionRepository must be provided');
});

final timeSegmentRepositoryProvider = Provider<TimeSegmentRepository>((ref) {
  throw UnimplementedError('TimeSegmentRepository must be provided');
});

final taskNotifierProvider =
    StateNotifierProvider<TaskNotifier, ListState<Task>>((ref) {
      final repo = ref.watch(taskRepositoryProvider);
      return TaskNotifier(repo);
    });

final sessionNotifierProvider =
    StateNotifierProvider<SessionNotifier, ListState<Session>>((ref) {
      final repo = ref.watch(taskSessionRepositoryProvider);
      return SessionNotifier(repo);
    });

final segmentNotifierProvider =
    StateNotifierProvider<SegmentNotifier, ListState<TimeSegment>>((ref) {
      final repo = ref.watch(timeSegmentRepositoryProvider);
      return SegmentNotifier(repo);
    });

class TaskNotifier extends StateNotifier<ListState<Task>> {
  TaskNotifier(this._repo) : super(ListState.initial()) {
    _load();
  }

  final TaskRepository _repo;

  void _load() {
    final tasks = _repo.getAll();
    state = state.copyWith(items: tasks, isLoading: false);
  }

  void addTask(Task task) {
    final updated = [...state.items, task];
    state = state.copyWith(items: updated);
    _repo.upsert(task);
  }

  void updateTask(Task draft) {
    final existing = _findTask(draft.id);
    if (existing == null) {
      return;
    }
    final updatedTask = Task(
      id: existing.id,
      title: draft.title,
      targetDurationMinutes: draft.targetDurationMinutes,
      colorValue: draft.colorValue,
      scheduleType: draft.scheduleType,
      customDays: draft.customDays,
    );
    state = state.copyWith(items: _replaceTask(updatedTask));
    _repo.upsert(updatedTask);
  }

  void deleteTask(String id) {
    final updated = state.items.where((task) => task.id != id).toList();
    state = state.copyWith(items: updated);
    _repo.delete(id);
  }

  Task? _findTask(String id) {
    try {
      return state.items.firstWhere((task) => task.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Task> _replaceTask(Task updatedTask) {
    return state.items
        .map((task) => task.id == updatedTask.id ? updatedTask : task)
        .toList();
  }
}

class SessionNotifier extends StateNotifier<ListState<Session>> {
  SessionNotifier(this._repo) : super(ListState.initial()) {
    _load();
  }

  final TaskSessionRepository _repo;

  void _load() {
    final sessions = _repo.getAll();
    state = state.copyWith(items: sessions, isLoading: false);
  }

  void upsert(Session session) {
    final existingIndex = state.items.indexWhere(
      (item) => item.id == session.id,
    );
    final updated = [...state.items];
    if (existingIndex == -1) {
      updated.add(session);
    } else {
      updated[existingIndex] = session;
    }
    state = state.copyWith(items: updated);
    _repo.upsert(session);
  }

  void upsertAll(Iterable<Session> sessions) {
    final updated = [...state.items];
    for (final session in sessions) {
      final index = updated.indexWhere((item) => item.id == session.id);
      if (index == -1) {
        updated.add(session);
      } else {
        updated[index] = session;
      }
    }
    state = state.copyWith(items: updated);
    _repo.upsertAll(sessions);
  }

  void removeByIds(Iterable<String> ids) {
    final idSet = ids.toSet();
    if (idSet.isEmpty) {
      return;
    }
    final updated = state.items
        .where((session) => !idSet.contains(session.id))
        .toList();
    state = state.copyWith(items: updated);
    for (final id in idSet) {
      _repo.delete(id);
    }
  }
}

class SegmentNotifier extends StateNotifier<ListState<TimeSegment>> {
  SegmentNotifier(this._repo) : super(ListState.initial()) {
    _load();
  }

  final TimeSegmentRepository _repo;

  void _load() {
    final segments = _repo.getAll();
    state = state.copyWith(items: segments, isLoading: false);
  }

  void upsert(TimeSegment segment) {
    final existingIndex = state.items.indexWhere(
      (item) => item.id == segment.id,
    );
    final updated = [...state.items];
    if (existingIndex == -1) {
      updated.add(segment);
    } else {
      updated[existingIndex] = segment;
    }
    state = state.copyWith(items: updated);
    _repo.upsert(segment);
  }

  void upsertAll(Iterable<TimeSegment> segments) {
    final updated = [...state.items];
    for (final segment in segments) {
      final index = updated.indexWhere((item) => item.id == segment.id);
      if (index == -1) {
        updated.add(segment);
      } else {
        updated[index] = segment;
      }
    }
    state = state.copyWith(items: updated);
    _repo.upsertAll(segments);
  }

  void removeBySessionIds(Iterable<String> sessionIds) {
    final idSet = sessionIds.toSet();
    if (idSet.isEmpty) {
      return;
    }
    final updated = state.items
        .where((segment) => !idSet.contains(segment.sessionId))
        .toList();
    state = state.copyWith(items: updated);
    _repo.deleteBySessionIds(sessionIds);
  }
}
