import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:outdoor_clothing_picker/misc/weather_viewmodel.dart';

/// Widget for interacting with a weather API or manual user input.
class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  final cityController = TextEditingController();
  late final TextEditingController manualTempController;
  bool _isInitialized = false;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WeatherViewModel>();

    if (!_isInitialized) {
      manualTempController = TextEditingController(text: '${viewModel.manualTemperature ?? ''}');
      _isInitialized = true;
    }

    return Column(
      children: [
        // TextField(
        //   controller: cityController,
        //   decoration: const InputDecoration(labelText: 'Enter City', border: OutlineInputBorder()),
        // ),
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
          keyboardType: TextInputType.numberWithOptions(signed: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*'))],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
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

  @override
  void dispose() {
    cityController.dispose();
    if (_isInitialized) {
      manualTempController.dispose();
    }
    super.dispose();
  }

}
