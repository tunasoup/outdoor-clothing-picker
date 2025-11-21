import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:outdoor_clothing_picker/backend/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// TODO: use the output values to query forecasts
// TODO: Change date to offset from today
// TODO: Add favorites
class WeatherConfigPage extends StatefulWidget {
  const WeatherConfigPage({super.key});

  @override
  State<WeatherConfigPage> createState() => _WeatherConfigPageState();
}

class _WeatherConfigPageState extends State<WeatherConfigPage> {
  late List<WeatherForecastRequest> _cards;

  @override
  void initState() {
    super.initState();
    _cards = [];
    _loadForecasts();
  }

  void _addCard() {
    final lastLocation = _cards.isNotEmpty ? _cards.last.location : '';

    if (_cards.length < 4) {
      setState(() => _cards.add(WeatherForecastRequest(location: lastLocation)));
    }
  }

  void _updateCard(int index, WeatherForecastRequest updated) {
    setState(() => _cards[index] = updated);
  }

  void _removeCard(int index) {
    setState(() => _cards.removeAt(index));
  }

  void _applyAndExit() {
    _saveForecasts();
    Navigator.pop(context, _cards);
  }

  void _onDismissCard(int index) {
    final removedCard = _cards[index];
    final removedIndex = index;
    _removeCard(index);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Forecast deleted"),
        action: SnackBarAction(
          label: "UNDO",
          onPressed: () {
            setState(() {
              _cards.insert(removedIndex, removedCard);
            });
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _saveForecasts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _cards.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(PrefKeys.forecastCards, jsonList);
  }

  Future<void> _loadForecasts() async {
    final prefs = await SharedPreferences.getInstance();
    final savedList = prefs.getStringList(PrefKeys.forecastCards);
    setState(() {
      if (savedList != null && savedList.isNotEmpty) {
        _cards = savedList.map((e) => WeatherForecastRequest.fromJson(jsonDecode(e))).toList();
      } else {
        // Create a default card if there no cards
        _cards = [WeatherForecastRequest()];
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
        itemCount: _cards.length,
        itemBuilder: (context, index) {
          final isLast = index == _cards.length - 1;
          return Column(
            children: [
              Dismissible(
                key: ValueKey(_cards[index].id),
                direction: _cards.length > 1 ? DismissDirection.endToStart : DismissDirection.none,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white, size: 28),
                ),
                onDismissed: (_) => _onDismissCard(index),
                child: WeatherForecastCardWidget(
                  request: _cards[index],
                  onChanged: (value) => _updateCard(index, value),
                ),
              ),

              if (isLast && _cards.length < 4)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ElevatedButton.icon(
                    onPressed: _addCard,
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

class WeatherForecastRequest {
  final String id;
  bool manualMode;
  String location;
  DateTime? forecastTime;
  int? manualTemperature;

  WeatherForecastRequest({
    String? id,
    this.manualMode = false,
    this.location = '',
    this.forecastTime,
    this.manualTemperature,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
    'id': id,
    'manualMode': manualMode,
    'location': location,
    'manualTemperature': manualTemperature,
  };

  factory WeatherForecastRequest.fromJson(Map<String, dynamic> json) {
    return WeatherForecastRequest(
      id: json['id'],
      manualMode: json['manualMode'] ?? false,
      location: json['location'] ?? '',
      manualTemperature: (json['manualTemperature'] != null)
          ? (json['manualTemperature'] as num).toInt()
          : null,
    );
  }
}

class WeatherForecastCardWidget extends StatelessWidget {
  final WeatherForecastRequest request;
  final ValueChanged<WeatherForecastRequest> onChanged;

  const WeatherForecastCardWidget({required this.request, required this.onChanged, super.key});

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
                  isSelected: [!request.manualMode, request.manualMode],
                  onPressed: (index) {
                    bool manual = index == 1;

                    onChanged(
                      WeatherForecastRequest(
                        manualMode: manual,
                        location: request.location,
                        forecastTime: request.forecastTime,
                        manualTemperature: request.manualTemperature,
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

            if (!request.manualMode) ...[
              TextFormField(
                initialValue: request.location,
                decoration: const InputDecoration(labelText: "Location"),
                onChanged: (value) {
                  onChanged(
                    WeatherForecastRequest(
                      id: request.id,
                      manualMode: request.manualMode,
                      location: value,
                      forecastTime: request.forecastTime,
                      manualTemperature: request.manualTemperature,
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      request.forecastTime == null ? "Time: Now" : "Time: ${request.forecastTime}",
                    ),
                  ),
                  TextButton(
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
                        WeatherForecastRequest(
                          manualMode: false,
                          location: request.location,
                          forecastTime: combined,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],

            if (request.manualMode)
              TextFormField(
                initialValue: request.manualTemperature?.toString() ?? '',
                decoration: const InputDecoration(labelText: "Temperature (°C)"),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final temp = int.tryParse(value);
                  onChanged(
                    WeatherForecastRequest(
                      id: request.id,
                      manualMode: true,
                      location: request.location,
                      forecastTime: request.forecastTime,
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
