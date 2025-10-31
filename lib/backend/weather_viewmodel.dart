import 'package:flutter/foundation.dart';
import 'package:outdoor_clothing_picker/backend/weather_model.dart';
import 'package:outdoor_clothing_picker/backend/weather_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String manualTempPrefKey = 'manualTemperature';

class WeatherViewModel extends ChangeNotifier {
  final WeatherService _weatherService;

  WeatherViewModel(this._weatherService) {
    _initialize();
  }

  String? _cityName;
  double? _apiTemperature;
  double? _manualTemperature;
  String? _mainCondition;
  bool _isLoading = false;

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedManualTemp = prefs.getString(manualTempPrefKey) ?? '';
    await setManualTemperature(savedManualTemp);
  }

  String? get cityName => _cityName;

  double? get apiTemperature => _apiTemperature;

  double? get manualTemperature => _manualTemperature;

  String? get mainCondition => _mainCondition;

  bool get isUsingManual => _manualTemperature != null;

  bool get isLoading => _isLoading;

  double? get temperature => isUsingManual ? _manualTemperature : _apiTemperature;

  Future<void> setManualTemperature(String value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value.isEmpty) {
      _manualTemperature = null;
      await prefs.remove(manualTempPrefKey);
    } else {
      _manualTemperature = double.parse(value.trim());
      await prefs.setString(manualTempPrefKey, value);
    }
    notifyListeners();
  }

  Future<void> refresh() {
    return fetchWeather('');
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
