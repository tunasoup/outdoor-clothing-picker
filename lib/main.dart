import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:outdoor_clothing_picker/database/database.dart';
import 'package:outdoor_clothing_picker/pages/clothing_page.dart';
import 'package:outdoor_clothing_picker/pages/data_visualization_page.dart';

late AppDb db;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  db = AppDb();


  // Insert default data when not in release mode if the tables are empty
  if (kDebugMode) await insertDefaultDataIfNeeded(db);

  runApp(const MyApp());
}

/// Insert default data to [db] if the tables are empty.
Future<void> insertDefaultDataIfNeeded(AppDb db) async {
  // Check if tables are empty
  final clothingCount = await db.select(db.clothing).get().then((rows) => rows.length);
  final categoryCount = await db.select(db.categories).get().then((rows) => rows.length);
  final activityCount = await db.select(db.activities).get().then((rows) => rows.length);

  if (clothingCount == 0 && categoryCount == 0 && activityCount == 0) {
    await db.createDefaultCategories();
    await db.createDefaultActivities();
    await db.createDefaultClothing();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Outdoor Clothing Picker',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.green)),
      home: ClothingPage(title: 'Demo Home Page', db: db),
      routes: {
        '/clothing': (context) => ClothingPage(title: 'Demo Home Page', db: db),
        '/database': (context) => DataVisualizationPage(db: db),
      },
    );
  }
}
