import 'package:flutter/foundation.dart';
import 'package:outdoor_clothing_picker/core/database/database.dart';

import './clothing_repository.dart';
import './weather_viewmodel.dart';

class ClothingViewModel extends ChangeNotifier {
  final ClothingRepository _clothingRepository;
  final WeatherViewModel weatherViewModel; // Not ideal
  late final VoidCallback _listener;

  ClothingViewModel({
    required ClothingRepository clothingRepository,
    required this.weatherViewModel,
  }) : _clothingRepository = clothingRepository {
    _listener = () {
      if (kDebugMode) debugPrint('listener changed');
      notifyListeners();
    };
    _clothingRepository.filtered.addListener(_listener);
    if (kDebugMode) debugPrint('clothingvm init');
  }

  String? get activity => _clothingRepository.activity;

  List<ValidClothingResult> get filteredClothing => _clothingRepository.filtered.value;

  void setActivity(String? value) {
    _clothingRepository.setActivity(value: value);
    notifyListeners();
  }

  Future<void> refresh() async {
    await weatherViewModel.refresh();
  }

  @override
  void dispose() {
    // FIXME: Not called when a page is changed, so there are multiple VMs, might fix with gorouter
    if (kDebugMode) debugPrint('disposed');
    _clothingRepository.filtered.removeListener(_listener);
    super.dispose();
  }
}
