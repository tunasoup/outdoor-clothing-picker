import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:outdoor_clothing_picker/database/database.dart';

class ActivityDialogController {
  final AppDb db;
  final List<String> availableActivities;
  final Map<String, dynamic>? editableData;
  late final bool editMode;
  late final int? _id;
  late final String? _oldName;

  ActivityDialogController(this.db, this.availableActivities, [this.editableData])
    : editMode = editableData != null,
      _id = editableData?['id'],
      _oldName = editableData?['name'];

  String? _name;
  final formKey = GlobalKey<FormState>();

  String getTitle() => editMode ? 'Edit Activity \'$_oldName\'' : 'Add Activity';

  String? getInitialName() => _oldName;

  String? validateName(String? value) {
    value = value?.trim();
    if (value == null || value.isEmpty) return 'Enter a value';
    if (value == _oldName) return 'Enter a new value';
    // TODO: option to merge if a duplicate name given (i.e. delete and change clothing reference)
    List<String> existingNames = availableActivities.map((el) => el.toLowerCase()).toList();
    if (existingNames.contains(value.toLowerCase())) {
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
      // TODO: use items provider?
      if (editMode) {
        await db.updateActivity(_name!, _id!);
      } else {
        await db.into(db.activities).insert(ActivitiesCompanion.insert(name: _name!));
      }
      return true;
    }
    return false;
  }
}

class CategoryDialogController {
  final AppDb db;
  final List<String> availableCategories;
  final Map<String, dynamic>? editableData;
  late final bool editMode;
  late final int? _id;
  late final String? _oldName;
  late final double? _oldNormX;
  late final double? _oldNormY;

  CategoryDialogController(this.db, this.availableCategories, [this.editableData])
    : editMode = editableData != null,
      _id = editableData?['id'],
      _oldName = editableData?['name'],
      _oldNormX = editableData?['norm_x'],
      _oldNormY = editableData?['norm_y'];

  String? _name;
  double? _normX;
  double? _normY;
  final formKey = GlobalKey<FormState>();

  String getTitle() => editMode ? 'Edit Category \'$_oldName\'' : 'Add Category';

  String? getInitialName() => _oldName;

  Offset? getInitialCoords() =>
      _oldNormX != null && _oldNormY != null ? Offset(_oldNormX, _oldNormY) : null;

  String? validateName(String? value) {
    value = value?.trim();
    if (value == null || value.isEmpty) return 'Enter a value';
    // The only allowed duplicate value is a possible old one
    if (value != _oldName && availableCategories.contains(value.toLowerCase())) {
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
      if (editMode) {
        await db.updateCategory(_name!, _normX!, _normY!, _id);
      } else {
        await db
            .into(db.categories)
            .insert(CategoriesCompanion.insert(name: _name!, normX: _normX!, normY: _normY!));
      }
      return true;
    }
    return false;
  }
}

class ClothingDialogController {
  final AppDb db;
  final Map<String, dynamic>? editableData;
  late final bool editMode;
  late final int? _id;
  late final String? _oldName;
  late final int? _oldMinTemp;
  late final int? _oldMaxTemp;
  late final String? _oldActivity;
  late final String? _oldCategory;

  ClothingDialogController(this.db, [this.editableData])
    : editMode = editableData != null,
      _id = editableData?['id'],
      _oldName = editableData?['name'],
      _oldMinTemp = editableData?['min_temp'],
      _oldMaxTemp = editableData?['max_temp'],
      _oldActivity = editableData?['activity'],
      _oldCategory = editableData?['category'];

  String? _name;
  int? _minTemp;
  int? _minTempVal;
  int? _maxTemp;
  String? _activity;
  String? _category;
  final formKey = GlobalKey<FormState>();

  String getTitle() => editMode ? 'Edit Clothing \'$_oldName\'' : 'Add Clothing Item';

  String? getInitialName() => _oldName;

  int? getInitialMinTemp() => _oldMinTemp;

  int? getInitialMaxTemp() => _oldMaxTemp;

  String? getInitialActivity() => _oldActivity;

  String? getInitialCategory() => _oldCategory;

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
      if (editMode) {
        await db.updateClothing(_name!, _minTemp!, _maxTemp!, _category, _activity, _id);
      } else {
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
      }
      return true;
    }
    return false;
  }
}
