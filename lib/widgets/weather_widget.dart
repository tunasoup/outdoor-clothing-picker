import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:outdoor_clothing_picker/misc/weather_viewmodel.dart';

class WeatherWidget extends StatelessWidget {
  const WeatherWidget({super.key});

  // TODO: Controller should not be used with Stateless due to memory leaks, need to dispose
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WeatherViewModel>();
    final cityController = TextEditingController();
    final manualTempController = TextEditingController(
      text: '${viewModel.manualTemperature ?? ''}',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: cityController,
          decoration: const InputDecoration(labelText: 'Enter City', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: manualTempController,
          decoration: const InputDecoration(
            labelText: 'Manual Temperature (optional)',
            border: OutlineInputBorder(),
            hintText: 'e.g. 25',
          ),
          // onChanged: (value) => viewModel.setManualTemperature(value),
          onSubmitted: (value) => viewModel.setManualTemperature(value),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: viewModel.isLoading
              ? null
              : () => viewModel.fetchWeather(cityController.text),
          child: viewModel.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Get Weather'),
        ),
        const SizedBox(height: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('City: ${viewModel.cityName}'),
            Text('Temperature: ${viewModel.temperature?.round()}°C'),
            Text('Condition: ${viewModel.mainCondition ?? "N/A"}'),
            Text(viewModel.isUsingManual ? '(Manual temperature used)' : '(API temperature used)'),
          ],
        ),
      ],
    );
  }
}

// Temporary widget for testing
class TemperatureInfoWidget extends StatelessWidget {
  const TemperatureInfoWidget({super.key});

  String _mapTemperatureToLabel(double temperature) {
    return temperature >= 20 ? "Warm" : "Cold";
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WeatherViewModel>();

    if (viewModel.temperature == null) {
      return const Text('No temperature available yet.');
    }

    final label = _mapTemperatureToLabel(viewModel.temperature!);

    return Text(
      'It feels: $label',
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}
