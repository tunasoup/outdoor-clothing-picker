class PrefKeys {
  static const String activity = 'clothing_selected_activity';
  static const String darkMode = 'settings_dark_mode_bool';
  static const String apiKeyOWM = 'weather_api_key_owm';
  static const String apiWeather = 'weather_api_weather';
  static const String manualTemp = 'weather_manual_temperature';
}

extension DateTimeExtensions on DateTime {
  String get shortMonth {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}

enum TimeFormat { t24, t12 }

/// Format [time] to a given [timeFormat], and optionally with [showConditionalDay] show the
/// date if it differs from today.
String formatTime({
  required DateTime time,
  TimeFormat timeFormat = TimeFormat.t24,
  bool showConditionalDay = false,
}) {
  String? formatted;
  String minute = time.minute.toString().padLeft(2, '0');
  switch (timeFormat) {
    case TimeFormat.t12:
      int hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
      String period = time.hour >= 12 ? 'PM' : 'AM';
      formatted = '$hour:$minute $period';
    case TimeFormat.t24:
      formatted = '${time.hour.toString()}:$minute';
  }
  if (showConditionalDay && !isToday(time)) {
    formatted = '${time.day.toString().padLeft(2, '0')}/${time.shortMonth} $formatted';
  }
  return formatted;
}

bool isToday(DateTime date) {
  final today = DateTime.now();
  return date.year == today.year && date.month == today.month && date.day == today.day;
}
