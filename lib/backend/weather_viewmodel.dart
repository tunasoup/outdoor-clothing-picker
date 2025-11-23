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

  Weather? _currentWeather;
  List<WeatherView> _currentWeatherViews = [WeatherView.createEmpty()];
  bool _isLoading = false;

  Future<void> _initialize() async {
    // Load a possible saved Weather from previous use
    final prefs = await SharedPreferences.getInstance();
    final String? savedWeather = prefs.getString(PrefKeys.latestWeather);
    if (savedWeather == null) {
      if (kDebugMode) debugPrint('No saved Weather found, starting fresh.');
      return;
    }
    if (kDebugMode) debugPrint('Setting old weather...');
    final weather = Weather.fromJsonString(savedWeather);
    await setWeather(weather);
    // If the saved weather was an API call, and not recent, start refreshing it
    if (!weather.isManual && isOlderThan(weather.updateDate, Duration(minutes: 30))) {
      try {
        if (kDebugMode) debugPrint('Fetching newer weather...');
        await fetchCurrentWeather();
      } catch (_) {
        if (kDebugMode) debugPrint('New weather unavailable');
      }
    }
  }

  String? get cityName => _currentWeather?.cityName;

  String? get mainCondition => _currentWeather?.mainCondition;

  String? get updateInfo {
    // TODO: show update time only if any API weather is included
    if (_currentWeather == null) return null;
    return _currentWeather!.isManual
        ? 'Using Manual Temperature'
        : 'Updated ${formatTime(time: _currentWeather!.updateDate, showConditionalDay: true)}';
  }

  bool get isLoading => _isLoading;

  double? get temperature => _currentWeather?.temperature;

  List<WeatherView> get weathers => _currentWeatherViews;

  /// Create a manual weather from a [temperature] and set it active.
  Future<void> setManualWeather({String? temperature}) async {
    final temp = double.tryParse(temperature?.trim() ?? '');
    if (temp == null) return await setWeather(null);
    await setWeather(Weather.fromTemperature(temp));
  }

  /// Set the current weather information with the provided [weather], or reset if null.
  Future<void> setWeather(Weather? weather) async {
    _currentWeather = weather;
    if (weather == null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(PrefKeys.latestWeather);
    } else {
      await weather.save();
    }
    notifyListeners();
  }

  /// Set the current weather information with the provided [weathers], or reset if null.
  Future<void> setWeathers(List<Weather>? weathers) async {
    final prefs = await SharedPreferences.getInstance();
    if (weathers == null || weathers.isEmpty) {
      _currentWeatherViews = [WeatherView.createEmpty()];
      await prefs.remove(PrefKeys.latestWeather);
    } else {
      _currentWeatherViews = weathers.map(WeatherView.fromWeather).toList();
      final jsonString = jsonEncode(weathers.map((w) => w.toJson()).toList());
      await prefs.setString(PrefKeys.latestWeather, jsonString);
    }
    // notifyListeners();
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

    // Temporarily re-enable manual input
    await setWeather(currentWeathers.firstOrNull);
    // TODO: convert the rest of the class to use lists/weatherview

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
  final DateTime updateDate;
  final bool isManual;

  WeatherView({
    required this.cityName,
    required this.temperature,
    required this.mainCondition,
    required this.updateDate,
    required this.isManual,
  });

  factory WeatherView.fromWeather(Weather weather) {
    return WeatherView(
      cityName: weather.cityName,
      temperature: '${weather.temperature.round()}°C',
      mainCondition: weather.mainCondition,
      updateDate: weather.updateDate,
      isManual: weather.isManual,
    );
  }

  factory WeatherView.createEmpty() {
    return WeatherView(
      cityName: '',
      temperature: '-°C',
      mainCondition: null,
      updateDate: DateTime.timestamp(),
      isManual: true,
    );
  }
}
