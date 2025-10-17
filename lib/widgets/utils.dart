import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import 'package:outdoor_clothing_picker/database/database.dart';
import 'package:outdoor_clothing_picker/misc/activity_notifier.dart';

/// Dialog where a new Activity item can be created.
class AddActivityDialog extends StatelessWidget {
  final AppDb db;

  const AddActivityDialog({super.key, required this.db});

  Future<bool> show(BuildContext context) async {
    final success = await showDialog<bool>(
      context: context,
      builder: (context) {
        return ChangeNotifierProvider(
          create: (_) => ActivityDialogViewModel(db),
          child: AddActivityDialog(db: db),
        );
      },
    );
    return success ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ActivityDialogViewModel>();

    return AlertDialog(
      title: Text('Add Activity'),
      content: Form(
        key: vm.formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: InputDecoration(labelText: 'Activity Name'),
              validator: (value) => vm.validateName(value),
              onSaved: (value) => vm.saveName(value),
              autofocus: true,
            ),
            Padding(padding: EdgeInsets.all(16.0)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (await vm.saveActivity()) {
                      Provider.of<ActivityItemsProvider>(context, listen: false).refresh();
                      Navigator.pop(context, true);
                    }
                  },
                  child: Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Open a dialog where a new Category item can be created for the [db].
/// If [normX] and [normY] coordinates are not provided, then the user is prompted
/// to click a spot on a figure for them.
Future<bool> showAddCategoryDialog({
  required BuildContext context,
  required AppDb db,
  double? normX,
  double? normY,
}) async {
  final formKey = GlobalKey<FormState>();
  String? category;
  bool coordinatesValid = true;
  final Size size = Size(100, 200);
  // TODO: accurate 1-to-1 matching with other figure

  double localNormX = normX ?? 0.0;
  double localNormY = normY ?? 0.0;

  final categories = (await db.allCategories().get()).map((a) => a.name.toLowerCase()).toList();

  final success = await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text('Add Category'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCategoryDialogContent(
                context: context,
                categories: categories,
                onSaved: (value) => category = value!.trim(),
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
                coordinatesValid: coordinatesValid,
              ),
              Padding(padding: EdgeInsets.all(16.0)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final formValid = formKey.currentState?.validate() ?? false;

                      final xValid = normX != null || localNormX != 0.0;
                      final yValid = normY != null || localNormY != 0.0;
                      final coordsValid = xValid && yValid;

                      setState(() {
                        coordinatesValid = coordsValid;
                      });

                      if (formValid && coordsValid) {
                        formKey.currentState?.save();
                        await db
                            .into(db.categories)
                            .insert(
                              CategoriesCompanion.insert(
                                name: category!,
                                normX: normX ?? localNormX,
                                normY: normY ?? localNormY,
                              ),
                            );
                        Navigator.pop(context, true);
                      }
                    },
                    child: Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return success ?? false;
}

Widget _buildCategoryDialogContent({
  required BuildContext context,
  required List<String> categories,
  required String? Function(String?)? onSaved,
  required Size size,
  required double? normX,
  required double? normY,
  required double localNormX,
  required double localNormY,
  required void Function(double, double) onPositionSelected,
  required bool coordinatesValid,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      TextFormField(
        decoration: InputDecoration(labelText: 'Category Name'),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Enter a value';
          if (categories.contains(value.trim().toLowerCase())) {
            return 'This activity already exists';
          }
          return null;
        },
        onSaved: onSaved,
      ),
      SizedBox(height: 16),
      if (normX != null && normY != null)
        _buildStaticCoordinateView(normX, normY)
      else
        _buildInteractiveFigure(
          context: context,
          size: size,
          normX: localNormX,
          normY: localNormY,
          onPositionSelected: onPositionSelected,
          coordinatesValid: coordinatesValid,
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
  required BuildContext context,
  required Size size,
  required double normX,
  required double normY,
  required void Function(double, double) onPositionSelected,
  required bool coordinatesValid,
}) {
  return Column(
    children: [
      Text(
        'Click on the figure to select coordinates,\n'
        'x=${normX.toStringAsFixed(2)}, y=${normY.toStringAsFixed(2)}',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: coordinatesValid
              ? Theme.of(context).textTheme.bodyMedium?.color
              : Theme.of(context).colorScheme.error,
        ),
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
Future<bool> showAddClothingDialog({required BuildContext context, required AppDb db}) async {
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
  final success = await showDialog(
    context: context,
    builder: (context) => AlertDialog(
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
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Cancel'),
                  ),
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
                        Navigator.pop(context, true);
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
  return success ?? false;
}

Future<bool> showAddRowDialog({
  required BuildContext context,
  required String tableName,
  required AppDb db,
}) async {
  switch (tableName) {
    case 'clothing':
      return await showAddClothingDialog(context: context, db: db);
    case 'activities':
      return await AddActivityDialog(db: db).show(context);
    case 'categories':
      return await showAddCategoryDialog(context: context, db: db);
  }
  return false;
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
    showAddCategoryDialog(context: context, db: db, normX: normX, normY: normY);
  }
}
