import 'package:flutter/foundation.dart';
import 'package:outdoor_clothing_picker/backend/utils.dart';
import 'package:outdoor_clothing_picker/backend/weather_model.dart';
import 'package:outdoor_clothing_picker/backend/weather_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeatherViewModel extends ChangeNotifier {
  final WeatherService _weatherService;

  WeatherViewModel(this._weatherService) {
    _initialize();
  }

  String? _cityName;
  double? _apiTemperature;
  double? _manualTemperature;
  String? _mainCondition;
  DateTime? _updateDate;
  bool _isLoading = false;

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedManualTemp = prefs.getString(PrefKeys.manualTemp);
    final String? savedApiWeather = prefs.getString(PrefKeys.apiWeather);
    debugPrint('api weather in init: $savedApiWeather');
    // Only one (or neither) of the values should exist at a time
    if (savedApiWeather != null) {
      final weather = Weather.fromJsonString(savedApiWeather);
      await setApiWeather(weather);
    } else {
      await setManualTemperature(savedManualTemp);
    }
  }

  String? get cityName => _cityName;

  double? get apiTemperature => _apiTemperature;

  double? get manualTemperature => _manualTemperature;

  String? get mainCondition => _mainCondition;

  String? get updateInfo {
    if (_manualTemperature == null && _apiTemperature == null) return null;
    return isUsingManual
        ? 'Using Manual Temperature'
        : 'Updated '
              '${formatTime(time: _updateDate!, showConditionalDay: true)}';
  }

  bool get isUsingManual => _manualTemperature != null;

  bool get isLoading => _isLoading;

  double? get temperature => isUsingManual ? _manualTemperature : _apiTemperature;

  /// Override the current temperature with the given [value] in string format, or reset if null
  /// is provided.
  Future<void> setManualTemperature(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      _manualTemperature = null;
      await prefs.remove(PrefKeys.manualTemp);
    } else {
      _manualTemperature = double.parse(value.trim());
      await prefs.setString(PrefKeys.manualTemp, value);
      await setApiWeather(null);
    }
    notifyListeners();
  }

  Future<void> setApiWeather(Weather? weather) async {
    _cityName = weather?.cityName;
    _apiTemperature = weather?.temperature;
    _mainCondition = weather?.mainCondition;
    _updateDate = weather?.updateDate;
    if (weather == null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(PrefKeys.apiWeather);
    } else {
      await weather.save();
      await setManualTemperature(null);
    }
  }

  Future<void> refresh() {
    return fetchWeather();
  }

  Future<void> fetchWeather() async {
    try {
      final Weather weather = await _weatherService.getWeatherByCurrentLocation();
      await setApiWeather(weather);
    } catch (e) {
      await setApiWeather(null);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
