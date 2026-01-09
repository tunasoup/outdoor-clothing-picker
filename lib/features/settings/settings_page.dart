import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:outdoor_clothing_picker/core/ui/ui_helpers.dart';

import './settings_viewmodel.dart';

class SettingsPage extends StatelessWidget {
  final SettingsViewModel viewModel;

  const SettingsPage({super.key, required this.viewModel});

  // TODO: Localization (language, units, time format)
  // TODO: Data import and export

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      ),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          return viewModel.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ApiKeyBox(viewModel: viewModel),
                    ThemeSelectorTile(viewModel: viewModel),
                    HandLayoutTile(viewModel: viewModel),
                  ],
                );
        },
      ),
    );
  }
}

class ApiKeyBox extends StatefulWidget {
  final SettingsViewModel viewModel;

  const ApiKeyBox({super.key, required this.viewModel});

  @override
  State<ApiKeyBox> createState() => _ApiKeyBoxState();
}

class _ApiKeyBoxState extends State<ApiKeyBox> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.viewModel.apiKey);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: widget.viewModel.apiLabel,
        border: OutlineInputBorder(),
      ),
      onChanged: widget.viewModel.saveApiKey,
    );
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
