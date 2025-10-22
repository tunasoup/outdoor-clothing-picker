import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import 'package:outdoor_clothing_picker/database/database.dart';

class ActivityDialogController {
  final AppDb db;
  final List<String> availableActivities;

  ActivityDialogController(this.db, this.availableActivities);

  String? _name;
  final formKey = GlobalKey<FormState>();

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter a value';
    List<String> existingNames = availableActivities.map((el) => el.toLowerCase()).toList();
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

class ClothingDialogController {
  final AppDb db;

  ClothingDialogController(this.db);

  String? _name;
  int? _minTemp;
  int? _minTempVal;
  int? _maxTemp;
  String? _activity;
  String? _category;
  final formKey = GlobalKey<FormState>();

  String? validateName(String? value) {
    return value == null || value.trim().isEmpty ? 'Enter a value' : null;
  }

  String? validateMinTemp(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter a value';
    }
    _minTempVal = int.tryParse(value);
    if (_minTempVal == null) {
      return 'Enter a valid whole number';
    }
    return null;
  }

  String? validateMaxTemp(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter a value';
    }
    int? number = int.tryParse(value);
    if (number == null) {
      return 'Enter a valid whole number';
    } else if (_minTempVal != null && number < _minTempVal!) {
      return 'Must be ≥ Min Temp';
    }
    return null;
  }

  String? validateDropdown(String? value) {
    return value == null ? 'Select a value' : null;
  }

  void saveName(String? value) {
    _name = value?.trim();
  }

  void saveMinTemp(String? value) {
    _minTemp = int.parse(value!);
  }

  void saveMaxTemp(String? value) {
    _maxTemp = int.parse(value!);
  }

  void saveActivity(String? value) {
    _activity = value;
  }

  void saveCategory(String? value) {
    _category = value;
  }

  Future<bool> saveClothing() async {
    if (formKey.currentState?.validate() ?? false) {
      formKey.currentState?.save();
      await db
          .into(db.clothing)
          .insert(
            ClothingCompanion.insert(
              name: _name!,
              minTemp: _minTemp!,
              maxTemp: _maxTemp!,
              category: Value(_category!),
              activity: Value(_activity!),
            ),
          );
      return true;
    }
    return false;
  }
}

class CategoryDialogController {
  final AppDb db;
  final List<String> availableCategories;

  CategoryDialogController(this.db, this.availableCategories);

  String? _name;
  double? _normX;
  double? _normY;
  final formKey = GlobalKey<FormState>();

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter a value';
    if (availableCategories.contains(value.trim().toLowerCase())) {
      return 'This category already exists';
    }
    return null;
  }

  String? validateCoords(double? x, double? y) {
    if (x == null || y == null) return 'Select coordinates';
    return null;
  }

  void saveName(String? value) {
    _name = value?.trim();
  }

  void saveCoords(double? x, double? y) {
    _normX = x;
    _normY = y;
  }

  Future<bool> saveCategory() async {
    if (formKey.currentState?.validate() ?? false) {
      formKey.currentState?.save();
      await db
          .into(db.categories)
          .insert(CategoriesCompanion.insert(name: _name!, normX: _normX!, normY: _normY!));
      return true;
    }
    return false;
  }
}
