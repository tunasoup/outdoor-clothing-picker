import 'dart:convert';

class Weather {
  final String cityName;
  final double temperature;
  final String mainCondition;
  final DateTime localTime;
  final DateTime updateDate;
  final bool isManual;

  Weather({
    required this.cityName,
    required this.temperature,
    required this.mainCondition,
    required this.localTime,
    required this.updateDate,
    required this.isManual,
  });

  /// Create from a decoded Open Weather Map JSON response.
  factory Weather.fromOWMJson(Map<String, dynamic> json) {
    return Weather(
      cityName: json['name'],
      temperature: json['main']['temp'].toDouble(),
      mainCondition: json['weather'][0]['main'],
      localTime: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1_000, isUtc: false),
      updateDate: DateTime.timestamp(),
      isManual: false,
    );
  }

  static List<Weather> fromOWMForecastJson(Map<String, dynamic> json, List<int> indices) {
    final updateDate = DateTime.timestamp();
    final cityName = json['city']['name'];
    return indices.map((idx) {
      final jsonList = json['list'][idx];
      return Weather(
        cityName: cityName,
        temperature: jsonList['main']['temp'].toDouble(),
        mainCondition: jsonList['weather'][0]['main'],
        localTime: DateTime.fromMillisecondsSinceEpoch(jsonList['dt'] * 1_000, isUtc: false),
        updateDate: updateDate,
        isManual: false,
      );
    }).toList();
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
      localTime: DateTime.parse(input['localTime']),
      updateDate: DateTime.parse(input['updateDate']),
      isManual: input['isManual'],
    );
  }

  factory Weather.fromTemperature(double temperature) {
    final now = DateTime.timestamp();
    return Weather(
      cityName: '',
      temperature: temperature,
      mainCondition: '',
      localTime: now.toLocal(),
      updateDate: now,
      isManual: true,
    );
  }

  Map<String, dynamic> toJson() => {
    'cityName': cityName,
    'temperature': temperature,
    'mainCondition': mainCondition,
    'localTime': localTime.toString(),
    'updateDate': updateDate.toString(),
    'isManual': isManual,
  };
}
