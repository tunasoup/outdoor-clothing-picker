import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:outdoor_clothing_picker/backend/utils.dart';
import 'package:outdoor_clothing_picker/backend/weather_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeatherService {
  WeatherService();

  static const baseUrl = 'https://api.openweathermap.org/data/2.5/weather';
  final String units = 'metric';

  Future<Weather> getWeatherByCity(String cityName) async {
    Location location = await getLocationFromCityName(cityName);
    return getWeatherByLocation(location);
  }

  Future<Weather> getWeatherByCurrentLocation() async {
    Location location = await getCurrentLocation();
    return getWeatherByLocation(location);
  }

  Future<Weather> getWeatherByLocation(Location location) async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString(PrefKeys.apiKeyOWM);
    if (apiKey == null) throw 'No API key, set it in Settings';
    double lat = location.latitude;
    double lon = location.longitude;
    if (kDebugMode) debugPrint('lat:$lat, lon:$lon');
    final response = await http.get(
      Uri.parse('$baseUrl?lat=$lat&lon=$lon&appid=$apiKey&units=$units'),
    );

    if (response.statusCode == 200) {
      return Weather.fromOWMJson(jsonDecode(response.body));
    } else {
      String msg =
          'Failed to load weather data, code ${response.statusCode}: ${response.reasonPhrase}';
      if (kDebugMode) debugPrint(msg);
      throw Exception(msg);
    }
  }

  Future<Location> getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    Position position = await Geolocator.getCurrentPosition();
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
    if (kDebugMode) debugPrint('$e');
    rethrow;
  }

  if (locations.isNotEmpty) {
    return locations.first;
  } else {
    throw Exception('No locations found for the provided city name.');
  }
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
