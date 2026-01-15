import 'package:flutter/foundation.dart';
import 'package:outdoor_clothing_picker/core/utils/forecast_config_model.dart';

class ForecastConfigRepository {
  late final Future<void> initialized;

  ForecastConfigRepository() {
    initialized = _initialize();
  }

  final configsLimit = 4;

  List<ForecastConfig> configs = [];

  int get configsCount => configs.length;

  Future<void> _initialize() async {
    if (kDebugMode) debugPrint('config repo ini');
    await loadConfigs();
  }

  // TODO: Use a shared storage so that the configs can be supplied to weather features and
  //  saved if valid
  Future<void> loadConfigs() async {
    configs = await loadForecastConfigs();
  }

  bool addConfig() {
    if (configs.length >= configsLimit) return false;
    // Copy latest location
    final lastLocation = configs.isNotEmpty ? configs.last.location : '';
    configs.add(ForecastConfig(location: lastLocation));
    return true;
  }

  void insertConfig(int index, ForecastConfig config) {
    if (configsCount < configsLimit) {
      configs.insert(index, config);
    }
  }

  ForecastConfig removeConfig(int index) {
    return configs.removeAt(index);
  }

  ForecastConfig configAt(int index) {
    return configs[index];
  }
}
