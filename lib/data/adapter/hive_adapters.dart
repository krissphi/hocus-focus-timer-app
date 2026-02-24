import 'package:hive_ce/hive_ce.dart';
import 'package:hocusfocus/data/model/session.dart';
import 'package:hocusfocus/data/model/time_segment.dart';

import '../model/task.dart';

@GenerateAdapters([
  AdapterSpec<Task>(),
  AdapterSpec<Session>(),
  AdapterSpec<TimeSegment>(),
  AdapterSpec<TaskScheduleType>(),
])
part 'hive_adapters.g.dart';
