import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:outdoor_clothing_picker/backend/forecast_config.dart';
import 'package:outdoor_clothing_picker/backend/utils.dart';
import 'package:outdoor_clothing_picker/backend/weather_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeatherService {
  WeatherService();

  static const currentUrl = 'https://api.openweathermap.org/data/2.5/weather';
  static const forecastUrl = 'https://api.openweathermap.org/data/2.5/forecast';
  final String units = 'metric';

  Future<List<Weather>> fetchWeathers(List<ForecastConfig> configs) async {
    /*
    With free OWM, specific forecast times cannot be obtained, instead 3 hours intervals
    are obtained, going from 0:00 -> 3:00 -> 6:00, etc., starting from or near the previous
    occurrence up to 40 counts. So to reach this time tomorrow, need to use at least cnt=9,
    and all previous weathers are obtained as well. JSON is different to the current weather,
    city is given in "city" and other info is under list[cnt_ind].
     */
    final hourInterval = 3;
    // TODO: Add another weather API with 1-hour intervals

    // Combine if close enough in time or location to avoid unnecessary API calls
    final now = DateTime.now(); // Assume that each location is at the current local time
    // FIXME: The assumption leads to wrong forecast times if another timezone is used
    for (var e in configs) {
      roundForecastTime(e, now, hourInterval);
    }
    configs = configs.toSet().toList(); // Remove rounded duplicates

    // Split configs on whether they are for current weathers or forecasts
    Set<ForecastConfig> currents = {};
    Set<ForecastConfig> forecasts = {};
    for (var e in configs) {
      (e.isForecast ? forecasts : currents).add(e);
    }

    // Split forecasts according to locations
    final forecastMap = <String, Set<DateTime>>{};
    for (var e in forecasts) {
      final location = e.location.trim();
      forecastMap.putIfAbsent(location, () => {});
      forecastMap[location]!.add(e.dateTime);
    }

    // Convert currents to locations
    final currentMap = <String>{};
    for (var e in currents) {
      final location = e.location.trim();
      currentMap.add(location);
    }

    // Make simulatenous API calls
    final responses = await fetchWeatherBatch(currents: currentMap, forecasts: forecastMap);

    // Make weathers from responses
    final weathers = await processWeatherBatch(responses, hourInterval);

    // Return in order of time (or name for equal)
    weathers.sort((a, b) {
      final timeComparison = a.localTime.compareTo(b.localTime);
      if (timeComparison != 0) return timeComparison;
      return a.cityName.compareTo(b.cityName);
    });

    return weathers;
  }

  /// Round the time of [config] to the [hourInterval] starting from 0:00. If the rounded time
  /// is before [earliest], the time is set to null to represent current time.
  void roundForecastTime(ForecastConfig config, DateTime earliest, int hourInterval) {
    if (!config.isForecast) return;
    final dt = config.dateTime;

    final totalHours = dt.hour + dt.minute / 60.0;

    // Calculate the nearest hour interval block
    final roundedBlocks = (totalHours / hourInterval).round();
    int roundedHour = roundedBlocks * hourInterval;

    DateTime? dtRounded = roundedHour >= 24
        ? DateTime(dt.year, dt.month, dt.day + 1, 0, 0, 0)
        : DateTime(dt.year, dt.month, dt.day, roundedHour, 0, 0);

    if (!earliest.isBefore(dtRounded)) {
      dtRounded = null;
    }
    config.setDateTime(dtRounded);
  }

  /// Return current location if [cityName] is empty, otherwise find matching location
  Future<Location> determineLocation({String? cityName}) async {
    return cityName == null || cityName.trim().isEmpty
        ? await getCurrentLocation()
        : await getLocationFromCityName(cityName);
  }

  Future<String> getAPIKey() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString(PrefKeys.apiKeyOWM);
    if (apiKey == null) throw 'No API key, set it in Settings';
    return apiKey;
  }

  /// Make simultaneous API calls to obtain cuurent and forecast weather data for different
  /// cities. [currents] should be name of cities (or empty for local), [forecasts} should have
  /// locations as key, and desired timestamps as a set.
  Future<WeatherBatchResponses> fetchWeatherBatch({
    Set<String>? currents,
    Map<String, Set<DateTime>>? forecasts,
  }) async {
    final apiKey = await getAPIKey();

    final currentFutures = <Future<CurrentWeatherResponse>>[];
    if (currents != null) {
      for (final location in currents) {
        currentFutures.add(() async {
          final resolvedLocation = await determineLocation(cityName: location);
          double lat = resolvedLocation.latitude;
          double lon = resolvedLocation.longitude;

          final url = Uri.parse('$currentUrl?lat=$lat&lon=$lon&appid=$apiKey&units=$units');

          final response = await http.get(url);

          return CurrentWeatherResponse(location: resolvedLocation, response: response);
        }());
      }
    }

    final forecastFutures = <Future<ForecastWeatherResponse>>[];
    if (forecasts != null) {
      for (final entry in forecasts.entries) {
        final location = entry.key;
        final timestamps = entry.value;

        forecastFutures.add(() async {
          final resolvedLocation = await determineLocation(cityName: location);
          double lat = resolvedLocation.latitude;
          double lon = resolvedLocation.longitude;
          final cnt = 40; // Maximum and default

          final url = Uri.parse(
            '$forecastUrl?lat=$lat&lon=$lon&appid=$apiKey&units=$units&cnt=$cnt',
          );

          final response = await http.get(url);

          return ForecastWeatherResponse(
            location: resolvedLocation,
            timestamps: timestamps,
            response: response,
          );
        }());
      }
    }

    final currentResults = await Future.wait(currentFutures);
    final forecastResults = await Future.wait(forecastFutures);

    return WeatherBatchResponses(
      currentResponses: currentResults,
      forecastResponses: forecastResults,
    );
  }

  /// Generate Weather objects from the provided API response [batch]. [hourInterval] is used for
  /// determining the indices for forecast timestamps in the response body.
  Future<List<Weather>> processWeatherBatch(WeatherBatchResponses batch, int hourInterval) async {
    // Obtain current weathers
    final currentFutures = <Future<Weather>>[];
    for (final currentResponse in batch.currentResponses) {
      currentFutures.add(() async {
        final response = currentResponse.response;
        checkResponse(response);
        return Weather.fromOWMJson(jsonDecode(response.body));
      }());
    }

    // Obtain forecast weathers
    final forecastFutures = <Future<List<Weather>>>[];
    for (final forecastResponse in batch.forecastResponses) {
      forecastFutures.add(() async {
        final response = forecastResponse.response;
        checkResponse(response);

        final json = jsonDecode(response.body);
        final list = json['list'] as List<dynamic>;

        if (list.isEmpty) {
          throw Exception('Forecast list is empty for ${forecastResponse.location}');
        }

        // Check the first forecast's time
        final firstDtSec = list.first['dt'] as int;
        final firstDt = DateTime.fromMillisecondsSinceEpoch(firstDtSec * 1_000, isUtc: false);

        // Calculate indices corresponding to desired timestamps
        final indices = forecastResponse.timestamps.map((ts) {
          final diff = ts.difference(firstDt);
          final index = (diff.inHours / hourInterval).round();
          if (index < 0 || index >= list.length) {
            throw Exception(
              'Timestamp $ts is out of forecast range for ${forecastResponse.location}',
            );
          }
          return index;
        }).toList();

        return Weather.fromOWMForecastJson(json, indices);
      }());
    }

    final currentResults = await Future.wait(currentFutures); // List<Weather>
    final forecastResultsList = await Future.wait(forecastFutures); // List<List<Weather>>
    // Flatten the nested list
    final forecastResults = forecastResultsList.expand((e) => e).toList();
    return [...currentResults, ...forecastResults];
  }

  /// Fetch the current weather.
  Future<Weather> fetchWeather({String? cityName}) async {
    if (kDebugMode) debugPrint('In fetch Weather');
    final apiKey = await getAPIKey();

    final location = await determineLocation(cityName: cityName);
    double lat = location.latitude;
    double lon = location.longitude;

    final response = await http.get(
      Uri.parse('$currentUrl?lat=$lat&lon=$lon&appid=$apiKey&units=$units'),
    );

    checkResponse(response);
    return Weather.fromOWMJson(jsonDecode(response.body));
  }

  Future<Location> getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    } else if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied, re-enable from app settings.');
    }
    Position position = await Geolocator.getCurrentPosition().timeout(Duration(seconds: 10));

    return Location(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime(0),
    );
  }

  Future<String> getCurrentCity() async {
    Location location = await getCurrentLocation();
    String cityName = await getCityNameFromLocation(location);
    return cityName;
  }
}

Future<Location> getLocationFromCityName(String cityName) async {
  List<Location> locations;
  try {
    // Mobile only
    locations = await locationFromAddress(cityName);
  } catch (e) {
    if (kIsWeb) throw Exception('Location from city name not supported on web.');
    if (e is NoResultFoundException) {
      // Reword to include input
      throw Exception('No locations found for the provided city name: $cityName.');
    }
    rethrow;
  }

  if (kDebugMode) debugPrint('Found locations: $locations');
  return locations.first;
}

Future<String> getCityNameFromLocation(Location location) async {
  List<Placemark> placemarks = await placemarkFromCoordinates(
    location.latitude,
    location.longitude,
  );

  if (placemarks.isNotEmpty) {
    final placemark = placemarks.first;
    return placemark.locality ?? '';
  } else {
    throw Exception('No placemarks found for the provided coordinates.');
  }
}

void checkResponse(http.Response response) {
  if (response.statusCode != 200) {
    final msg =
        'Failed to load weather data, code ${response.statusCode}: ${response.reasonPhrase}';
    if (kDebugMode) debugPrint(msg);
    throw Exception(msg);
  }
}

class WeatherBatchResponses {
  final List<CurrentWeatherResponse> currentResponses;
  final List<ForecastWeatherResponse> forecastResponses;

  WeatherBatchResponses({required this.currentResponses, required this.forecastResponses});
}

class CurrentWeatherResponse {
  final Location location;
  final http.Response response;

  CurrentWeatherResponse({required this.location, required this.response});
}

class ForecastWeatherResponse {
  final Location location;
  final Set<DateTime> timestamps;
  final http.Response response;

  ForecastWeatherResponse({
    required this.location,
    required this.timestamps,
    required this.response,
  });
}
