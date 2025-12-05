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
        ChangeNotifierProvider(create: (_) => ActivityItemsProvider(db)),
        ChangeNotifierProvider(create: (_) => CategoryItemsProvider(db)),
        ChangeNotifierProvider(create: (_) => ClothingItemsProvider(db)),
        ChangeNotifierProvider(create: (_) => WeatherViewModel(WeatherService())),
        ChangeNotifierProvider(
          create: (context) => ClothingViewModel(
            db,
            context.read<WeatherViewModel>(),
            context.read<ActivityItemsProvider>(),
            context.read<CategoryItemsProvider>(),
            context.read<ClothingItemsProvider>(),
          ),
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
      home: HomePage(),
      debugShowCheckedModeBanner: false,
      theme: lightMode,
      darkTheme: darkMode,
      themeMode: Provider.of<ThemeProvider>(context).themeMode,
    );
  }
}
