import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:outdoor_clothing_picker/core/utils/forecast_config_model.dart';

import './forecast_config_repository.dart';

class ForecastConfigViewModel extends ChangeNotifier {
  final ForecastConfigRepository _repository;

  ForecastConfigViewModel({required ForecastConfigRepository forecastConfigRepository})
    : _repository = forecastConfigRepository {
    _waitForRepo();
  }

  bool isLoading = true;

  Future<void> _waitForRepo() async {
    isLoading = true;
    if (kDebugMode) debugPrint('wait for init');
    await _repository.initialized;
    isLoading = false;
    notifyListeners();
  }

  int get configsLimit => _repository.configsLimit;

  int get configsCount => _repository.configsCount;

  void addConfig() {
    final success = _repository.addConfig();
    if (success) notifyListeners();
  }

  SnackBarAction removeConfig(int index) {
    final config = _repository.removeConfig(index);
    notifyListeners();
    final action = SnackBarAction(
      label: 'UNDO',
      onPressed: () {
        _repository.insertConfig(index, config);
        notifyListeners();
      },
    );
    return action;
  }

  ForecastConfig configAt(int index) {
    return _repository.configAt(index);
  }
}
