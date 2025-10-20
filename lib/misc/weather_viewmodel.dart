import 'package:flutter/foundation.dart';

import 'package:outdoor_clothing_picker/misc/weather_model.dart';
import 'package:outdoor_clothing_picker/misc/weather_service.dart';

class WeatherViewModel extends ChangeNotifier {
  final WeatherService _weatherService;

  WeatherViewModel(this._weatherService);

  String? _cityName;
  double? _apiTemperature;
  double? _manualTemperature;
  String? _mainCondition;
  bool _isLoading = false;

  String? get cityName => _cityName;

  double? get apiTemperature => _apiTemperature;

  double? get manualTemperature => _manualTemperature;

  String? get mainCondition => _mainCondition;

  bool get isUsingManual => _manualTemperature != null;

  bool get isLoading => _isLoading;

  double? get temperature => isUsingManual ? _manualTemperature : _apiTemperature;

  void setManualTemperature(String value) {
    if (value.isEmpty) {
      _manualTemperature = null;
    } else {
      _manualTemperature = double.parse(value.trim());
    }
    notifyListeners();
  }

  Future<void> fetchWeather(String city) async {
    try {
      // TODO as city input does not work on web, decide which approach(es) to use
      // final Weather weather = await _weatherService.getWeatherByCity(city);
      final Weather weather = await _weatherService.getWeatherByCurrentLocation();
      _cityName = weather.cityName;
      _apiTemperature = weather.temperature;
      _mainCondition = weather.mainCondition;
      _manualTemperature = null;
    } catch (e) {
      _cityName = null;
      _apiTemperature = null;
      _mainCondition = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
