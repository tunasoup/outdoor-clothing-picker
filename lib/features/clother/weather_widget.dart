import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:outdoor_clothing_picker/core/ui/ui_helpers.dart';
import 'package:outdoor_clothing_picker/core/utils/weather_model.dart';
import 'package:outdoor_clothing_picker/routes.dart';

import './forecast_config.dart';
import './weather_viewmodel.dart';

/// Widget for displaying weather info and opening the weather config page.
class WeatherWidget extends StatefulWidget {
  final WeatherViewModel viewModel;

  const WeatherWidget({super.key, required this.viewModel});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  // Keep track of current configs and save them only on success, so that active weathers are
  // not changed by failed configs, but the user can go back to edit the drafts if they do not
  // restart the app.
  // TODO: move to backend, set to result on page exit, null on saveForecastConfig
  List<ForecastConfig>? draftConfigs;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          return Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () async {
                    // TODO: Errorwrapper
                    await context.push(Routes.forecastConfigs);
                    // final result = await Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => WeatherConfigPage(initialConfigs: draftConfigs),
                    //   ),
                    // );
                    // ScaffoldMessenger.of(context).clearSnackBars();
                    // if (result == null) return;
                    // draftConfigs = result;
                    // await errorWrapper(context, () async {
                    //   try {
                    //     await widget.viewModel.updateWeatherConfigs(configs: result);
                    //   } catch (e) {
                    //     rethrow;
                    //   }
                    //   draftConfigs = null;
                    // });
                    // TODO: tapping could be expected to show more detailed weather informations as well
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        if (widget.viewModel.isLoading)
                          Center(child: CircularProgressIndicator(strokeWidth: 3)),
                        Center(
                          child: Column(
                            children: [
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  spacing: 16,
                                  children: widget.viewModel.weathers
                                      .map((e) => _buildWeatherDisplay(e, colorScheme))
                                      .toList(),
                                ),
                              ),
                              _buildUpdateInfo(widget.viewModel, colorScheme),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (kIsWeb) GetWeatherButton(viewModel: widget.viewModel),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWeatherDisplay(WeatherPresenter weather, ColorScheme colorScheme) {
    final icon = iconFromCondition(weather.mainCondition);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 48, color: colorScheme.onPrimaryContainer),
              const SizedBox(width: 16),
            ],
            Text(
              weather.temperatureDisplay,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
                height: 1,
              ),
            ),
          ],
        ),
        Text(
          weather.description,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 14, color: colorScheme.onPrimaryContainer),
        ),
      ],
    );
  }

  Widget _buildUpdateInfo(WeatherViewModel viewModel, ColorScheme colorScheme) {
    return Text(
      viewModel.updateInfo,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 14, color: colorScheme.onPrimaryContainer),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
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
              : () async => await errorWrapper(context, viewModel.refreshWithLoading),
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
