import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:outdoor_clothing_picker/backend/weather_viewmodel.dart';
import 'package:outdoor_clothing_picker/widgets/utils.dart';
import 'package:provider/provider.dart';

/// Widget for interacting with a weather API or manual user input.
class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WeatherViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => WeatherEditor(viewModel: viewModel),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.ac_unit, size: 48, color: colorScheme.onPrimaryContainer),
                    const SizedBox(width: 16),
                    Text(
                      '${viewModel.temperature?.round() ?? -100}°C',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      viewModel.cityName ?? 'Unknown City',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: colorScheme.onPrimaryContainer),
                    ),
                    Text(
                      viewModel.updateInfo ??
                          'This is a very long additional text that might not fit',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onPrimaryContainer),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (kIsWeb) GetWeatherButton(viewModel: viewModel),
      ],
    );
  }
}

class WeatherEditor extends StatelessWidget {
  final WeatherViewModel viewModel;

  const WeatherEditor({super.key, required this.viewModel});

  Future<void> _submitForm(
    BuildContext context,
    WeatherViewModel viewModel,
    String? temperature,
  ) async {
    errorWrapper(context, () async {
      Navigator.pop(context, true);
      await viewModel.setManualTemperature(temperature!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Weather Editor'),
      content: TextFormField(
        decoration: const InputDecoration(labelText: 'Manual Temperature Override'),
        keyboardType: const TextInputType.numberWithOptions(signed: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*'))],
        autofocus: true,
        onFieldSubmitted: (value) async {
          await _submitForm(context, viewModel, value);
        },
      ),
    );
  }
}

class GetWeatherButton extends StatelessWidget {
  final WeatherViewModel viewModel;

  const GetWeatherButton({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          onPressed: viewModel.isLoading
              ? null
              : () => errorWrapper(context, viewModel.fetchWeather),
          child: viewModel.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Get Weather'),
        ),
      ),
    );
  }
}
