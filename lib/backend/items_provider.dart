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

  Future<void> refresh() async {
    isLoading = true;
    notifyListeners();
    await _loadItems();
    isLoading = false;
    notifyListeners();
  }

  Future<void> _loadItems();

  Future<List<ClothingData>> referencedBy(int id);

  Future<int> referencedByCount(int id) async => (await referencedBy(id)).length;

  Future<void> deleteItems(List<int> ids);

  Future<void> deleteItem(int id) async {
    final ids = [id];
    await deleteItems(ids);
  }
}

class ActivityItemsProvider extends ItemsProvider {
  ActivityItemsProvider(super.db);

  @override
  Future<void> _loadItems() async {
    final result = await db.allActivities().get();
    names = result.map((el) => el.name).toList();
    itemList = result.map((el) => el.toJson()).toList();
  }

  @override
  Future<List<ClothingData>> referencedBy(int id) async {
    return await db.clothingWithActivity(id).get();
  }

  @override
  Future<void> deleteItems(List<int> ids) async {
    await db.deleteActivities(ids);
    await refresh();
  }
}

class CategoryItemsProvider extends ItemsProvider {
  CategoryItemsProvider(super.db);

  @override
  Future<void> _loadItems() async {
    final result = await db.allCategories().get();
    // TODO sorting vertically or alphabetically
    names = result.map((el) => el.name).toList();
    itemList = result.map((el) => el.toJson()).toList();
  }

  @override
  Future<List<ClothingData>> referencedBy(int id) async {
    return await db.clothingWithCategory(id).get();
  }

  @override
  Future<void> deleteItems(List<int> ids) async {
    await db.deleteCategories(ids);
    await refresh();
  }
}

class ClothingItemsProvider extends ItemsProvider {
  ClothingItemsProvider(super.db);

  @override
  Future<void> _loadItems() async {
    final result = await db.allClothingFull().get();
    itemList = result.map((e) {
      return {
        'id': e.id,
        'name': e.name,
        'min_temp': e.minTemp,
        'max_temp': e.maxTemp,
        'category': e.category,
        'activities': e.activities?.split(';').toList(),
      };
    }).toList();
  }

  @override
  Future<List<ClothingData>> referencedBy(int id) async {
    return [];
  }

  @override
  Future<void> deleteItems(List<int> ids) async {
    await db.deleteClothing(ids);
    await refresh();
  }
}
