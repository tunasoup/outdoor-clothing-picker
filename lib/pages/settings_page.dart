import 'package:flutter/material.dart';
import 'package:outdoor_clothing_picker/backend/theme.dart';
import 'package:outdoor_clothing_picker/backend/utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [_buildAPIKeyBox(), const ThemeSelectorTile()],
            ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class ThemeSelectorTile extends StatelessWidget {
  const ThemeSelectorTile({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = themeProvider.isDarkMode;

    return ListTile(
      leading: Icon(
        isDarkMode ? Icons.dark_mode : Icons.light_mode,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: const Text('Theme'),
      subtitle: Text(isDarkMode ? 'Dark mode' : 'Light mode'),
      trailing: Switch.adaptive(
        value: isDarkMode,
        onChanged: (_) async {
          await Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
        },
      ),
      onTap: () async {
        await Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
      },
    );
  }
}
