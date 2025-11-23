/// Configuration for obtaining a weather model. In [isManual] mode the manual temperature is
/// used. Otherwise, [location] and [forecastTime] are used for API weather calls. Empty
/// [location] is meant for automatically obtaining the current location. Empty [forecastTime]
/// is meant for obtaining the current weather.
class ForecastConfig {
  bool isManual;
  String location;
  DateTime? forecastTime;
  int? manualTemperature;
  // TODO: day as an offset so on day 7th, picking 8th 9:00 would later on 18th show as 19th 9:00

  ForecastConfig({
    this.isManual = false,
    this.location = '',
    this.forecastTime,
    this.manualTemperature,
  });

  Map<String, dynamic> toJson() => {
    'isManual': isManual,
    'location': location,
    'manualTemperature': manualTemperature,
  };

  factory ForecastConfig.fromJson(Map<String, dynamic> json) {
    return ForecastConfig(
      isManual: json['isManual'] ?? false,
      location: json['location'] ?? '',
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

    final timeText = forecastTime?.toIso8601String() ?? 'Now';
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
      return location == other.location && forecastTime == other.forecastTime;
    }

    // Different modes
    return false;
  }

  @override
  int get hashCode {
    if (isManual) {
      return manualTemperature.hashCode;
    } else {
      return Object.hash(location, forecastTime);
    }
  }
}
