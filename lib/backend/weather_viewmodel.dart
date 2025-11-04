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
    // Only one (or neither) of the values should exist at a time
    if (savedApiWeather != null) {
      // If API was active last, try to fetch new weather if the saved one is old
      final weather = Weather.fromJsonString(savedApiWeather);
      if (isOlderThan(weather.updateDate, Duration(minutes: 30))) {
        try {
          if (kDebugMode) debugPrint('Fetching newer weather...');
          await fetchWeather();
        } catch (_) {
          if (kDebugMode) debugPrint('New weather unavailable, using old');
          await setApiWeather(weather);
        }
      } else {
        if (kDebugMode) debugPrint('Loading old weather as it is recent');
        await setApiWeather(weather);
      }
    } else {
      if (kDebugMode) debugPrint('Starting with earlier manual weather');
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
    return tryFetchWeather();
  }

  Future<void> fetchWeather() async {
    final Weather weather = await _weatherService.getWeatherByCurrentLocation();
    if (kDebugMode) debugPrint('start to set weather');
    await setApiWeather(weather);
  }

  Future<void> tryFetchWeather() async {
    _isLoading = true;
    notifyListeners();

    try {
      await fetchWeather();
    } catch (e) {
      await setApiWeather(null);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
