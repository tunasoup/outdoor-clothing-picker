import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;

import 'package:outdoor_clothing_picker/database/database.dart';
import 'package:outdoor_clothing_picker/misc/activity_notifier.dart';
import 'package:outdoor_clothing_picker/misc/clothing_viewmodel.dart';
import 'package:outdoor_clothing_picker/widgets/utils.dart';
import 'package:outdoor_clothing_picker/widgets/weather_widget.dart';

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
  final GlobalKey _svgKey = GlobalKey();
  int selectedIndex = 0;
  bool useRail = false;

  @override
  void initState() {
    super.initState();
    // Prevent right-click context menu on web
    html.document.onContextMenu.listen((event) => event.preventDefault());
    db = widget.db;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: AdderButton(db: db),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const WeatherWidget(),
            const SizedBox(height: 32),
            const Text('Select activity:'),
            SizedBox(
              width: 200,
              child: ActivityDropdown(
                initialValue: context.read<ClothingViewModel>().activity,
                onChanged: (value) => context.read<ClothingViewModel>().setActivity(value),
              ),
            ),
            Expanded(
              child: ClothingFigure(
                svgKey: _svgKey,
                getNormalizedTapOffset: getNormalizedTapOffset,
              ),
            ),
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
  final AppDb db;

  const AdderButton({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.add, size: 32, color: Theme.of(context).colorScheme.secondary),
      onSelected: (value) async {
        bool success = await showAddRowDialog(context: context, tableName: value, db: db);
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

class ClothingFigure extends StatelessWidget {
  final GlobalKey svgKey;
  final Future<Offset?> Function({required TapDownDetails details, required GlobalKey key})
  getNormalizedTapOffset;

  const ClothingFigure({super.key, required this.svgKey, required this.getNormalizedTapOffset});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ClothingViewModel>();
    return GestureDetector(
      onTapDown: (details) async {
        final normalized = await getNormalizedTapOffset(key: svgKey, details: details);
        if (normalized != null) {
          if (kDebugMode) {
            debugPrint('Normalized Tap: $normalized');
          }
        }
      },
      // TODO: selector?
      child: FittedBox(
        fit: BoxFit.contain,
        child: Container(
          key: svgKey,
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
                  painter: ClothingPainter(context, viewModel.filteredClothing),
                  size: const Size(200, 200), // TODO: dynamic sizing
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
