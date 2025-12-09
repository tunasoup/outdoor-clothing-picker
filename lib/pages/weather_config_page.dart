import 'package:flutter/material.dart';
import 'package:outdoor_clothing_picker/backend/forecast_config.dart';
import 'package:outdoor_clothing_picker/backend/settings.dart';
import 'package:outdoor_clothing_picker/widgets/forecast_configurator.dart';
import 'package:outdoor_clothing_picker/widgets/utils.dart';
import 'package:provider/provider.dart';

// TODO: Add favorites
class WeatherConfigPage extends StatefulWidget {
  final List<ForecastConfig>? initialConfigs;

  const WeatherConfigPage({super.key, this.initialConfigs});

  @override
  State<WeatherConfigPage> createState() => _WeatherConfigPageState();
}

class _WeatherConfigPageState extends State<WeatherConfigPage> {
  late List<ForecastConfig> configs;

  @override
  void initState() {
    super.initState();
    configs = [];
    if (widget.initialConfigs != null) {
      configs = widget.initialConfigs!;
    } else {
      _loadConfigs();
    }
  }

  Future<void> _loadConfigs() async {
    final loadedConfigs = await loadForecastConfigs();
    setState(() {
      configs = loadedConfigs;
    });
  }

  void _addConfig() {
    // Disable a possible config undo message
    ScaffoldMessenger.of(context).clearSnackBars();
    final lastLocation = configs.isNotEmpty ? configs.last.location : '';

    if (configs.length < 4) {
      setState(() => configs.add(ForecastConfig(location: lastLocation)));
    }
  }

  void _removeConfig(int index) {
    setState(() => configs.removeAt(index));
  }

  void _applyAndExit() {
    Navigator.pop(context, configs);
  }

  void _onDismissConfig(int index) {
    final removedConfig = configs[index];
    final removedIndex = index;
    _removeConfig(index);

    final action = SnackBarAction(
      label: 'UNDO',
      onPressed: () {
        setState(() {
          configs.insert(removedIndex, removedConfig);
        });
      },
    );
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
        onPressed: _applyAndExit,
        child: const Icon(Icons.check),
      ),
      appBar: AppBar(title: const Text('Choose Forecasts')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: configs.length,
        itemBuilder: (context, index) {
          final isLast = index == configs.length - 1;
          return Column(
            children: [
              Dismissible(
                key: ObjectKey(configs[index]),
                direction: configs.length > 1
                    ? DismissDirection.endToStart
                    : DismissDirection.none,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: colorScheme.errorContainer,
                  child: Icon(Icons.delete, color: colorScheme.onErrorContainer, size: 28),
                ),
                onDismissed: (_) => _onDismissConfig(index),
                child: ForecastConfigurator(config: configs[index]),
              ),

              if (isLast)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  // TODO: Add an animation
                  child: IconButton(
                    onPressed: configs.length < 4 ? _addConfig : null,
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
      ),
    );
  }
}
