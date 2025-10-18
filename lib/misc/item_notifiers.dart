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
    items = result.map((el) => el.name).toList();
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

class CategoryItemsProvider extends ChangeNotifier {
  final AppDb db;

  List<String> names = [];

  CategoryItemsProvider(this.db) {
    _loadItems();
  }

  Future<void> _loadItems() async {
    final result = await db.allCategories().get();
    names = result.map((el) => el.name).toList();
    notifyListeners();
  }

  Future<void> refresh() => _loadItems();
}
