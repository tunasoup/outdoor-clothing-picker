import 'package:flutter/material.dart';
import 'package:outdoor_clothing_picker/database/database.dart';

/// Define classes responsible for providing and maintaining each main
/// database table.
abstract class ItemsProvider extends ChangeNotifier {
  final AppDb db;

  ItemsProvider(this.db) {
    refresh();
  }

  bool isLoading = true;

  List<Map<String, dynamic>> itemList = [];
  List<String> names = [];

  String get tableName;

  Future<void> refresh() async {
    isLoading = true;
    notifyListeners();
    await _loadItems();
    isLoading = false;
    notifyListeners();
  }

  Future<void> _loadItems();

  Future<List<ClothingData>> referencedBy(Map<String, dynamic> data);

  Future<int> referencedByCount(Map<String, dynamic> data) async =>
      (await referencedBy(data)).length;

  Future<void> deleteItem(Map<String, dynamic> data);
}

class ActivityItemsProvider extends ItemsProvider {
  ActivityItemsProvider(super.db);

  @override
  String get tableName => "Activities";

  @override
  Future<void> _loadItems() async {
    final result = await db.allActivities().get();
    names = result.map((el) => el.name).toList();
    itemList = result.map((el) => el.toJson()).toList();
  }

  @override
  Future<List<ClothingData>> referencedBy(Map<String, dynamic> data) async {
    String name = data['name'];
    return await db.clothingWithActivity(name).get();
  }

  @override
  Future<void> deleteItem(Map<String, dynamic> data) async {
    int id = data['id'];
    await db.deleteActivity(id);
    await refresh();
  }
}

class CategoryItemsProvider extends ItemsProvider {
  CategoryItemsProvider(super.db);

  @override
  String get tableName => "Categories";

  @override
  Future<void> _loadItems() async {
    final result = await db.allCategories().get();
    names = result.map((el) => el.name).toList();
    itemList = result.map((el) => el.toJson()).toList();
  }

  @override
  Future<List<ClothingData>> referencedBy(Map<String, dynamic> data) async {
    String name = data['name'];
    return await db.clothingWithCategory(name).get();
  }

  @override
  Future<void> deleteItem(Map<String, dynamic> data) async {
    int id = data['id'];
    await db.deleteCategory(id);
    await refresh();
  }
}

class ClothingItemsProvider extends ItemsProvider {
  ClothingItemsProvider(super.db);

  @override
  String get tableName => "Clothing";

  @override
  Future<void> _loadItems() async {
    final result = await db.allClothing().get();
    itemList = result.map((el) => el.toJson()).toList();
  }

  @override
  Future<List<ClothingData>> referencedBy(Map<String, dynamic> data) async {
    return [];
  }

  @override
  Future<void> deleteItem(Map<String, dynamic> data) async {
    int id = data['id'];
    await db.deleteClothing(id);
    await refresh();
  }
}
