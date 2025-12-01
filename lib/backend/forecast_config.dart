import 'package:flutter/material.dart';

/// Configuration for obtaining a weather model. In [isManual] mode the manual temperature is
/// used. Otherwise, [location], [time] and [dateOffset] are used for API weather calls. Empty
/// [location] is meant for automatically obtaining the current location. Empty [time] is meant
/// for obtaining the current weather, with optional added [dateOffset].
class ForecastConfig {
  bool isManual;
  String location;
  TimeOfDay? time;
  int dateOffset;
  int? manualTemperature;

  ForecastConfig({
    this.isManual = false,
    this.location = '',
    this.time,
    this.dateOffset = 0,
    this.manualTemperature,
  });

  bool get isForecast => time != null || dateOffset != 0;

  DateTime get dateTime {
    final now = DateTime.now();
    final selectedDate = now.add(Duration(days: dateOffset));

    if (time == null) {
      return now;
    }

    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      time!.hour,
      time!.minute,
    );
  }

  void resetDateTime() {
    dateOffset = 0;
    time = null;
  }

  void setDateTime(DateTime? dt) {
    if (dt == null) {
      resetDateTime();
      return;
    }
    dateOffset = dt.difference(DateTime.now()).inDays;
    time = TimeOfDay(hour: dt.hour, minute: dt.minute);
  }

  Map<String, dynamic> toJson() => {
    'isManual': isManual,
    'location': location,
    'time': timeOfDayToJson(time),
    'dateOffset': dateOffset,
    'manualTemperature': manualTemperature,
  };

  factory ForecastConfig.fromJson(Map<String, dynamic> json) {
    return ForecastConfig(
      isManual: json['isManual'] ?? false,
      location: json['location'] ?? '',
      time: timeOfDayFromJson(json['time']),
      dateOffset: json['dateOffset'] ?? 0,
      manualTemperature: (json['manualTemperature'] != null)
          ? (json['manualTemperature'] as num).toInt()
          : null,
    );
  }

  bool get isEmpty => isManual && manualTemperature == null;

  @override
  String toString() {
    final typeName = runtimeType.toString();
    if (isManual) {
      return '$typeName(Manual: $manualTemperature)';
    }

    final timeText = isForecast ? dateTime.toString() : 'Now';
    return '$typeName(time: $timeText, location: $location)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ForecastConfig) return false;

    // Two manuals with same temperature
    if (isManual && other.isManual) {
      return manualTemperature == other.manualTemperature;
    }

    // Two non-manual with same location and time
    if (!isManual && !other.isManual) {
      return location == other.location && dateTime == other.dateTime;
    }

    // Different modes
    return false;
  }

  @override
  int get hashCode {
    if (isManual) {
      return manualTemperature.hashCode;
    } else {
      return Object.hash(location, dateTime);
    }
  }
}

String? timeOfDayToJson(TimeOfDay? time) {
  if (time == null) return null;
  final hh = time.hour.toString().padLeft(2, '0');
  final mm = time.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

TimeOfDay? timeOfDayFromJson(String? json) {
  if (json == null) return null;
  final parts = json.split(':');
  final hour = int.parse(parts[0]);
  final minute = int.parse(parts[1]);
  return TimeOfDay(hour: hour, minute: minute);
}
