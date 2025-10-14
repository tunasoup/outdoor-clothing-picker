import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:outdoor_clothing_picker/database/database.dart';

/// Open a dialog where a new Activity item can be created for the [db].
Future<void> showAddActivityDialog({
  required BuildContext context,
  required AppDb db,
  required VoidCallback onRowAdded,
}) async {
  final controller = TextEditingController();
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Add Activity'),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: 'Activity Name'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            final name = controller.text.trim();
            if (name.isNotEmpty) {
              await db.into(db.activities).insert(ActivitiesCompanion.insert(name: name));
              onRowAdded();
              Navigator.pop(context);
            }
          },
          child: Text('Save'),
        ),
      ],
    ),
  );
}

/// Open a dialog where a new Category item can be created for the [db].
/// If [normX] and [normY] coordinates are not provided, then the user is prompted
/// to click a spot on a figure for them.
Future<void> showAddCategoryDialog({
  required BuildContext context,
  required AppDb db,
  required VoidCallback onRowAdded,
  double? normX,
  double? normY,
}) async {
  final controller = TextEditingController();
  final Size size = Size(100, 200);
  // TODO: accurate 1-to-1 matching with other figure

  double localNormX = normX ?? 0.0;
  double localNormY = normY ?? 0.0;

  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text('Add Category'),
        content: _buildCategoryDialogContent(
          context: context,
          controller: controller,
          size: size,
          normX: normX,
          normY: normY,
          localNormX: localNormX,
          localNormY: localNormY,
          onPositionSelected: (newX, newY) {
            localNormX = newX;
            localNormY = newY;
            setState(() {});
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty &&
                  (normX != null || localNormX != 0.0) &&
                  (normY != null || localNormY != 0.0)) {
                await db
                    .into(db.categories)
                    .insert(
                      CategoriesCompanion.insert(
                        name: name,
                        normX: normX ?? localNormX,
                        normY: normY ?? localNormY,
                      ),
                    );
                onRowAdded();
                Navigator.pop(context);
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    ),
  );
}

Widget _buildCategoryDialogContent({
  required BuildContext context,
  required TextEditingController controller,
  required Size size,
  required double? normX,
  required double? normY,
  required double localNormX,
  required double localNormY,
  required void Function(double, double) onPositionSelected,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      TextField(
        controller: controller,
        decoration: InputDecoration(labelText: 'Category Name'),
      ),
      SizedBox(height: 16),
      if (normX != null && normY != null)
        _buildStaticCoordinateView(normX, normY)
      else
        _buildInteractiveFigure(
          size: size,
          normX: localNormX,
          normY: localNormY,
          onPositionSelected: onPositionSelected,
        ),
    ],
  );
}

Widget _buildStaticCoordinateView(double normX, double normY) {
  return Text(
    'Coordinates selected:\nx=${normX.toStringAsFixed(2)}, y=${normY.toStringAsFixed(2)}',
    textAlign: TextAlign.center,
  );
}

/// Build a figure of [size] which can be tapped to obtain the widget's normalized coordinates
/// for that point.
Widget _buildInteractiveFigure({
  required Size size,
  required double normX,
  required double normY,
  required void Function(double, double) onPositionSelected,
}) {
  return Column(
    children: [
      Text(
        'Click on the figure to select coordinates,\n'
        'x=${normX.toStringAsFixed(2)}, y=${normY.toStringAsFixed(2)}',
        textAlign: TextAlign.center,
      ),
      SizedBox(height: 8),
      Builder(
        builder: (context) => SizedBox(
          width: size.width,
          height: size.height,
          child: GestureDetector(
            onTapDown: (details) {
              final RenderBox box = context.findRenderObject() as RenderBox;
              final localPos = box.globalToLocal(details.globalPosition);
              final newX = localPos.dx / size.width;
              final newY = localPos.dy / size.height;
              onPositionSelected(newX, newY);
            },
            child: Stack(
              children: [
                SvgPicture.asset(
                  'assets/images/silhouette.svg',
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.onSurfaceVariant,
                    BlendMode.srcIn,
                  ),
                  width: size.width,
                  height: size.height,
                  fit: BoxFit.cover,
                ),
                if (normX != 0.0 || normY != 0.0)
                  Positioned(
                    left: normX * size.width - 5,
                    top: normY * size.height - 5,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

/// Open a dialog where a new Clothing item can be created for the [db].
Future<void> showAddClothingDialog({
  required BuildContext context,
  required AppDb db,
  required VoidCallback onRowAdded,
}) async {
  final formKey = GlobalKey<FormState>();
  String? name;
  int? minTemp;
  String? minTempText; // Save text for comparing with maxTemp
  int? maxTemp;
  String? category;
  String? activity;

  String? required(String? value) => value == null || value.isEmpty ? 'Enter a value' : null;

  // Fetch categories and activities from DB
  final categories = (await db.allCategories().get()).map((c) => c.name).toList();
  final activities = (await db.allActivities().get()).map((a) => a.name).toList();

  // TODO: disable or add a warning if there are no categories or activities
  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add Clothing Item'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Name'),
                    validator: required,
                    onSaved: (value) => name = value!,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Min Temperature'),
                    validator: required,
                    onChanged: (value) => minTempText = value,
                    onSaved: (value) => minTemp = int.parse(value!),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*'))],
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Max Temperature'),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Enter a value';
                      final min = int.tryParse(minTempText ?? '');
                      final max = int.tryParse(value ?? '');
                      if (max == null) return 'Invalid number';
                      if (min != null && max < min) return 'Must be ≥ Min Temp ($min)';
                      return null;
                    },
                    onSaved: (value) => maxTemp = int.parse(value!),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*'))],
                  ),
                  DropdownButtonFormField<String>(
                    validator: required,
                    items: categories
                        .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                    onSaved: (value) => category = value!,
                    decoration: InputDecoration(labelText: 'Category'),
                    onChanged: (value) {},
                  ),
                  DropdownButtonFormField<String>(
                    validator: required,
                    items: activities
                        .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                    onSaved: (value) => activity = value!,
                    decoration: InputDecoration(labelText: 'Activity'),
                    onChanged: (value) {},
                  ),
                  Padding(padding: EdgeInsets.all(16.0)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
                      ElevatedButton(
                        onPressed: () async {
                          final form = formKey.currentState;
                          if (form!.validate()) {
                            form.save();
                            await db
                                .into(db.clothing)
                                .insert(
                                  ClothingCompanion.insert(
                                    name: name!,
                                    minTemp: minTemp!,
                                    maxTemp: maxTemp!,
                                    category: category!,
                                    activity: activity!,
                                  ),
                                );
                            onRowAdded();
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(const SnackBar(content: Text('Clothing added')));
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

Future<void> showAddRowDialog({
  required BuildContext context,
  required String tableName,
  required AppDb db,
  required VoidCallback onRowAdded,
}) async {
  switch (tableName) {
    case 'clothing':
      await showAddClothingDialog(context: context, db: db, onRowAdded: onRowAdded);
    case 'activities':
      await showAddActivityDialog(context: context, db: db, onRowAdded: onRowAdded);
    case 'categories':
      await showAddCategoryDialog(context: context, db: db, onRowAdded: onRowAdded);
  }
}

/// Obtain the normalized coordinates (range [0, 1]) of a tap inside a widget.
/// Meant to be used inside a GestureDetector, linking toa global [key] of a target widget.
Future<Offset?> getNormalizedTapOffset({
  required GlobalKey key,
  required TapDownDetails details,
}) async {
  final context = key.currentContext;
  if (context == null) return null;

  final box = context.findRenderObject() as RenderBox;
  final localPosition = box.globalToLocal(details.globalPosition);
  final size = box.size;

  if (size.width == 0 || size.height == 0) return null;

  final normalized = Offset(
    (localPosition.dx / size.width).clamp(0.0, 1.0),
    (localPosition.dy / size.height).clamp(0.0, 1.0),
  );

  return normalized;
}

/// Open a context menu at the provided position with the option to create a Category item.
/// The size of the local widget needs to be provided.
Future<void> _showContextMenu({
  required BuildContext context,
  required Offset globalPosition,
  required Offset localPosition,
  required Size localSize,
  required AppDb db,
  required VoidCallback onRowAdded,
}) async {
  final selected = await showMenu(
    context: context,
    position: RelativeRect.fromLTRB(
      globalPosition.dx,
      globalPosition.dy,
      globalPosition.dx,
      globalPosition.dy,
    ),
    items: [PopupMenuItem<String>(value: 'create_category', child: Text('Create Category'))],
  );

  if (selected == 'create_category') {
    double normX = localPosition.dx / localSize.width;
    double normY = localPosition.dy / localSize.height;
    if (kDebugMode) {
      debugPrint('Create category at: $normX $normY');
    }
    showAddCategoryDialog(
      context: context,
      db: db,
      onRowAdded: onRowAdded,
      normX: normX,
      normY: normY,
    );
  }
}
