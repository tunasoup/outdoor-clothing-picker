import 'package:flutter/material.dart';
import 'package:outdoor_clothing_picker/backend/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

// TODO: Custom theme
const seedColor = Colors.green;
ThemeData lightMode = ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: seedColor));
ThemeData darkMode = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.dark),
);

/// Provider for adjusting user settings.
class SettingsProvider with ChangeNotifier {
  // initialize should be called before any getters.
  late bool _isDark;
  late bool _isLeftHanded;

  Future<void> initialize() async {
    await Future.wait([loadTheme(), loadHand()]);
  }

  ThemeMode get themeMode {
    return _isDark ? ThemeMode.dark : ThemeMode.light;
  }

  bool get isDarkMode => _isDark;

  bool get isLeftHanded => _isLeftHanded;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(PrefKeys.darkMode);
    if (isDark == null) {
      await applySystemTheme();
    } else {
      _isDark = isDark;
    }
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

  Future<void> _saveHand() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.darkMode, _isLeftHanded);
  }

  Future<void> loadHand() async {
    final prefs = await SharedPreferences.getInstance();
    _isLeftHanded = prefs.getBool(PrefKeys.leftHanded) ?? false;
  }

  Future<void> toggleHand() async {
    _isLeftHanded = !_isLeftHanded;
    await _saveHand();
    notifyListeners();
  }
}
