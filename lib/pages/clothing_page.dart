import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:universal_html/html.dart' as html;

import 'package:outdoor_clothing_picker/database/database.dart';
import 'package:outdoor_clothing_picker/widgets/utils.dart';

/// The clothing page visualizes which clothings from a local database would be appropriate
/// for the current/selected weather, while allowing the user to add new items.
class ClothingPage extends StatefulWidget {
  const ClothingPage({super.key, required this.title, required this.db});

  final String title;
  final AppDb db;

  @override
  State<ClothingPage> createState() => _ClothingPageState();
}

class _ClothingPageState extends State<ClothingPage> {
  List<ClothingData> items = [];
  late final AppDb db;
  final TextEditingController _tempController = TextEditingController();
  String? _selectedActivity;
  List<String> _activities = [];
  List<ValidClothingResult> _selectedClothing = [];
  final GlobalKey _svgKey = GlobalKey();
  int selectedIndex = 0;
  bool useRail = false;

  @override
  void initState() {
    super.initState();
    html.document.onContextMenu.listen((event) => event.preventDefault());
    db = widget.db;
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    final acts = await db.allActivities().get();
    setState(() {
      _activities = acts.map((a) => a.name).toList();
      if (_activities.isNotEmpty && _selectedActivity == null) {
        _selectedActivity = _activities.first;
      }
    });
  }

  /// For each category, choose clothing that are valid for the weather and activity.
  void _updateClothing() async {
    final tempText = _tempController.text;
    final activity = _selectedActivity ?? '';

    if (tempText.isEmpty || activity.isEmpty) return;

    final temp = int.tryParse(tempText);
    if (temp == null) return;

    List<category> categories = await widget.db.allCategories().get();
    List<ValidClothingResult> items = await widget.db.validClothing(temp, activity).get();
    Map<String, ValidClothingResult?> outfit = {};
    for (var category in categories) {
      final categoryItems = items.where((item) => item.category == category.name).toList();
      if (categoryItems.isNotEmpty) {
        // If there are multiple items, choose the first
        // TODO: Choose the first chosen based on temperature range
        // TODO: Store all valid items, make interactable (tap for list or arrows)
        outfit[category.name] = categoryItems.first;
      } else {
        outfit[category.name] = null;
      }
    }

    setState(() {
      _selectedClothing = outfit.values.whereType<ValidClothingResult>().toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: Text(widget.title)),
      // endDrawer: const AppDrawer(),
      floatingActionButton: AdderButton(
        loadActivities: _loadActivities,
        loadClothing: _updateClothing,
        db: db,
      ),
      body: Center(
        child: Column(
          spacing: 20,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Enter current temperature:'),
            SizedBox(
              width: 100,
              child: TextField(
                controller: _tempController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(hintText: 'Temperature'),
                onChanged: (_) => _updateClothing(),
              ),
            ),
            Text('Select activity:'),
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String>(
                initialValue: _selectedActivity,
                items: _activities
                    .map((act) => DropdownMenuItem(value: act, child: Text(act)))
                    .toList(),
                onChanged: (value) {
                  if (value != _selectedActivity) {
                    setState(() {
                      _selectedActivity = value;
                    });
                    _updateClothing();
                  }
                },
                decoration: InputDecoration(hintText: 'Activity'),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTapDown: (details) async {
                  final normalized = await getNormalizedTapOffset(key: _svgKey, details: details);
                  if (normalized != null) {
                    if (kDebugMode) {
                      debugPrint('Normalized Tap: $normalized');
                    }
                  }
                },
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Container(
                    key: _svgKey,
                    child: Stack(
                      children: [
                        SvgPicture.asset('assets/images/silhouette.svg'),
                        RepaintBoundary(
                          child: CustomPaint(
                            painter: ClothingPainter(_selectedClothing),
                            size: Size(200, 200),
                            // TODO: dynamic calculation of size
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 0), // Column already has child padding
          ],
        ),
      ),
    );
  }
}

/// Draw the selected clothing labels on top of the figure.
class ClothingPainter extends CustomPainter {
  final List<ValidClothingResult> clothing;

  ClothingPainter(this.clothing);

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2;
    if (kDebugMode) print('Painting');

    for (var item in clothing) {
      final startX = item.normX * size.width;
      final y = item.normY * size.height;
      final labelX = size.width * 0.7; // Place label at 70% width

      // Draw horizontal line from figure to label
      canvas.drawLine(Offset(startX, y), Offset(labelX - 10, y), linePaint);

      // Draw label text
      final textPainter = TextPainter(
        text: TextSpan(
          text: item.name,
          style: TextStyle(color: Colors.blue, fontSize: 16),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(labelX, y - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// A button for adding new items to the [db].
class AdderButton extends StatelessWidget {
  final VoidCallback? loadActivities;
  final VoidCallback? loadClothing;
  final AppDb db;

  const AdderButton({super.key, this.loadActivities, this.loadClothing, required this.db});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.add, size: 32, color: Theme.of(context).colorScheme.secondary),
      onSelected: (value) async {
        switch (value) {
          case 'clothing':
            await showAddRowDialog(
              context: context,
              tableName: value,
              db: db,
              onRowAdded: loadClothing ?? () {},
            );
          case 'activities':
            await showAddRowDialog(
              context: context,
              tableName: value,
              db: db,
              onRowAdded: loadActivities ?? () {},
            );
          case 'categories':
            await showAddRowDialog(context: context, tableName: value, db: db, onRowAdded: () {});
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'clothing', child: Text('Add Clothing Item')),
        PopupMenuItem(value: 'activities', child: Text('Add Activity')),
        PopupMenuItem(value: 'categories', child: Text('Add Category')),
      ],
    );
  }
}

class WeatherInput extends StatelessWidget {
  final TextEditingController tempController = TextEditingController();

  WeatherInput({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Enter current temperature:'),
        TextField(controller: tempController, keyboardType: TextInputType.number),
      ],
    );
  }
}
