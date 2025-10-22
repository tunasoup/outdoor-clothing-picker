import 'package:flutter/material.dart';
import 'package:outdoor_clothing_picker/database/database.dart';

abstract class ItemsProvider extends ChangeNotifier {
  final AppDb db;

  ItemsProvider(this.db);

  Future<List<ClothingData>> referencedBy(Map<String, dynamic> data);

  Future<int> referencedByCount(Map<String, dynamic> data) async {
    List<ClothingData> a = await referencedBy(data);
    return a.length;
  }

  Future<void> deleteItem(Map<String, dynamic> data);
}

class ActivityItemsProvider extends ItemsProvider {
  ActivityItemsProvider(super.db) {
    _loadItems();
  }

  List<String> items = [];

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

  @override
  Future<List<ClothingData>> referencedBy(Map<String, dynamic> data) async {
    String name = data['name'];
    return await db.clothingWithActivity(name).get();
  }

  @override
  Future<void> deleteItem(Map<String, dynamic> data) async {
    String name = data['name'];
    await db.deleteActivity(name);
    // _loadItems();
  }
}

class CategoryItemsProvider extends ItemsProvider {
  CategoryItemsProvider(super.db) {
    _loadItems();
  }

  List<String> names = [];

  Future<void> _loadItems() async {
    final result = await db.allCategories().get();
    names = result.map((el) => el.name).toList();
    notifyListeners();
  }

  Future<void> refresh() => _loadItems();

  @override
  Future<List<ClothingData>> referencedBy(Map<String, dynamic> data) async {
    String name = data['name'];
    return await db.clothingWithCategory(name).get();
  }

  @override
  Future<void> deleteItem(Map<String, dynamic> data) async {
    String name = data['name'];
    await db.deleteCategory(name);
  }
}

class ClothingItemsProvider extends ItemsProvider {
  ClothingItemsProvider(super.db);

  @override
  Future<List<ClothingData>> referencedBy(Map<String, dynamic> data) async {
    return [];
  }

  @override
  Future<void> deleteItem(Map<String, dynamic> data) async {
    int id = data['id'];
    await db.deleteClothing(id);
  }
}
