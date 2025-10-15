import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;

import 'package:outdoor_clothing_picker/database/database.dart';
import 'package:outdoor_clothing_picker/misc/activity_notifier.dart';
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
  List<ValidClothingResult> _selectedClothing = [];
  final GlobalKey _svgKey = GlobalKey();
  int selectedIndex = 0;
  bool useRail = false;

  @override
  void initState() {
    super.initState();
    // Prevent right-click context menu on web
    html.document.onContextMenu.listen((event) => event.preventDefault());
    db = widget.db;
    Future.microtask(() async {
      final provider = context.read<ActivityItemsProvider>();
      _selectedActivity = await provider.getFirstItem();
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

  // TODO: check if stateful builder useful here
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: AdderButton(loadClothing: _updateClothing, db: db),
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
              child: ActivityDropdown(
                initialValue: _selectedActivity,
                onChanged: (value) {
                  if (value != _selectedActivity) {
                    setState(() {
                      _selectedActivity = value;
                    });
                    _updateClothing();
                  }
                },
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
                        SvgPicture.asset(
                          'assets/images/silhouette.svg',
                          colorFilter: ColorFilter.mode(
                            Theme.of(context).colorScheme.onSurfaceVariant,
                            BlendMode.srcIn,
                          ),
                        ),
                        RepaintBoundary(
                          child: CustomPaint(
                            painter: ClothingPainter(context, _selectedClothing),
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
  BuildContext context;
  final List<ValidClothingResult> clothing;

  ClothingPainter(this.context, this.clothing);

  @override
  void paint(Canvas canvas, Size size) {
    final color = Theme.of(context).colorScheme.onSurface;

    final linePaint = Paint()
      ..color = color
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
          style: TextStyle(color: color, fontSize: 16),
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
  final VoidCallback? loadClothing;
  final AppDb db;

  const AdderButton({super.key, this.loadClothing, required this.db});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.add, size: 32, color: Theme.of(context).colorScheme.secondary),
      onSelected: (value) async {
        bool success = false;

        switch (value) {
          case 'clothing':
            success = await showAddRowDialog(
              context: context,
              tableName: value,
              db: db,
              onRowAdded: loadClothing ?? () {},
            );
            break;
          case 'activities':
            success = await showAddRowDialog(
              context: context,
              tableName: value,
              db: db,
              onRowAdded: () {},
            );
            break;
          case 'categories':
            success = await showAddRowDialog(
              context: context,
              tableName: value,
              db: db,
              onRowAdded: () {},
            );
            break;
        }

        if (success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Added $value successfully')));
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

class ActivityDropdown extends StatelessWidget {
  final String? initialValue;
  final void Function(String?) onChanged;

  const ActivityDropdown({super.key, this.initialValue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityItemsProvider>(
      builder: (context, provider, _) {
        return DropdownButtonFormField<String>(
          initialValue: initialValue,
          items: provider.items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(hintText: 'Activity'),
        );
      },
    );
  }
}
