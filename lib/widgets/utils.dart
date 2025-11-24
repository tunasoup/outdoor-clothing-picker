import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:weather_icons/weather_icons.dart';

/// Wrapper for showing a snackbar of a possible error when running [action].
Future<void> errorWrapper(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
  } catch (e) {
    debugPrint('$e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$e'),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: Duration(seconds: 5),
      ),
    );
  }
}

IconData? iconFromCondition(String? condition) {
  // OWM main conditions
  switch (condition?.toLowerCase()) {
    case 'thunderstorm':
      return WeatherIcons.storm_showers;
    case 'drizzle':
    case 'rain':
      return WeatherIcons.rain_wind;
    case 'snow':
      return WeatherIcons.snow;
    case 'clear':
      return WeatherIcons.day_sunny;
    case 'clouds':
      return WeatherIcons.cloudy;
    case 'fog':
    case 'mist':
      return WeatherIcons.fog;
    case 'tornado':
      return WeatherIcons.tornado;
    case 'haze':
      return WeatherIcons.day_haze;
    case null:
    case '':
      return null;
    default:
      if (kDebugMode) debugPrint('Unknown weather condition: $condition');
      return Icons.error_outline;
  }
}
