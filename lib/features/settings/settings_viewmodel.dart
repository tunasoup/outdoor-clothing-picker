import 'package:flutter/foundation.dart';

import 'package:outdoor_clothing_picker/core/configs/settings.dart';

class SettingsViewModel extends ChangeNotifier {
  final SettingsProvider _settingsRepository;

  SettingsViewModel({
    required SettingsProvider settingsRepository
}) : _settingsRepository = settingsRepository;

  // TODO: Add API setting, add initialization

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool get isDarkMode => _settingsRepository.isDarkMode;

  String get themeText => 'Theme';

  String get themeDescription => isDarkMode ? 'Dark mode' : 'Light mode';

  Future<void> toggleTheme() async {
    await _runWithLoading(_settingsRepository.toggleTheme);
  }

  bool get isLeftHanded => _settingsRepository.isLeftHanded;

  String get layoutText => 'Hand Layout';
  String get layoutDescription => isLeftHanded ? 'Left-handed' : 'Right-handed';

  Future<void> toggleHand() async {
    await _runWithLoading(_settingsRepository.toggleHand);
  }

  Future<void> _runWithLoading(Future<void> Function() command) async {
    _isLoading = true;
    notifyListeners();
    try {
      await command();
    } catch (e) {
      rethrow;
    } finally {
      // Theme toggle causes the whole MaterialApp to be rebuild, including this viewModel,
      // hence this part may not do anything
      _isLoading = false;
      notifyListeners();
    }
  }

}