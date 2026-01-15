import 'package:flutter/foundation.dart';
import 'package:outdoor_clothing_picker/core/utils/forecast_config_model.dart';
import 'package:outdoor_clothing_picker/core/utils/weather_model.dart';
import 'package:outdoor_clothing_picker/features/clother/weather_repository.dart';

class WeatherViewModel extends ChangeNotifier {
  final WeatherRepository _weatherRepository;

  WeatherViewModel({required WeatherRepository weatherRepository})
    : _weatherRepository = weatherRepository;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  List<WeatherPresenter> get weathers => _weatherRepository.weathers;

  String get updateInfo => _weatherRepository.updateInfo;

  Future<void> refresh() async {
    await _weatherRepository.refresh();
    notifyListeners();
  }

  /// Like refresh(), but sets loading booleans (for showing an icon), should be used
  /// if no RefreshIndicator is used.
  Future<void> refreshWithLoading() async {
    await _runWithLoading(_weatherRepository.refresh);
  }

  Future<void> updateWeatherConfigs({required List<ForecastConfig>? configs}) async {
    if (configs == null) return;
    await _runWithLoading(() => _weatherRepository.applyForecastConfigs(configs: configs));
    // TODO: delegate to backend
    await saveForecastConfigs(configs);
  }

  Future<void> _runWithLoading(Future<void> Function() command) async {
    _isLoading = true;
    notifyListeners();
    try {
      await command();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
