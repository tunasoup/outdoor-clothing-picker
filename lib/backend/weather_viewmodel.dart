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

  List<WeatherView> _currentWeatherViews = [WeatherView.createEmpty()];
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  List<WeatherView> get weathers => _currentWeatherViews;

  Future<void> _initialize() async {
    // Load a possible saved Weathers from previous use
    final prefs = await SharedPreferences.getInstance();
    final String? savedWeathers = prefs.getString(PrefKeys.latestWeathers);
    if (savedWeathers == null) {
      if (kDebugMode) debugPrint('No saved Weathers found, starting fresh.');
      return;
    }
    if (kDebugMode) debugPrint('Setting old weathers...');
    final weathers = loadWeathersFromJson(savedWeathers);
    unawaited(setWeathers(weathers));
    // If the saved weathers has an API call, and not recent, start refreshing it
    if (_currentWeatherViews.any((e) => !e.isManual) &&
        isOlderThan(weathers.first.updateDate, Duration(minutes: 30))) {
      try {
        if (kDebugMode) debugPrint('Fetching newer weather...');
        // TODO: use saved forecastConfigs which should match the old weathers
        await fetchCurrentWeather();
      } catch (_) {
        if (kDebugMode) debugPrint('New weather unavailable');
      }
    }
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

  /// Create a manual weather from a [temperature] and set it active.
  Future<void> setManualWeather({String? temperature}) async {
    final temp = double.tryParse(temperature?.trim() ?? '');
    if (temp == null) return await setWeather(null);
    await setWeather(Weather.fromTemperature(temp));
  }

  /// Set the current weather information with the provided [weather], or reset if null.
  Future<void> setWeather(Weather? weather) async {
    final weathers = weather == null ? null : [weather];
    await setWeathers(weathers);
  }

  /// Set the current weather information with the provided [weathers], or reset if null.
  Future<void> setWeathers(List<Weather>? weathers) async {
    final prefs = await SharedPreferences.getInstance();
    if (weathers == null || weathers.isEmpty) {
      _currentWeatherViews = [WeatherView.createEmpty()];
      await prefs.remove(PrefKeys.latestWeathers);
    } else {
      _currentWeatherViews = weathers.map(WeatherView.fromWeather).toList();
      final jsonString = jsonEncode(weathers.map((w) => w.toJson()).toList());
      await prefs.setString(PrefKeys.latestWeathers, jsonString);
    }
    notifyListeners(); // FIXME: called unnecessary often
  }

  Future<void> applyForecastConfigs(List<ForecastConfig>? configs) async {
    if (configs == null) return;
    _isLoading = true;
    notifyListeners();
    configs = cleanForecastConfigs(configs);

    if (configs.isEmpty) {
      // TODO: decide what to do, either reset weather, do not act (maybe snackbar), or run
      //  current. Realistically only empty if an empty manual temperature is provided, which
      //  could be prevented in the UI by disabling apply.
      return;
    }

    var manual = <ForecastConfig>[];
    var automatic = <ForecastConfig>[];

    for (final c in configs) {
      (c.isManual ? manual : automatic).add(c);
    }

    List<Weather> currentWeathers = [];

    // Add manual weathers
    currentWeathers += manual
        .map((e) => Weather.fromTemperature(e.manualTemperature!.toDouble()))
        .toList();

    // Add API weathers
    currentWeathers += await _weatherService.getWeathers(automatic);

    await setWeathers(currentWeathers);
    _isLoading = false;
    notifyListeners();
  }

  List<ForecastConfig> cleanForecastConfigs(List<ForecastConfig> configs) {
    if (kDebugMode) debugPrint('Configs: $configs');
    configs.removeWhere((c) => c.isEmpty);
    configs = configs.toSet().toList(); // Remove duplicates
    if (kDebugMode) debugPrint('Cleaned configs: $configs');
    return configs;
  }

  /// Try to fetch the current weather without waiting for it.
  Future<void> refresh() {
    return tryFetchCurrentWeather();
  }

  Future<void> fetchCurrentWeather() async {
    final Weather weather = await _weatherService.getWeatherByCurrentLocation();
    if (kDebugMode) debugPrint('start to set weather');
    await setWeather(weather);
  }

  Future<void> tryFetchCurrentWeather() async {
    _isLoading = true;
    notifyListeners();

    try {
      await fetchCurrentWeather();
    } catch (e) {
      await setWeather(null);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class WeatherView {
  final String cityName;
  final String temperature;
  final String? mainCondition;
  final DateTime localTime;
  final DateTime updateDate;
  final bool isManual;
  final bool isEmpty;

  WeatherView({
    required this.cityName,
    required this.temperature,
    required this.mainCondition,
    required this.localTime,
    required this.updateDate,
    required this.isManual,
    this.isEmpty = false,
  });

  String get description {
    if (isManual) {
      return 'manual\n';
    } else {
      return '$cityName\n${formatTime(time: localTime, showConditionalDay: true)}';
    }
  }

  factory WeatherView.fromWeather(Weather weather) {
    return WeatherView(
      cityName: weather.cityName,
      temperature: '${weather.temperature.round()}°C',
      mainCondition: weather.mainCondition,
      localTime: weather.localTime,
      updateDate: weather.updateDate,
      isManual: weather.isManual,
    );
  }

  factory WeatherView.createEmpty() {
    final now = DateTime.timestamp();
    return WeatherView(
      cityName: '',
      temperature: '-°C',
      mainCondition: null,
      localTime: now.toLocal(),
      updateDate: now,
      isManual: true,
      isEmpty: true,
    );
  }
}
