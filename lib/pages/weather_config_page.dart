import 'package:flutter/material.dart';
import 'package:outdoor_clothing_picker/backend/forecast_config.dart';
import 'package:outdoor_clothing_picker/widgets/forecast_configurator.dart';
import 'package:outdoor_clothing_picker/widgets/utils.dart';

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
    showSnackBar(context: context, text: 'Forecast deleted', action: action, seconds: 3);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Forecasts'),
        actions: [TextButton(onPressed: _applyAndExit, child: const Text('Apply'))],
      ),

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
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white, size: 28),
                ),
                onDismissed: (_) => _onDismissConfig(index),
                child: ForecastConfigurator(config: configs[index]),
              ),

              if (isLast && configs.length < 4)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ElevatedButton.icon(
                    onPressed: _addConfig,
                    icon: const Icon(Icons.add),
                    label: const Text('Add another forecast'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
