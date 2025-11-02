import 'dart:convert';

import 'package:outdoor_clothing_picker/backend/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Weather {
  final String cityName;
  final double temperature;
  final String mainCondition;
  final DateTime updateDate;

  Weather({
    required this.cityName,
    required this.temperature,
    required this.mainCondition,
    required this.updateDate,
  });

  /// Create from a decoded Open Weather Map JSON response.
  factory Weather.fromOWMJson(Map<String, dynamic> json) {
    return Weather(
      cityName: json['name'],
      temperature: json['main']['temp'].toDouble(),
      mainCondition: json['weather'][0]['main'],
      updateDate: DateTime.timestamp(),
    );
  }

  /// Create from an earlier Weather instance that used toJson.
  factory Weather.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString);
    return Weather(
      cityName: json['cityName'],
      temperature: json['temperature'],
      mainCondition: json['mainCondition'],
      updateDate: DateTime.parse(json['updateDate']),
    );
  }

  Map<String, dynamic> toJson() => {
    'cityName': cityName,
    'temperature': temperature,
    'mainCondition': mainCondition,
    'updateDate': updateDate.toString(),
  };

  /// Save the Weather arguments locally in an encoded JSON string.
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(toJson());
    await prefs.setString(PrefKeys.apiWeather, jsonString);
  }
}
