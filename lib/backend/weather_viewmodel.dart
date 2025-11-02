import 'package:flutter/foundation.dart';
import 'package:outdoor_clothing_picker/backend/weather_model.dart';
import 'package:outdoor_clothing_picker/backend/weather_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:outdoor_clothing_picker/backend/utils.dart';

class WeatherViewModel extends ChangeNotifier {
  final WeatherService _weatherService;

  WeatherViewModel(this._weatherService) {
    _initialize();
  }

  String? _cityName;
  double? _apiTemperature;
  double? _manualTemperature;
  String? _mainCondition;
  String? _updateInfo;
  bool _isLoading = false;

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedManualTemp = prefs.getString(PrefKeys.manualTemp) ?? '';
    await setManualTemperature(savedManualTemp);
  }

  String? get cityName => _cityName;

  double? get apiTemperature => _apiTemperature;

  double? get manualTemperature => _manualTemperature;

  String? get mainCondition => _mainCondition;

  String? get updateInfo => _updateInfo;

  bool get isUsingManual => _manualTemperature != null;

  bool get isLoading => _isLoading;

  double? get temperature => isUsingManual ? _manualTemperature : _apiTemperature;

  Future<void> setManualTemperature(String value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value.isEmpty) {
      _manualTemperature = null;
      await prefs.remove(PrefKeys.manualTemp);
    } else {
      _updateInfo = 'Using Manual Temperature';
      _manualTemperature = double.parse(value.trim());
      await prefs.setString(PrefKeys.manualTemp, value);
    }
    notifyListeners();
  }

  Future<void> refresh() {
    return fetchWeather();
  }

  Future<void> fetchWeather() async {
    try {
      final Weather weather = await _weatherService.getWeatherByCurrentLocation();
      _cityName = weather.cityName;
      _apiTemperature = weather.temperature;
      _mainCondition = weather.mainCondition;
      _manualTemperature = null;
      _updateInfo = 'Updated HH:MM';
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
