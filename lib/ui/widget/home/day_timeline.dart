import 'package:flutter/material.dart';

import '../../../data/model/session.dart';
import '../../../data/model/task.dart';
import '../../../data/model/time_segment.dart';
import '../../utils/date_time_utils.dart';

class DayTimeline extends StatelessWidget {
  const DayTimeline({
    super.key,
    required this.tasks,
    required this.sessions,
    required this.segments,
    required this.day,
    required this.isDesktop,
  });

  final List<Task> tasks;
  final List<Session> sessions;
  final List<TimeSegment> segments;
  final DateTime day;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TimeFormatUtils.formatTodayHeader(day),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final timelineSegments = _buildSegments(
              tasks: tasks,
              sessions: sessions,
              timeSegments: segments,
              day: day,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(179),
                    borderRadius: BorderRadius.zero,
                    border: Border.all(color: const Color(0xFFE9E4DA)),
                  ),
                  child: Stack(
                    children: [
                      for (final segment in timelineSegments)
                        Positioned(
                          left: segment.$1 * constraints.maxWidth,
                          width: segment.$2 * constraints.maxWidth,
                          top: 2,
                          bottom: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              color: segment.$3,
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('00:00'),
                    if (isDesktop) Text('03:00'),
                    Text('06:00'),
                    if (isDesktop) Text('09:00'),
                    Text('12:00'),
                    if (isDesktop) Text('15:00'),
                    Text('18:00'),
                    if (isDesktop) Text('21:00'),
                    Text('24:00'),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

List<(double, double, Color)> _buildSegments({
  required List<Task> tasks,
  required List<Session> sessions,
  required List<TimeSegment> timeSegments,
  required DateTime day,
}) {
  final segments = <(double, double, Color)>[];
  const dayMinutes = 1440.0;
  final dayStart = DateTime(day.year, day.month, day.day);
  final dayEnd = dayStart.add(const Duration(days: 1));
  final taskById = {for (final task in tasks) task.id: task};
  final taskIdBySessionId = {
    for (final session in sessions) session.id: session.taskId,
  };

  for (final segment in timeSegments) {
    final taskId = taskIdBySessionId[segment.sessionId];
    final task = taskId == null ? null : taskById[taskId];
    if (task == null) {
      continue;
    }

    final segmentStart = segment.startTime;
    final segmentEnd = segment.endTime ?? DateTime.now();
    if (segmentEnd.isBefore(dayStart) || !segmentStart.isBefore(dayEnd)) {
      continue;
    }

    final clampedStart = segmentStart.isBefore(dayStart)
        ? dayStart
        : segmentStart;
    final clampedEnd = segmentEnd.isAfter(dayEnd) ? dayEnd : segmentEnd;
    final startMinutes = clampedStart.difference(dayStart).inSeconds / 60.0;
    final endMinutes = clampedEnd.difference(dayStart).inSeconds / 60.0;
    if (endMinutes <= startMinutes) {
      continue;
    }

    final left = (startMinutes / dayMinutes).clamp(0.0, 1.0);
    final width = ((endMinutes - startMinutes) / dayMinutes).clamp(0.002, 1.0);
    segments.add((left, width, Color(task.colorValue)));
  }

  segments.sort((a, b) => a.$1.compareTo(b.$1));

  return segments;
}
