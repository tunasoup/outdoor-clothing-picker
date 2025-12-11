import 'package:flutter/material.dart';
import 'package:outdoor_clothing_picker/core/database/items_provider.dart';
import 'package:outdoor_clothing_picker/core/database/database.dart';

enum DialogMode { add, edit, copy }

/// Responsible for modifying [db] via a dialog, and filling and validating the contents
/// of a form inside it.
abstract class DialogViewModel {
  final AppDb db;
  final DialogMode mode;
  final Map<String, dynamic>? initialData;

  final formKey = GlobalKey<FormState>();
  late final int? _id;
  late final String? initialName;

  DialogViewModel({required this.db, required this.mode, this.initialData}) {
    _id = initialData?['id'];
    if (mode != DialogMode.add && _id == null) {
      throw Exception(
        'Initial data needs to be provided with an existing id when using '
        'other than \'add\' mode for a dialog controller.',
      );
    }
    initialName = initialData?['name'];
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

class ActivityDialogViewModel extends DialogViewModel {
  final ActivityItemsProvider activityProvider;
  final ClothingItemsProvider clothingProvider;
  late final List<String> availableActivities;

  ActivityDialogViewModel({
    required super.db,
    required super.mode,
    super.initialData,
    required this.activityProvider,
    required this.clothingProvider,
  }) : availableActivities = activityProvider.names;

  String? _name;

  @override
  String getTitle() => switch (mode) {
    DialogMode.add => 'Add Activity',
    DialogMode.edit => 'Edit Activity \'$initialName\'',
    DialogMode.copy => 'Copy Activity \'$initialName\'',
  };

  String? validateName(String? value) {
    // Never accept empty values
    value = value?.trim();
    if (value == null || value.isEmpty) return 'Enter a value';

    // Never accept case-sensitive initial value, but allow changing the case during edit
    bool isInitial = value.toLowerCase() == initialName?.toLowerCase();
    bool caseChange = isInitial && value != initialName;
    bool isMerging = mode == DialogMode.edit && isBoxChecked;
    if (isInitial && isMerging) return 'Choose a different existing activity for merging';
    // Allow case change when in edit mode but not merging
    if (mode == DialogMode.edit && caseChange) return null;
    if (isInitial) return 'Enter a new value';

    // Avoid duplicates, except require it when merging
    List<String> existingNames = availableActivities.map((el) => el.toLowerCase()).toList();
    bool isDuplicate = existingNames.contains(value.toLowerCase());
    if (isMerging && !isDuplicate) return 'Choose an existing activity for merging';
    if (isDuplicate && !isMerging) return 'This activity already exists';

    return null;
  }

  void saveName(String? value) {
    _name = value?.trim();
  }

  @override
  String getCheckboxLabel() => switch (mode) {
    DialogMode.add => '',
    DialogMode.edit => 'Merge with an existing activity?',
    DialogMode.copy => 'Also add activity to referenced clothing?',
  };

  Future<void> _handleEdit() async {
    if (isBoxChecked) {
      int targetId = (await db.activityFromName(_name!).getSingle()).id;
      await db.changeClothingActivity(targetId, _id!);
      await db.deleteActivities([_id]);
    } else {
      await db.updateActivity(_name!, _id!);
    }
    await clothingProvider.refresh();
  }

  Future<void> _handleCopy() async {
    int actId = await db.insertActivity(_name!);
    if (isBoxChecked) {
      await db.duplicateClothingActivity(actId, _id!);
      await clothingProvider.refresh();
    }
  }

  @override
  Future<bool> submitForm() async {
    if (formKey.currentState?.validate() ?? false) {
      formKey.currentState?.save();
      await switch (mode) {
        DialogMode.add => db.insertActivity(_name!),
        DialogMode.edit => _handleEdit(),
        DialogMode.copy => _handleCopy(),
      };
      await activityProvider.refresh();
      return true;
    }
    return false;
  }
}

class CategoryDialogViewModel extends DialogViewModel {
  final CategoryItemsProvider categoryProvider;
  final ClothingItemsProvider clothingProvider;
  late final List<String> availableCategories;
  late final double? _initialNormX;
  late final double? _initialNormY;

  CategoryDialogViewModel({
    required super.db,
    required super.mode,
    super.initialData,
    required this.categoryProvider,
    required this.clothingProvider,
  }) : availableCategories = categoryProvider.names,
       _initialNormX = initialData?['norm_x'],
       _initialNormY = initialData?['norm_y'];

  String? _name;
  double? _normX;
  double? _normY;

  @override
  String getTitle() => switch (mode) {
    DialogMode.add => 'Add Category',
    DialogMode.edit => 'Edit Category \'$initialName\'',
    DialogMode.copy => 'Copy Category \'$initialName\'',
  };

  Offset? getInitialCoords() =>
      _initialNormX != null && _initialNormY != null ? Offset(_initialNormX, _initialNormY) : null;

  String? validateName(String? value) {
    // Never accept empty values
    value = value?.trim();
    if (value == null || value.isEmpty) return 'Enter a value';

    // Initial value only acceptable when other editing is performed
    bool isInitial = value.toLowerCase() == initialName?.toLowerCase();
    bool isMerging = mode == DialogMode.edit && isBoxChecked;
    if (isInitial && mode != DialogMode.edit) return 'Enter a new value';
    if (isInitial && isMerging) return 'Choose a different existing category for merging';

    // Duplicate handling
    List<String> existingNames = availableCategories.map((el) => el.toLowerCase()).toList();
    bool isDuplicate = existingNames.contains(value.toLowerCase());
    // Avoid duplicate when not editing
    if (isDuplicate && mode != DialogMode.edit) return 'This category name already exists';
    // Require duplicate when merging
    if (isMerging && !isDuplicate) return 'Choose an existing activity for merging';
    // Avoid duplicate when editing but not merging
    if (isDuplicate && !isInitial && !isMerging) return 'This category name already exists';

    return null;
  }

  String? validateCoords(double? x, double? y) {
    // Coordinates are ignored when merging
    if (mode == DialogMode.edit && isBoxChecked) return null;
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
  String getCheckboxLabel() => switch (mode) {
    DialogMode.add => '',
    DialogMode.edit => 'Merge with an existing category?',
    DialogMode.copy => 'Also duplicate referenced clothing?',
  };

  Future<void> _handleEdit() async {
    if (isBoxChecked) {
      // The data of _initialName is used, current form coordinates are ignored
      int targetId = (await db.categoryFromName(_name!).getSingle()).id;
      await db.changeClothingCategory(targetId, _id!);
      await db.deleteCategories([_id]);
    } else {
      await db.updateCategory(_name!, _normX!, _normY!, _id!);
    }
    await clothingProvider.refresh();
  }

  Future<void> _handleCopy() async {
    await db.insertCategory(_name!, _normX!, _normY!);
    if (isBoxChecked) {
      int targetId = (await db.categoryFromName(_name!).getSingle()).id;
      await db.duplicateCategoryClothing(targetId, _id!);
      await db.duplicateCategoryClothingActivities(targetId, _id);
    }
    await clothingProvider.refresh();
  }

  @override
  Future<bool> submitForm() async {
    if (formKey.currentState?.validate() ?? false) {
      formKey.currentState?.save();
      await switch (mode) {
        DialogMode.add => db.insertCategory(_name!, _normX!, _normY!),
        DialogMode.edit => _handleEdit(),
        DialogMode.copy => _handleCopy(),
      };
      await categoryProvider.refresh();
      return true;
    }
    return false;
  }
}

class ClothingDialogViewModel extends DialogViewModel {
  final ClothingItemsProvider clothingProvider;
  late final int? initialMinTemp;
  late final int? initialMaxTemp;
  late final List<String>? initialActivities;
  late final String? initialCategoryName;

  ClothingDialogViewModel({
    required super.db,
    required super.mode,
    super.initialData,
    required this.clothingProvider,
  }) : initialMinTemp = initialData?['min_temp'],
       initialMaxTemp = initialData?['max_temp'],
       initialActivities = initialData?['activities'],
       initialCategoryName = initialData?['category'];

  String? _name;
  int? _minTemp;
  int? _minTempVal;
  int? _maxTemp;
  String? _categoryName;
  List<String>? _activities;

  @override
  String getTitle() => switch (mode) {
    DialogMode.add => 'Add Clothing Item',
    DialogMode.edit => 'Edit Clothing \'$initialName\'',
    DialogMode.copy => 'Copy Clothing \'$initialName\'',
  };

  String? validateName(String? value) {
    return value == null || value.trim().isEmpty ? 'Enter a value' : null;
  }

  String? validateMinTemp(String? value) {
    _minTempVal = value != null ? int.tryParse(value) : null;
    if (value == null || value.isEmpty) return null;
    if (_minTempVal == null) {
      return 'Enter a whole number or leave empty';
    }
    return null;
  }

  String? validateMaxTemp(String? value) {
    if (value == null || value.isEmpty) return null;
    int? number = int.tryParse(value);
    if (number == null) {
      return 'Enter a whole number or leave empty';
    } else if (_minTempVal != null && number < _minTempVal!) {
      return 'Must be ≥ Min Temperature';
    }
    return null;
  }

  String? validateDropdown(String? value) {
    // Category can be null, UI assumed to only include existing options
    return null;
  }

  String? validateMultiselect(List<String>? values) {
    // Activities can be null, UI assumed to only include existing options
    return null;
  }

  void saveName(String? value) {
    _name = value?.trim();
  }

  void saveMinTemp(String? value) {
    // Need to tryParse as input is an empty string by default
    _minTemp = value != null ? int.tryParse(value) : null;
  }

  void saveMaxTemp(String? value) {
    _maxTemp = value != null ? int.tryParse(value) : null;
  }

  void saveActivities(List<String>? values) {
    _activities = values;
  }

  void saveCategory(String? value) {
    _categoryName = value;
  }

  Future<void> _handleNew(int? categoryID) async {
    final clothingID = await db.insertClothing(_name!, _minTemp, _maxTemp, categoryID);
    if (_activities != initialActivities) {
      await changeClothingActivities(db, clothingID, _activities, initialActivities);
    }
  }

  Future<void> _handleEdit(int? categoryID) async {
    final hasChanged =
        (_name != initialName ||
        _minTemp != initialMinTemp ||
        _maxTemp != initialMaxTemp ||
        _categoryName != initialCategoryName);
    if (hasChanged) await db.updateClothing(_name!, _minTemp, _maxTemp, categoryID, _id!);
    if (_activities != initialActivities) {
      await changeClothingActivities(db, _id!, _activities, initialActivities);
    }
  }

  @override
  Future<bool> submitForm() async {
    if (formKey.currentState?.validate() ?? false) {
      formKey.currentState?.save();
      final int? categoryID = await getCategoryID(db, _categoryName);

      switch (mode) {
        case DialogMode.add:
        case DialogMode.copy:
          await _handleNew(categoryID);
          break;
        case DialogMode.edit:
          await _handleEdit(categoryID);
          break;
      }
      await clothingProvider.refresh();
      return true;
    }
    return false;
  }
}

Future<int?> getCategoryID(AppDb db, String? categoryName) async {
  return categoryName == null
      ? null
      : (await db.categoryFromName(categoryName).getSingleOrNull())?.id;
}

/// Change the clothing activity references for [clothingID], adding those activities which are
/// in [newActivities] but not in [oldActivities], and removing in the opposite case.
Future<void> changeClothingActivities(
  AppDb db,
  int clothingID,
  List<String>? newActivities,
  List<String>? oldActivities,
) async {
  final toAdd = (newActivities ?? []).where((e) => !(oldActivities ?? []).contains(e)).toList();
  final toRemove = (oldActivities ?? []).where((e) => !(newActivities ?? []).contains(e)).toList();
  for (final act in toAdd) {
    final actID = (await db.activityFromName(act).getSingle()).id;
    await db.insertClothingActivity(clothingID, actID);
  }
  for (final act in toRemove) {
    final actID = (await db.activityFromName(act).getSingle()).id;
    await db.deleteClothingActivity(clothingID, actID);
  }
}
