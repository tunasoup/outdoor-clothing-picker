import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:outdoor_clothing_picker/backend/forecast_config.dart';
import 'package:outdoor_clothing_picker/backend/utils.dart';
import 'package:outdoor_clothing_picker/backend/weather_model.dart';
import 'package:outdoor_clothing_picker/backend/weather_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages and provides weather information obtained manually or via [_weatherService].
class WeatherViewModel extends ChangeNotifier {
  final WeatherService _weatherService;

  WeatherViewModel(this._weatherService) {
    _initialize();
  }

  List<WeatherPresenter> _currentWeatherViews = [WeatherPresenter.createEmpty()];
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  List<WeatherPresenter> get weathers => _currentWeatherViews;

  Future<void> _initialize() async {
    // Load a possible saved Weathers from previous use
    _isLoading = true;
    final prefs = await SharedPreferences.getInstance();
    final String? savedWeathers = prefs.getString(PrefKeys.latestWeathers);
    if (savedWeathers == null) {
      if (kDebugMode) debugPrint('No saved Weathers found, starting fresh.');
    } else {
      if (kDebugMode) debugPrint('Setting old weathers...');
      final weathers = loadWeathersFromJson(savedWeathers);
      await setWeathers(weathers);
      // If the saved weathers has an API call, and not recent, start refreshing them
      if (_currentWeatherViews.any((e) => !e.isManual) &&
          isOlderThan(weathers.first.updateDate, Duration(minutes: 30))) {
        try {
          if (kDebugMode) debugPrint('Fetching newer weather...');
          await fetchSelectedWeathers();
        } catch (_) {
          if (kDebugMode) debugPrint('New weather unavailable');
        }
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  String get updateInfo {
    if (_currentWeatherViews.isEmpty || _currentWeatherViews.first.isEmpty) {
      return 'Pull down to fetch current weather or tap for input';
    } else if (_currentWeatherViews.any((e) => !e.isManual)) {
      // Each current weather should have the same time they were updated
      final updateDate = _currentWeatherViews.first.updateDate;
      return 'Updated ${formatTime(time: updateDate, showConditionalDay: true)}';
    } else {
      String msg = 'Using Manual Temperature';
      msg += _currentWeatherViews.length > 1 ? 's' : '';
      return msg;
    }
  }

  List<Weather> loadWeathersFromJson(String jsonString) {
    final List<dynamic> weatherStrings = jsonDecode(jsonString);
    final weathers = weatherStrings.map((e) => Weather.fromMap(e)).toList();
    return weathers;
  }

  /// Set the current weather information with the provided [weathers], or reset if null.
  Future<void> setWeathers(List<Weather>? weathers) async {
    final prefs = await SharedPreferences.getInstance();
    if (weathers == null || weathers.isEmpty) {
      _currentWeatherViews = [WeatherPresenter.createEmpty()];
      await prefs.remove(PrefKeys.latestWeathers);
    } else {
      _currentWeatherViews = weathers.map(WeatherPresenter.fromWeather).toList();
      final jsonString = jsonEncode(weathers.map((w) => w.toJson()).toList());
      await prefs.setString(PrefKeys.latestWeathers, jsonString);
    }
  }

  Future<void> applyForecastConfigs(List<ForecastConfig>? configs) async {
    if (configs == null) return;
    _isLoading = true;
    notifyListeners();
    configs = cleanForecastConfigs(configs);

    if (configs.isEmpty) {
      await setWeathers(null);
      _isLoading = false;
      notifyListeners();
      return;
    }

    var manual = <ForecastConfig>[];
    var automatic = <ForecastConfig>[];

    for (final c in configs) {
      (c.isManual ? manual : automatic).add(c);
    }

    List<Weather> weathers = [];

    // Add manual weathers
    weathers += manual
        .map((e) => Weather.fromTemperature(e.manualTemperature!.toDouble()))
        .toList();

    // Add API weathers
    try {
      weathers += await _weatherService.fetchWeathers(automatic);
      await setWeathers(weathers);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<ForecastConfig> cleanForecastConfigs(List<ForecastConfig> configs) {
    if (kDebugMode) debugPrint('Configs: $configs');
    configs = configs.where((c) => !c.isEmpty).toList();
    configs = configs.toSet().toList(); // Remove duplicates
    if (kDebugMode) debugPrint('Cleaned configs: $configs');
    return configs;
  }

  /// Try to fetch the selected weathers without waiting for them.
  Future<void> refresh() {
    return tryFetchSelectedWeathers();
  }

  /// Fetch the weathers matching the latest successful configs, or if there are none, the
  /// default config (current weather in current position).
  Future<void> fetchSelectedWeathers() async {
    final configs = await loadForecastConfigs(useDefault: true);
    await applyForecastConfigs(configs);
  }

  Future<void> tryFetchSelectedWeathers() async {
    _isLoading = true;
    notifyListeners();

    try {
      await fetchSelectedWeathers();
    } catch (e) {
      await setWeathers(null);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class WeatherPresenter {
  final String cityName;
  final num? temperature;
  final String? mainCondition;
  final DateTime localTime;
  final DateTime updateDate;
  final bool isManual;
  final bool isEmpty;

  WeatherPresenter({
    required this.cityName,
    required this.temperature,
    required this.mainCondition,
    required this.localTime,
    required this.updateDate,
    required this.isManual,
    this.isEmpty = false,
  });

  String get temperatureDisplay => '${temperature?.round() ?? '-'}°C';

  String get description {
    if (isManual) {
      return 'manual\n';
    } else {
      return '$cityName\n${formatTime(time: localTime, showConditionalDay: true)}';
    }
  }

  factory WeatherPresenter.fromWeather(Weather weather) {
    return WeatherPresenter(
      cityName: weather.cityName,
      temperature: weather.temperature,
      mainCondition: weather.mainCondition,
      localTime: weather.localTime,
      updateDate: weather.updateDate,
      isManual: weather.isManual,
    );
  }

  factory WeatherPresenter.createEmpty() {
    final now = DateTime.timestamp();
    return WeatherPresenter(
      cityName: '',
      temperature: null,
      mainCondition: null,
      localTime: now.toLocal(),
      updateDate: now,
      isManual: true,
      isEmpty: true,
    );
  }
}
