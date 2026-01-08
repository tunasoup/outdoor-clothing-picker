import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:outdoor_clothing_picker/core/utils/utils.dart';
import 'package:outdoor_clothing_picker/core/utils/weather_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './forecast_config.dart';
import './weather_service.dart';

/// Manages and provides weather information obtained manually or via [_weatherService].
class WeatherRepository extends ChangeNotifier {
  final WeatherService _weatherService;

  WeatherRepository(this._weatherService) {
    _initialize();
  }

  List<WeatherPresenter> _activeWeatherViews = [WeatherPresenter.createEmpty()];

  List<WeatherPresenter> get weathers => _activeWeatherViews;

  Future<void> _initialize() async {
    // Load a possible saved Weathers from previous use
    final prefs = await SharedPreferences.getInstance();
    final String? savedWeathers = prefs.getString(PrefKeys.latestWeathers);
    if (savedWeathers == null) {
      if (kDebugMode) debugPrint('No saved Weathers found, starting fresh.');
    } else {
      if (kDebugMode) debugPrint('Setting old weathers...');
      final weathers = loadWeathersFromJson(savedWeathers);
      await setWeathers(weathers);
      // If the saved weathers has an API call, and not recent, start refreshing them
      if (_activeWeatherViews.any((e) => !e.isManual) &&
          isOlderThan(weathers.first.updateDate, Duration(minutes: 30))) {
        try {
          if (kDebugMode) debugPrint('Fetching newer weathers...');
          await fetchSelectedWeathers();
        } catch (_) {
          if (kDebugMode) debugPrint('New weathers unavailable');
        }
      }
    }
    notifyListeners();
  }

  String get updateInfo {
    if (_activeWeatherViews.isEmpty || _activeWeatherViews.first.isEmpty) {
      return 'Pull down to fetch current weather or tap for input';
    } else if (_activeWeatherViews.any((e) => !e.isManual)) {
      // Each current weather should have the same time they were updated
      final updateDate = _activeWeatherViews.first.updateDate;
      return 'Updated ${formatTime(time: updateDate, showConditionalDay: true)}';
    } else {
      String msg = 'Using Manual Temperature';
      msg += _activeWeatherViews.length > 1 ? 's' : '';
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
      _activeWeatherViews = [WeatherPresenter.createEmpty()];
      await prefs.remove(PrefKeys.latestWeathers);
    } else {
      _activeWeatherViews = weathers.map(WeatherPresenter.fromWeather).toList();
      final jsonString = jsonEncode(weathers.map((w) => w.toJson()).toList());
      await prefs.setString(PrefKeys.latestWeathers, jsonString);
    }
  }

  /// Fetch weathers matching the provided [configs] and set them as active. [showLoading]
  /// should be set to false if an outer function is already notifying listeners.
  Future<void> applyForecastConfigs({
    required List<ForecastConfig>? configs,
    bool showLoading = true,
  }) async {
    if (configs == null) return;
    configs = cleanForecastConfigs(configs);

    if (configs.isEmpty) {
      await setWeathers(null);
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

    try {
      if (automatic.isNotEmpty) {
        // Add API weathers
        weathers += await _weatherService.fetchWeathers(automatic);
      }
      await setWeathers(weathers);
    } catch (e) {
      rethrow;
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
  /// default config (current weather in current position). [showLoading] should be set to false
  /// if an outer function is already notifying listeners.
  Future<void> fetchSelectedWeathers() async {
    final configs = await loadForecastConfigs(useDefault: true);
    await applyForecastConfigs(configs: configs);
  }

  /// Standalone outer function for fetching weather that match the saved forecast configs.
  /// [showLoading] should be set to false if called by RefreshIndicator to avoid double loading
  /// icons.
  Future<void> tryFetchSelectedWeathers() async {
    try {
      await fetchSelectedWeathers();
    } catch (e) {
      await setWeathers(null);
      rethrow;
    } finally {
      notifyListeners();
    }
  }
}
