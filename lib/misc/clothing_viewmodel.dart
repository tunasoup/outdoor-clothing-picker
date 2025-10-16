import 'package:flutter/foundation.dart';

import 'package:outdoor_clothing_picker/database/database.dart';

class ClothingViewModel extends ChangeNotifier {
  final AppDb _db;

  int? _temperature;
  String? _activity;

  List<ValidClothingResult> _valid = [];
  List<ValidClothingResult> _filtered = [];

  ClothingViewModel(this._db);

  List<ValidClothingResult> get filteredClothing => _filtered;

  void setActivity(String? activity, {bool load = true}) {
    bool changed = _activity != activity;
    _activity = activity;
    if (changed && load) _loadClothing();
  }

  void setTemperature({required double? temp, bool load = true}) {
    final int? value = temp?.round();
    bool changed = _temperature != value;
    _temperature = value;
    if (changed && load) _loadClothing();
  }

  Future<void> _loadClothing() async {
    if (_temperature == null || _activity == null) {
      _filtered = [];
      _valid = [];
      notifyListeners();
      return;
    }

    List<category> categories = await _db.allCategories().get();
    _valid = await _db.validClothing(_temperature!, _activity!).get();
    Map<String, ValidClothingResult?> outfit = {};
    for (var category in categories) {
      final categoryItems = _valid.where((item) => item.category == category.name).toList();
      if (categoryItems.isNotEmpty) {
        // If there are multiple items, choose the first
        // TODO: Choose the first chosen based on temperature range
        // TODO: Store all valid items, make interactable (tap for list or arrows)
        outfit[category.name] = categoryItems.first;
      } else {
        outfit[category.name] = null;
      }
    }
    _filtered = outfit.values.whereType<ValidClothingResult>().toList();
    notifyListeners();
  }
}
