import 'package:flutter/material.dart';
import 'package:outdoor_clothing_picker/backend/forecast_config.dart';

class ForecastConfigurator extends StatefulWidget {
  final ForecastConfig config;

  const ForecastConfigurator({required this.config, super.key});

  @override
  State<ForecastConfigurator> createState() => _ForecastConfiguratorState();
}

class _ForecastConfiguratorState extends State<ForecastConfigurator> {
  late final TextEditingController _locationController;
  late final TextEditingController _tempController;

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController(text: widget.config.location);
    _tempController = TextEditingController(
      text: widget.config.manualTemperature?.toString() ?? '',
    );

    _locationController.addListener(_onLocationChanged);
    _tempController.addListener(_onTempChanged);
  }

  @override
  void didUpdateWidget(covariant ForecastConfigurator oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If a new config instance was provided, update controller texts to match
    if (oldWidget.config != widget.config) {
      if (_locationController.text != widget.config.location) {
        _locationController.text = widget.config.location;
      }
      final tempText = widget.config.manualTemperature?.toString() ?? '';
      if (_tempController.text != tempText) {
        _tempController.text = tempText;
      }
    }
  }

  void _onLocationChanged() {
    widget.config.location = _locationController.text;
  }

  void _onTempChanged() {
    final value = _tempController.text.trim();
    final temp = int.tryParse(value);
    widget.config.manualTemperature = temp;
  }

  @override
  void dispose() {
    _locationController.removeListener(_onLocationChanged);
    _tempController.removeListener(_onTempChanged);
    _locationController.dispose();
    _tempController.dispose();
    super.dispose();
  }

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
                  isSelected: [!widget.config.isManual, widget.config.isManual],
                  onPressed: (index) {
                    bool manual = index == 1;
                    setState(() {
                      widget.config.isManual = manual;
                    });
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

            if (!widget.config.isManual) ...[
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: "Location"),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.config.forecastTime == null
                          ? "Time: Now"
                          : "Time: ${widget.config.forecastTime}",
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

                      setState(() {
                        widget.config.forecastTime = combined;
                      });
                    },
                  ),
                ],
              ),
            ],

            if (widget.config.isManual)
              TextFormField(
                controller: _tempController,
                decoration: const InputDecoration(labelText: "Temperature (°C)"),
                keyboardType: TextInputType.number,
              ),
          ],
        ),
      ),
    );
  }
}
