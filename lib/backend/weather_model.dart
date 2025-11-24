import 'dart:convert';

class Weather {
  final String cityName;
  final double temperature;
  final String mainCondition;
  final DateTime updateDate;
  final bool isManual;

  Weather({
    required this.cityName,
    required this.temperature,
    required this.mainCondition,
    required this.updateDate,
    required this.isManual,
  });

  /// Create from a decoded Open Weather Map JSON response.
  factory Weather.fromOWMJson(Map<String, dynamic> json) {
    return Weather(
      cityName: json['name'],
      temperature: json['main']['temp'].toDouble(),
      mainCondition: json['weather'][0]['main'],
      updateDate: DateTime.timestamp(),
      isManual: false,
    );
  }

  /// Create from an earlier Weather instance that used toJson.
  factory Weather.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString);
    return Weather.fromMap(json);
  }

  /// Create from an earlier Weather instance that used toJson, followed by decode.
  factory Weather.fromMap(Map<String, dynamic> input) {
    return Weather(
      cityName: input['cityName'],
      temperature: input['temperature'],
      mainCondition: input['mainCondition'],
      updateDate: DateTime.parse(input['updateDate']),
      isManual: input['isManual'],
    );
  }

  factory Weather.fromTemperature(double temperature) {
    return Weather(
      cityName: '',
      temperature: temperature,
      mainCondition: '',
      updateDate: DateTime.timestamp(),
      isManual: true,
    );
  }

  Map<String, dynamic> toJson() => {
    'cityName': cityName,
    'temperature': temperature,
    'mainCondition': mainCondition,
    'updateDate': updateDate.toString(),
    'isManual': isManual,
  };
}
