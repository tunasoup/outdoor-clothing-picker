import 'package:flutter/material.dart';
import 'package:outdoor_clothing_picker/database/database.dart';

enum DialogMode { add, edit, copy }

/// Responsible for modifying [db] via a dialog, and filling and validating the contents
/// of a form inside it.
abstract class DialogController {
  final AppDb db;
  final DialogMode mode;
  final Map<String, dynamic>? initialData;

  final formKey = GlobalKey<FormState>();
  late final int? _id;
  late final String? _initialName;

  DialogController({required this.db, required this.mode, this.initialData}) {
    if (mode != DialogMode.add && initialData?['id'] == null) {
      throw Exception(
        'Initial data needs to be provided with an existing id when using a '
        'other than add mode for a dialog controller.',
      );
    }
    _id = initialData?['id'];
    _initialName = initialData?['name'];
  }

  bool isBoxChecked = false;

  String getTitle();

  Future<bool> submitForm();

  String getCheckboxLabel() => '';

  void checkboxChanged(bool? newState) {
    isBoxChecked = newState!;
  }

  String? validateCheckbox(bool? value) => null;

  void saveCheckbox(bool? value) => {};
}

class ActivityDialogController extends DialogController {
  final List<String> availableActivities;

  ActivityDialogController({
    required super.db,
    required super.mode,
    super.initialData,
    required this.availableActivities,
  });

  String? _name;

  @override
  String getTitle() => switch (mode) {
    DialogMode.add => 'Add Activity',
    DialogMode.edit => 'Edit Activity \'$_initialName\'',
    DialogMode.copy => 'Copy Activity \'$_initialName\'',
  };

  String? getInitialName() => _initialName;

  String? validateName(String? value) {
    value = value?.trim();
    if (value == null || value.isEmpty) return 'Enter a value';
    if (value == _initialName) return 'Enter a new value';
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

  @override
  Future<bool> submitForm() async {
    if (formKey.currentState?.validate() ?? false) {
      formKey.currentState?.save();
      await switch (mode) {
        DialogMode.add => db.insertActivity(_name!),
        DialogMode.edit => db.updateActivity(_name!, _id!),
        DialogMode.copy => Future.value(),
      };
      return true;
    }
    return false;
  }

  @override
  String getCheckboxLabel() => switch (mode) {
    DialogMode.add => '',
    DialogMode.edit => 'Merge with an existing activity?',
    DialogMode.copy => 'Also duplicate referenced clothing?',
  };
}

class CategoryDialogController extends DialogController {
  final List<String> availableCategories;
  late final double? _initialNormX;
  late final double? _initialNormY;

  CategoryDialogController({
    required super.db,
    required super.mode,
    super.initialData,
    required this.availableCategories,
  }) : _initialNormX = initialData?['norm_x'],
       _initialNormY = initialData?['norm_y'];

  String? _name;
  double? _normX;
  double? _normY;

  @override
  String getTitle() => switch (mode) {
    DialogMode.add => 'Add Category',
    DialogMode.edit => 'Edit Category \'$_initialName\'',
    DialogMode.copy => 'Copy Category \'$_initialName\'',
  };

  String? getInitialName() => _initialName;

  Offset? getInitialCoords() =>
      _initialNormX != null && _initialNormY != null ? Offset(_initialNormX, _initialNormY) : null;

  String? validateName(String? value) {
    value = value?.trim();
    if (value == null || value.isEmpty) return 'Enter a value';
    // The only allowed duplicate value is a possible initial one
    if (value != _initialName && availableCategories.contains(value.toLowerCase())) {
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

  @override
  Future<bool> submitForm() async {
    if (formKey.currentState?.validate() ?? false) {
      formKey.currentState?.save();
      await switch (mode) {
        DialogMode.add => db.insertCategory(_name!, _normX!, _normY!),
        DialogMode.edit => db.updateCategory(_name!, _normX!, _normY!, _id),
        DialogMode.copy => Future.value(),
      };
      return true;
    }
    return false;
  }
}

class ClothingDialogController extends DialogController {
  late final int? _initialMinTemp;
  late final int? _initialMaxTemp;
  late final String? _initialActivity;
  late final String? _initialCategory;

  ClothingDialogController({required super.db, required super.mode, super.initialData})
    : _initialMinTemp = initialData?['min_temp'],
      _initialMaxTemp = initialData?['max_temp'],
      _initialActivity = initialData?['activity'],
      _initialCategory = initialData?['category'];

  String? _name;
  int? _minTemp;
  int? _minTempVal;
  int? _maxTemp;
  String? _activity;
  String? _category;

  @override
  String getTitle() => switch (mode) {
    DialogMode.add => 'Add Clothing Item',
    DialogMode.edit => 'Edit Clothing \'$_initialName\'',
    DialogMode.copy => 'Copy Clothing \'$_initialName\'',
  };

  String? getInitialName() => _initialName;

  int? getInitialMinTemp() => _initialMinTemp;

  int? getInitialMaxTemp() => _initialMaxTemp;

  String? getInitialActivity() => _initialActivity;

  String? getInitialCategory() => _initialCategory;

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

  @override
  Future<bool> submitForm() async {
    if (formKey.currentState?.validate() ?? false) {
      formKey.currentState?.save();
      await switch (mode) {
        DialogMode.add ||
        DialogMode.copy => db.insertClothing(_name!, _minTemp!, _maxTemp!, _category, _activity),
        DialogMode.edit => db.updateClothing(
          _name!,
          _minTemp!,
          _maxTemp!,
          _category,
          _activity,
          _id,
        ),
      };
      return true;
    }
    return false;
  }
}
