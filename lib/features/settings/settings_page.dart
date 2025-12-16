import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:outdoor_clothing_picker/core/ui/app_page.dart';
import 'package:outdoor_clothing_picker/core/ui/ui_helpers.dart';
import 'package:outdoor_clothing_picker/core/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './settings_viewmodel.dart';

class SettingsPage extends AppPage {
  final SettingsViewModel viewModel;

  const SettingsPage({super.key, super.bottomNavigationBar, required this.viewModel});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

// TODO: Localization (language, units, time format)
// TODO: Data import and export
class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await Future.wait([_loadApiKey(prefs)]);

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadApiKey(SharedPreferences prefs) async {
    final savedKey = prefs.getString(PrefKeys.apiKeyOWM);
    _controller.text = savedKey ?? '';
  }

  Future<void> _saveApiKey(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.apiKeyOWM, value);
  }

  Widget _buildAPIKeyBox() {
    return TextField(
      controller: _controller,
      decoration: const InputDecoration(
        labelText: 'OpenWeatherMap API Key',
        border: OutlineInputBorder(),
      ),
      onChanged: _saveApiKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      ),
      bottomNavigationBar: widget.bottomNavigationBar,
      body: ListenableBuilder(listenable: widget.viewModel, builder: (context, _) {
        return widget.viewModel.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildAPIKeyBox(),
            ThemeSelectorTile(viewModel: widget.viewModel),
            HandLayoutTile(viewModel: widget.viewModel),
          ],
        );
      }
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class ThemeSelectorTile extends StatelessWidget {
  final SettingsViewModel viewModel;

  const ThemeSelectorTile({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = viewModel.isDarkMode;

    return ListTile(
      leading: Icon(
        isDarkMode ? Icons.dark_mode : Icons.light_mode,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(viewModel.themeText),
      subtitle: Text(viewModel.themeDescription),
      trailing: Switch.adaptive(
        value: isDarkMode,
        onChanged: (_) async {
          await viewModel.toggleTheme();
        },
      ),
      // Make the whole tile tappable
      onTap: () async {
        await viewModel.toggleTheme();
      },
    );
  }
}

class HandLayoutTile extends StatelessWidget {
  final SettingsViewModel viewModel;

  const HandLayoutTile({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final isLeftHanded = viewModel.isLeftHanded;

    return ListTile(
      leading: Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(isLeftHanded ? math.pi : 0),
        child: Icon(Icons.back_hand, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(viewModel.layoutText),
      subtitle: Text(viewModel.layoutDescription),
      trailing: Switch.adaptive(
        value: isLeftHanded,
        onChanged: (_) async {
          await errorWrapper(context, () async {
            await viewModel.toggleHand();
          });
        },
      ),
      // Make the whole tile tappable
      onTap: () async {
        await errorWrapper(context, () async {
          await viewModel.toggleHand();
        });
      },
    );
  }
}
