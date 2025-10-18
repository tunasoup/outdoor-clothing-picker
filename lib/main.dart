import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:outdoor_clothing_picker/database/database.dart';
import 'package:outdoor_clothing_picker/misc/clothing_viewmodel.dart';
import 'package:outdoor_clothing_picker/misc/item_notifiers.dart';
import 'package:outdoor_clothing_picker/misc/theme.dart';
import 'package:outdoor_clothing_picker/misc/weather_service.dart';
import 'package:outdoor_clothing_picker/misc/weather_viewmodel.dart';
import 'package:outdoor_clothing_picker/pages/home_page.dart';

late AppDb db;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  db = AppDb();
  // TODO: decide where to place and read api keys
  final String apiKey = 'api key here';

  // Insert default data when not in release mode if the tables are empty
  if (kDebugMode) await insertDefaultDataIfNeeded(db);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => ActivityItemsProvider(db)),
        ChangeNotifierProvider(create: (context) => CategoryItemsProvider(db)),
        ChangeNotifierProvider(create: (_) => WeatherViewModel(WeatherService(apiKey))),
        ChangeNotifierProxyProvider<WeatherViewModel, ClothingViewModel>(
          create: (_) => ClothingViewModel(db),
          update: (_, weatherVM, clothingVM) {
            clothingVM!.setTemperature(temp: weatherVM.temperature);
            return clothingVM;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
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
      theme: Provider.of<ThemeProvider>(context).themeData,
      home: HomePage(db: db),
      debugShowCheckedModeBanner: false,
    );
  }
}
