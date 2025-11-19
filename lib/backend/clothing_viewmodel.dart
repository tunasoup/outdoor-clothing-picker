import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:outdoor_clothing_picker/backend/items_provider.dart';
import 'package:outdoor_clothing_picker/backend/utils.dart';
import 'package:outdoor_clothing_picker/backend/weather_viewmodel.dart';
import 'package:outdoor_clothing_picker/database/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClothingViewModel extends ChangeNotifier {
  final AppDb _db;
  final WeatherViewModel weatherVM;
  final ActivityItemsProvider providerAct;
  final CategoryItemsProvider providerCat;
  final ClothingItemsProvider providerClo;

  ClothingViewModel(
    this._db,
    this.weatherVM,
    this.providerAct,
    this.providerCat,
    this.providerClo,
  ) {
    _initialize();
  }

  int? _temperature;
  String? _activity;

  List<ValidClothingResult> _valid = [];
  List<ValidClothingResult> _filtered = [];

  Future<void> _initialize() async {
    // Load previous activity
    final prefs = await SharedPreferences.getInstance();
    final savedActivity = prefs.getString(PrefKeys.activity);
    await setActivity(activity: savedActivity);

    // Subscribe to changes
    weatherVM.addListener(() {
      setTemperature(temp: weatherVM.temperature);
    });
    providerAct.addListener(() {
      setDefaultActivity(providerAct.names);
    });
    providerCat.addListener(_loadClothing);
    providerClo.addListener(_loadClothing);
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

    _valid = await _db.validClothing(_temperature!, _activity!).get();
    final validCategoryClothing = groupBy(_valid, (ValidClothingResult v) => v.categoryName);

    // Choose the first item for each available category
    // TODO: sort based on temperature range first
    _filtered = validCategoryClothing.entries.map((e) => e.value.first).toList();
    // TODO: Make interactable, allowing switching between valid items

    notifyListeners();
  }
}
