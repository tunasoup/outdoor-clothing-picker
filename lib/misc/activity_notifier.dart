import 'package:flutter/material.dart';

import 'package:outdoor_clothing_picker/database/database.dart';

class ActivityItemsProvider extends ChangeNotifier {
  final AppDb db;

  List<String> items = [];

  ActivityItemsProvider(this.db) {
    _loadItems();
  }

  Future<void> _loadItems() async {
    final result = await db.allActivities().get();
    items = result.map((c) => c.name).toList();
    notifyListeners();
  }

  // TODO: unused but needs a working replacement
  Future<String?> getFirstItem() async {
    if (items.isEmpty) {
      await _loadItems();
    }
    return items.isNotEmpty ? items.first : null;
  }

  Future<void> refresh() => _loadItems();
}

class ActivityDialogViewModel extends ChangeNotifier {
  final AppDb db;
  bool _isInitialized = false;
  late List<String> existingNames;

  ActivityDialogViewModel(this.db) {
    init();
  }

  String? _name;
  final formKey = GlobalKey<FormState>();

  Future<void> init() async {
    if (_isInitialized) return;

    final items = await db.allActivities().get();
    existingNames = items.map((el) => el.name.toLowerCase()).toList();
    _isInitialized = true;
  }

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter a value';
    if (existingNames.contains(value.trim().toLowerCase())) {
      return 'This activity already exists';
    }
    return null;
  }

  void saveName(String? value) {
    _name = value?.trim();
  }

  Future<bool> saveActivity() async {
    if (formKey.currentState?.validate() ?? false) {
      formKey.currentState?.save();
      await db.into(db.activities).insert(ActivitiesCompanion.insert(name: _name!));
      return true;
    }
    return false;
  }
}
