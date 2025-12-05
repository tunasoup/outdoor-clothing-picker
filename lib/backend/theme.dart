import 'package:flutter/material.dart';
import 'package:outdoor_clothing_picker/backend/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

// TODO: Custom theme
const seedColor = Colors.green;
ThemeData lightMode = ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: seedColor));
ThemeData darkMode = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.dark),
);

/// Provider for switching between light and dark mode.
class ThemeProvider with ChangeNotifier {
  // Load theme should be called before any getters.
  late bool _isDark;

  ThemeMode get themeMode {
    return _isDark ? ThemeMode.dark : ThemeMode.light;
  }

  bool get isDarkMode => _isDark;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(PrefKeys.darkMode);
    if (isDark == null) {
      await applySystemTheme();
    } else {
      _isDark = isDark;
    }
    notifyListeners();
  }

  Future<void> applySystemTheme() async {
    _isDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    await _saveTheme();
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    await _saveTheme();
    notifyListeners();
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.darkMode, _isDark);
  }
}
