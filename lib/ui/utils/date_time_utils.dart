import 'package:intl/intl.dart';

class AppDateUtils {
  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime startOfDay(DateTime date) {
    return dateOnly(date);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }
}

class TimeFormatUtils {
  static String formatSeconds(int seconds) {
    if (seconds < 0) {
      return '-${formatSeconds(-seconds)}';
    }
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    final hourPart = hours > 0 ? '${hours}j ' : '';
    final minutePart = minutes > 0 || hours > 0 ? '${minutes}m ' : '';
    final secPart = '${secs}s';
    return '$hourPart$minutePart$secPart';
  }

  static String formatClock(int seconds) {
    final isNegative = seconds < 0;
    final totalSeconds = seconds.abs();
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final secs = totalSeconds % 60;

    final clock = hours > 0
        ? '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}'
        : '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return isNegative ? '-$clock' : clock;
  }

  static String formatClockHms(int seconds) {
    final isNegative = seconds < 0;
    final totalSeconds = seconds.abs();
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final secs = totalSeconds % 60;

    final clock =
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return isNegative ? '-$clock' : clock;
  }

  static String formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours == 0) {
      return '${mins}m';
    }
    return '${hours}j ${mins}m';
  }

  static String formatTodayHeader(DateTime day) {
    return DateFormat('EEEE, d MMMM y').format(day);
  }

  static String formatTime12h(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }
}