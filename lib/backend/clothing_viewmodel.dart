import 'package:flutter/foundation.dart';
import 'package:outdoor_clothing_picker/backend/utils.dart';
import 'package:outdoor_clothing_picker/database/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClothingViewModel extends ChangeNotifier {
  final AppDb _db;

  ClothingViewModel(this._db) {
    _initialize();
  }

  int? _temperature;
  String? _activity;

  List<ValidClothingResult> _valid = [];
  List<ValidClothingResult> _filtered = [];

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedActivity = prefs.getString(PrefKeys.activity);
    await setActivity(activity: savedActivity);
  }

  String? get activity => _activity;

  List<ValidClothingResult> get filteredClothing => _filtered;

  Future<void> setDefaultActivity(List<String> activityNames) async {
    if (_activity != null && activityNames.contains(_activity)) return;
    await setActivity(activity: activityNames.firstOrNull, load: true);
  }

  Future<void> setActivity({required String? activity, bool load = true}) async {
    if (_activity == activity) return;

    _activity = activity;
    final prefs = await SharedPreferences.getInstance();

    // Update or remove saved preference
    activity == null
        ? await prefs.remove(PrefKeys.activity)
        : await prefs.setString(PrefKeys.activity, activity);

    if (load) await _loadClothing();
  }

  void setTemperature({required double? temp, bool load = true}) {
    final int? value = temp?.round();
    bool changed = _temperature != value;
    _temperature = value;
    if (changed && load) _loadClothing();
  }

  /// For each category, choose clothing that are valid for the weather and activity.
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
