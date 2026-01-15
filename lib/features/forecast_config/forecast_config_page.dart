import 'package:flutter/material.dart';
import 'package:outdoor_clothing_picker/core/configs/settings.dart';
import 'package:outdoor_clothing_picker/core/ui/ui_helpers.dart';
import 'package:provider/provider.dart';

import './forecast_configurator.dart';
import './forecast_config_viewmodel.dart';

// TODO: Add favorites
class ForecastConfigPage extends StatefulWidget {
  final ForecastConfigViewModel viewModel;

  const ForecastConfigPage({super.key, required this.viewModel});

  @override
  State<ForecastConfigPage> createState() => _ForecastConfigPageState();
}

class _ForecastConfigPageState extends State<ForecastConfigPage> {
  void _addConfig() {
    // Disable a possible config undo message
    ScaffoldMessenger.of(context).clearSnackBars();
    widget.viewModel.addConfig();
  }

  void _onDismissConfig(int index) {
    final action = widget.viewModel.removeConfig(index);
    showSnackBar(context: context, text: 'Forecast deleted', action: action);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLeftHanded = context.read<SettingsProvider>().isLeftHanded;
    final pos = isLeftHanded
        ? FloatingActionButtonLocation.startFloat
        : FloatingActionButtonLocation.endFloat;

    return Scaffold(
      floatingActionButtonLocation: pos,
      floatingActionButton: FloatingActionButton(
        // onPressed: _applyAndExit,
        onPressed: () => Navigator.pop(context),
        child: const Icon(Icons.check),
      ),
      appBar: AppBar(title: const Text('Choose Forecasts')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, _) {
            return widget.viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.viewModel.configsCount,
                    itemBuilder: (context, index) {
                      final isLast = index == widget.viewModel.configsCount - 1;
                      final config = widget.viewModel.configAt(index);
                      return Column(
                        children: [
                          Dismissible(
                            key: ObjectKey(config),
                            // Cannot delete if only one
                            direction: widget.viewModel.configsCount > 1
                                ? DismissDirection.endToStart
                                : DismissDirection.none,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              color: colorScheme.errorContainer,
                              child: Icon(
                                Icons.delete,
                                color: colorScheme.onErrorContainer,
                                size: 28,
                              ),
                            ),
                            onDismissed: (_) => _onDismissConfig(index),
                            child: ForecastConfigurator(config: config),
                          ),

                          // Include an Add button below the last item
                          if (isLast)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              // TODO: Add an animation
                              child: IconButton(
                                onPressed:
                                    widget.viewModel.configsCount < widget.viewModel.configsLimit
                                    ? _addConfig
                                    : null,
                                icon: const Icon(Icons.add, size: 28),
                                style: IconButton.styleFrom(
                                  backgroundColor: colorScheme.primaryContainer,
                                  foregroundColor: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  );
          },
        ),
      ),
    );
  }
}
