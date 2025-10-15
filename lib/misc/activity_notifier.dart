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

  Future<String?> getFirstItem() async {
    if (items.isEmpty) {
      await _loadItems();
    }
    return items.isNotEmpty ? items.first : null;
  }

  Future<void> refresh() => _loadItems();
}
