import 'package:flutter/material.dart';
import 'package:outdoor_clothing_picker/backend/forecast_config.dart';

class ForecastConfigurator extends StatelessWidget {
  final ForecastConfig config;
  final ValueChanged<ForecastConfig> onChanged;

  const ForecastConfigurator({required this.config, required this.onChanged, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text("Mode: "),
                const SizedBox(width: 4),
                ToggleButtons(
                  isSelected: [!config.isManual, config.isManual],
                  onPressed: (index) {
                    bool manual = index == 1;

                    onChanged(
                      ForecastConfig(
                        isManual: manual,
                        location: config.location,
                        forecastTime: config.forecastTime,
                        manualTemperature: config.manualTemperature,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text("Forecast"),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text("Manual °C"),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (!config.isManual) ...[
              TextFormField(
                // FIXME: keyboard toggles on type
                initialValue: config.location,
                decoration: const InputDecoration(labelText: "Location"),
                onChanged: (value) {
                  onChanged(
                    ForecastConfig(
                      isManual: config.isManual,
                      location: value,
                      forecastTime: config.forecastTime,
                      manualTemperature: config.manualTemperature,
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      config.forecastTime == null ? "Time: Now" : "Time: ${config.forecastTime}",
                    ),
                  ),
                  TextButton(
                    // TODO: separate time and date pickers
                    child: const Text("Pick time"),
                    onPressed: () async {
                      final now = DateTime.now();
                      final date = await showDatePicker(
                        context: context,
                        initialDate: now,
                        firstDate: now,
                        lastDate: DateTime(now.year + 2),
                      );
                      if (date == null) return;

                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time == null) return;

                      final combined = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );

                      onChanged(
                        ForecastConfig(
                          isManual: false,
                          location: config.location,
                          forecastTime: combined,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],

            if (config.isManual)
              TextFormField(
                initialValue: config.manualTemperature?.toString() ?? '',
                decoration: const InputDecoration(labelText: "Temperature (°C)"),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final temp = int.tryParse(value);
                  onChanged(
                    ForecastConfig(
                      isManual: true,
                      location: config.location,
                      forecastTime: config.forecastTime,
                      manualTemperature: temp,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
