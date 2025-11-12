import 'package:flutter/material.dart';
import 'package:outdoor_clothing_picker/backend/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

const seedColor = Colors.green;
ThemeData lightMode = ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: seedColor));
ThemeData darkMode = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.dark),
);

/// Provider for switching between light and dark mode.
class ThemeProvider with ChangeNotifier {
  ThemeData _themeData = lightMode;

  ThemeData get themeData => _themeData;

  bool get isDarkMode => _themeData == darkMode;

  set themeData(ThemeData themeData) {
    _themeData = themeData;
    notifyListeners();
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(PrefKeys.darkMode) ?? false;
    _themeData = isDark ? darkMode : lightMode;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    final isCurrentlyDark = _themeData == darkMode;
    _themeData = isCurrentlyDark ? lightMode : darkMode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.darkMode, !isCurrentlyDark);
  }
}
