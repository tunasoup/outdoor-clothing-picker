import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:outdoor_clothing_picker/backend/clothing_viewmodel.dart';
import 'package:outdoor_clothing_picker/backend/items_provider.dart';
import 'package:outdoor_clothing_picker/backend/theme.dart';
import 'package:outdoor_clothing_picker/backend/weather_service.dart';
import 'package:outdoor_clothing_picker/backend/weather_viewmodel.dart';
import 'package:outdoor_clothing_picker/database/database.dart';
import 'package:outdoor_clothing_picker/pages/home_page.dart';
import 'package:provider/provider.dart';

late AppDb db;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  db = AppDb();

  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();

  runApp(
    MultiProvider(
      providers: [
        Provider<AppDb>.value(value: db),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider(create: (context) => ActivityItemsProvider(db)),
        ChangeNotifierProvider(create: (context) => CategoryItemsProvider(db)),
        ChangeNotifierProvider(create: (context) => ClothingItemsProvider(db)),
        ChangeNotifierProvider(create: (_) => WeatherViewModel(WeatherService())),
        ChangeNotifierProxyProvider2<WeatherViewModel, ActivityItemsProvider, ClothingViewModel>(
          create: (_) => ClothingViewModel(db),
          update: (_, weatherVM, activityItemsProvider, clothingVM) {
            clothingVM!.setTemperature(temp: weatherVM.temperature);
            clothingVM.setDefaultActivity(activityItemsProvider.names);
            return clothingVM;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
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
