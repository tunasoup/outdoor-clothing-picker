import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:outdoor_clothing_picker/backend/forecast_config.dart';
import 'package:outdoor_clothing_picker/backend/utils.dart';
import 'package:outdoor_clothing_picker/widgets/forecast_configurator.dart';
import 'package:shared_preferences/shared_preferences.dart';

// TODO: use the output values to query forecasts
// TODO: Change date to offset from today
// TODO: Add favorites
class WeatherConfigPage extends StatefulWidget {
  const WeatherConfigPage({super.key});

  @override
  State<WeatherConfigPage> createState() => _WeatherConfigPageState();
}

class _WeatherConfigPageState extends State<WeatherConfigPage> {
  late List<ForecastConfig> configs;

  @override
  void initState() {
    super.initState();
    configs = [];
    _loadForecasts();
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
    _saveForecastConfigs();
    Navigator.pop(context, configs);
  }

  void _onDismissConfig(int index) {
    final removedConfig = configs[index];
    final removedIndex = index;
    _removeConfig(index);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Forecast deleted"),
        action: SnackBarAction(
          label: "UNDO",
          onPressed: () {
            setState(() {
              configs.insert(removedIndex, removedConfig);
            });
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _saveForecastConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = configs.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(PrefKeys.forecastConfigs, jsonList);
  }

  Future<void> _loadForecasts() async {
    final prefs = await SharedPreferences.getInstance();
    final savedList = prefs.getStringList(PrefKeys.forecastConfigs);
    setState(() {
      if (savedList != null && savedList.isNotEmpty) {
        configs = savedList.map((e) => ForecastConfig.fromJson(jsonDecode(e))).toList();
      } else {
        configs = [ForecastConfig()];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Choose Forecasts"),
        actions: [TextButton(onPressed: _applyAndExit, child: const Text("Apply"))],
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
                    label: const Text("Add another forecast"),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
