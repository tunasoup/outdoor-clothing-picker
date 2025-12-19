import 'package:flutter/material.dart';
import 'package:outdoor_clothing_picker/core/utils/utils.dart';
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
  late String _apiKey;
  late bool _isDark;
  late bool _isLeftHanded;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([loadApiKey(prefs: prefs), loadTheme(prefs: prefs), loadHand(prefs: prefs)]);
  }

  String get apiKey => _apiKey;

  ThemeMode get themeMode {
    return _isDark ? ThemeMode.dark : ThemeMode.light;
  }

  bool get isDarkMode => _isDark;

  bool get isLeftHanded => _isLeftHanded;

  TextDirection get textDirection => isLeftHanded ? TextDirection.rtl : TextDirection.ltr;

  Future<void> saveApiKey({required String value}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.apiKeyOWM, value);
    _apiKey = value;
  }

  Future<void> loadApiKey({SharedPreferences? prefs}) async {
    prefs ??= await SharedPreferences.getInstance();
    _apiKey = prefs.getString(PrefKeys.apiKeyOWM) ?? '';
  }

  Future<void> loadTheme({SharedPreferences? prefs}) async {
    prefs ??= await SharedPreferences.getInstance();
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
    await prefs.setBool(PrefKeys.leftHanded, _isLeftHanded);
  }

  Future<void> loadHand({SharedPreferences? prefs}) async {
    prefs ??= await SharedPreferences.getInstance();
    _isLeftHanded = prefs.getBool(PrefKeys.leftHanded) ?? false;
  }

  Future<void> toggleHand() async {
    _isLeftHanded = !_isLeftHanded;
    await _saveHand();
    notifyListeners();
  }
}
