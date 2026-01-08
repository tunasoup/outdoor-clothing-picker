import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:outdoor_clothing_picker/core/database/database.dart';
import 'package:outdoor_clothing_picker/core/database/items_provider.dart';
import 'package:outdoor_clothing_picker/core/utils/utils.dart';
import 'package:outdoor_clothing_picker/core/utils/weather_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './weather_repository.dart';

class ClothingRepository {
  final AppDb _db;
  final WeatherRepository weatherRepo;
  final ActivityItemsProvider providerAct;
  final CategoryItemsProvider providerCat;
  final ClothingItemsProvider providerClo;

  // FIXME: Should not use another repository, services are fine

  ClothingRepository(
    this._db,
    this.weatherRepo,
    this.providerAct,
    this.providerCat,
    this.providerClo,
  ) {
    _initialize();
  }

  List<int> _temperatures = [];
  String? _activity;

  List<ValidClothingResult> _valid = [];

  // List<ValidClothingResult> _filtered = [];
  ValueNotifier<List<ValidClothingResult>> filtered = ValueNotifier([]);

  Future<void> _initialize() async {
    // Load previous activity
    final prefs = await SharedPreferences.getInstance();
    final savedActivity = prefs.getString(PrefKeys.activity);
    await setActivity(value: savedActivity);

    // Subscribe to changes
    weatherRepo.addListener(() {
      setWeathers(weathers: weatherRepo.weathers);
    });
    providerAct.addListener(() {
      setDefaultActivity(providerAct.names);
    });
    providerCat.addListener(_loadClothing);
    providerClo.addListener(_loadClothing);

    // Set the weathers first time in case weather was fetched before listening started
    setWeathers(weathers: weatherRepo.weathers);
    filtered.value = [...filtered.value]; // Fail-safe update, not ideal
  }

  String? get activity => _activity;

  // List<ValidClothingResult> get filteredClothing => _filtered;

  Future<void> setDefaultActivity(List<String> activityNames) async {
    if (_activity != null && activityNames.contains(_activity)) return;
    await setActivity(value: activityNames.firstOrNull, load: true);
  }

  Future<void> setActivity({required String? value, bool load = true}) async {
    if (_activity == value) return;

    _activity = value;
    final prefs = await SharedPreferences.getInstance();

    // Update or remove saved preference
    value == null
        ? await prefs.remove(PrefKeys.activity)
        : await prefs.setString(PrefKeys.activity, value);

    if (load) await _loadClothing();
  }

  void setWeathers({required List<WeatherPresenter> weathers, bool load = true}) {
    List<int> values = [];
    if (weathers.isNotEmpty && !weathers.first.isEmpty) {
      // Temperature should be null only for the empty template
      values = weathers.map((e) => e.temperature!.round()).toList();
    }
    bool changed = _temperatures != values;
    _temperatures = values;
    if (changed && load) _loadClothing();
  }

  void _changeFiltered(List<ValidClothingResult> newValues) {
    if (!listEquals(newValues, filtered.value)) {
      filtered.value = newValues;
    }
  }

  /// For each category, choose clothing that are valid for the weathers and activity.
  Future<void> _loadClothing() async {
    if (_temperatures.isEmpty || _activity == null) {
      _changeFiltered([]);
      _valid = [];
      return;
    }

    // TODO: scoring algorithm to find the best clothing in each category for combined weathers
    // Make separate calls for each weather instance for scoring them individually
    List<Map<String, List<ValidClothingResult>>> instanceResults = [];
    for (final int temperature in _temperatures) {
      _valid = await _db.validClothing(temperature, _activity!).get();
      final validCategoryClothing = groupBy(_valid, (ValidClothingResult v) => v.categoryName);
      instanceResults.add(validCategoryClothing);
    }
    final results = getCommonResults(instanceResults);
    _changeFiltered(results);
    // TODO: Make interactable, allowing switching between valid items, indicate compatibility
    //  score with colors
  }

  /// For each category, return a single clothing item that is present in each instance.
  List<ValidClothingResult> getCommonResults(
    List<Map<String, List<ValidClothingResult>>> instanceResults,
  ) {
    if (instanceResults.isEmpty) return [];

    final firstInstance = instanceResults.first;
    final List<ValidClothingResult> output = [];

    for (final category in firstInstance.keys) {
      // Collect IDs from first instance for this category
      Set<int> commonIds = {for (final item in firstInstance[category]!) item.id};

      // Intersect with IDs from other instances
      for (final instance in instanceResults.skip(1)) {
        final categoryList = instance[category] ?? [];
        final ids = {for (final item in categoryList) item.id};
        commonIds = commonIds.intersection(ids);

        if (commonIds.isEmpty) break; // No possibilities left
      }

      // Pick the first item from the first instance using remaining IDs
      if (commonIds.isNotEmpty) {
        final firstList = firstInstance[category]!;
        final chosen = firstList.firstWhere((item) => commonIds.contains(item.id));
        output.add(chosen);
      }
    }

    return output;
  }
}
