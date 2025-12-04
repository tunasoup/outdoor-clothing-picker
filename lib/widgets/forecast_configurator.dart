import 'package:flutter/material.dart';
import 'package:outdoor_clothing_picker/backend/forecast_config.dart';
import 'package:outdoor_clothing_picker/backend/utils.dart';

class ForecastConfigurator extends StatefulWidget {
  final ForecastConfig config;

  const ForecastConfigurator({required this.config, super.key});

  @override
  State<ForecastConfigurator> createState() => _ForecastConfiguratorState();
}

class _ForecastConfiguratorState extends State<ForecastConfigurator> {
  late final TextEditingController _locationController;
  late final TextEditingController _tempController;

  // 3-hour interval times as dictated by OWM
  final List<TimeOfDay> timeOptions = List.generate(
    8,
    (index) => TimeOfDay(hour: index * 3, minute: 0),
  );

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

  Future<void> pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.config.dateTime,
      firstDate: now,
      lastDate: now.add(const Duration(days: 3)),
    );
    if (picked != null) {
      final offset = computeDateOffset(dt: picked);
      setState(() {
        widget.config.dateOffset = offset;
      });
    }
  }

  Future<void> pickTime() async {
    final picked = await showModalBottomSheet<dynamic>(
      context: context,
      builder: (_) => SizedBox(
        child: ListView(
          children: [
            ListTile(
              title: const Center(child: Text('Clear')),
              onTap: () => Navigator.pop(context, 'clear'),
            ),
            ...List.generate(timeOptions.length, (index) {
              final time = timeOptions[index];
              return ListTile(
                title: Center(child: Text(time.format(context))),
                onTap: () => Navigator.pop(context, time),
              );
            }),
          ],
        ),
      ),
    );

    if (picked == null) {
      return;
    } else if (picked == 'clear') {
      setState(() {
        widget.config.time = null;
      });
    } else {
      setState(() {
        widget.config.time = picked;
      });
    }
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
                const Text('Mode: '),
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
                      child: Text('Forecast'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Manual °C'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (!widget.config.isManual) ...[
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  hintText: 'Using location if left empty',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: pickDate,
                      child: Text(
                        widget.config.dateOffset == 0
                            ? 'Day: Today'
                            : 'Day: +${widget.config.dateOffset}',
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: pickTime,
                      child: Text(
                        widget.config.time == null
                            ? 'Time: Now'
                            : 'Time: ${widget.config.time!.format(context)}',
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (widget.config.isManual)
              TextFormField(
                controller: _tempController,
                decoration: const InputDecoration(labelText: 'Temperature (°C)'),
                keyboardType: TextInputType.number,
              ),
          ],
        ),
      ),
    );
  }
}
