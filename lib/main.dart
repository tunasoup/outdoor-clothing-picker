import 'package:flutter/material.dart';
import 'package:outdoor_clothing_picker/core/configs/settings.dart';
import 'package:outdoor_clothing_picker/core/database/database.dart';
import 'package:outdoor_clothing_picker/core/database/items_provider.dart';
import 'package:outdoor_clothing_picker/features/clother/clothing_viewmodel.dart';
import 'package:outdoor_clothing_picker/features/clother/weather_service.dart';
import 'package:outdoor_clothing_picker/features/clother/weather_viewmodel.dart';
import 'package:outdoor_clothing_picker/home_page.dart';
import 'package:provider/provider.dart';

late AppDb db;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  db = AppDb();

  final settingsProvider = SettingsProvider();
  await settingsProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        Provider<AppDb>.value(value: db),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
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
    return Selector<SettingsProvider, ThemeMode>(
      selector: (_, provider) => provider.themeMode,
      builder: (_, themeMode, _) {
        return MaterialApp(
          title: 'Outdoor Clothing Picker',
          home: HomePage(),
          debugShowCheckedModeBanner: false,
          theme: lightMode,
          darkTheme: darkMode,
          themeMode: themeMode,
        );
      },
    );
  }
}
