// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_adapters.dart';

// **************************************************************************
// AdaptersGenerator
// **************************************************************************

class TimeSegmentAdapter extends TypeAdapter<TimeSegment> {
  @override
  final typeId = 1;

  @override
  TimeSegment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimeSegment(
      id: fields[0] as String,
      sessionId: fields[1] as String,
      startTime: fields[2] as DateTime,
      endTime: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TimeSegment obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.sessionId)
      ..writeByte(2)
      ..write(obj.startTime)
      ..writeByte(3)
      ..write(obj.endTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeSegmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final typeId = 2;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Task(
      id: fields[0] as String,
      title: fields[1] as String,
      targetDurationMinutes: (fields[2] as num).toInt(),
      colorValue: (fields[3] as num).toInt(),
      scheduleType: fields[4] as TaskScheduleType,
      customDays: fields[5] == null
          ? const []
          : (fields[5] as List).cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.targetDurationMinutes)
      ..writeByte(3)
      ..write(obj.colorValue)
      ..writeByte(4)
      ..write(obj.scheduleType)
      ..writeByte(5)
      ..write(obj.customDays);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskScheduleTypeAdapter extends TypeAdapter<TaskScheduleType> {
  @override
  final typeId = 4;

  @override
  TaskScheduleType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskScheduleType.daily;
      case 2:
        return TaskScheduleType.customDays;
      case 3:
        return TaskScheduleType.today;
      default:
        return TaskScheduleType.daily;
    }
  }

  @override
  void write(BinaryWriter writer, TaskScheduleType obj) {
    switch (obj) {
      case TaskScheduleType.daily:
        writer.writeByte(0);
      case TaskScheduleType.customDays:
        writer.writeByte(2);
      case TaskScheduleType.today:
        writer.writeByte(3);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskScheduleTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SessionAdapter extends TypeAdapter<Session> {
  @override
  final typeId = 5;

  @override
  Session read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Session(
      id: fields[0] as String,
      taskId: fields[1] as String,
      taskTitle: fields[4] as String,
      taskColorValue: (fields[5] as num).toInt(),
      startAt: fields[2] as DateTime,
      endAt: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Session obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.taskId)
      ..writeByte(2)
      ..write(obj.startAt)
      ..writeByte(3)
      ..write(obj.endAt)
      ..writeByte(4)
      ..write(obj.taskTitle)
      ..writeByte(5)
      ..write(obj.taskColorValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
