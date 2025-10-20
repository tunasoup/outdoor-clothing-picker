import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import 'package:outdoor_clothing_picker/database/database.dart';
import 'package:outdoor_clothing_picker/misc/item_controllers.dart';
import 'package:outdoor_clothing_picker/misc/item_notifiers.dart';

/// Dialog where a new Activity item can be created.
class AddActivityDialog extends StatelessWidget {
  const AddActivityDialog({super.key});

  Future<bool> show(BuildContext context) async {
    final AppDb db = context.read<AppDb>();
    final success = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Provider(
          create: (context) {
            final itemsProvider = context.read<ActivityItemsProvider>();
            return ActivityDialogController(db, itemsProvider.items);
          },
          child: AddActivityDialog(),
        );
      },
    );
    return success ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<ActivityDialogController>();

    return AlertDialog(
      title: Text('Add Activity'),
      content: Form(
        key: controller.formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: InputDecoration(labelText: 'Activity Name'),
              validator: (value) => controller.validateName(value),
              onSaved: (value) => controller.saveName(value),
              autofocus: true,
            ),
            Padding(padding: EdgeInsets.all(16.0)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (await controller.saveActivity()) {
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

/// Dialog where a new Category item can be created.
/// If [normX] and [normY] coordinates are not provided, then the user is prompted
/// to click a spot on a figure for them.
class AddCategoryDialog extends StatelessWidget {
  final double? normX;
  final double? normY;

  AddCategoryDialog({super.key, this.normX, this.normY});

  final Size size = Size(100, 200);

  Future<bool> show(BuildContext context) async {
    final AppDb db = context.read<AppDb>();
    final success = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Provider(
          create: (context) {
            final itemsProvider = context.read<CategoryItemsProvider>();
            return CategoryDialogController(db, itemsProvider.names);
          },
          child: AddCategoryDialog(normX: normX, normY: normY),
        );
      },
    );
    return success ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<CategoryDialogController>();

    return AlertDialog(
      title: Text('Add Category'),
      content: Form(
        key: controller.formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: InputDecoration(labelText: 'Category Name'),
              validator: (value) => controller.validateName(value),
              onSaved: (value) => controller.saveName(value),
              autofocus: true,
            ),
            if (normX != null || normY != null)
              _buildStaticCoordinateView(normX!, normY!)
            else
              InteractiveFigureFormField(context: context, size: size, controller: controller),
            Padding(padding: EdgeInsets.all(16.0)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (await controller.saveCategory()) {
                      Provider.of<CategoryItemsProvider>(context, listen: false).refresh();
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

/// Custom Form Field with a tappable figure of [size] to obtain normalized coordinates.
class InteractiveFigureFormField extends FormField<Offset> {
  InteractiveFigureFormField({
    super.key,
    required this.context,
    required this.size,
    required this.controller,
    AutovalidateMode super.autovalidateMode = AutovalidateMode.disabled,
  }) : super(
         initialValue: null,
         validator: (value) => controller.validateCoords(value?.dx, value?.dy),
         onSaved: (value) => controller.saveCoords(value?.dx, value?.dy),
         builder: (FormFieldState<Offset> field) {
           final Offset? value = field.value;
           final double? normX = field.value?.dx;
           final double? normY = field.value?.dy;
           final coordinatesValid = field.errorText == null;

           return Column(
             children: [
               Text(
                 'Click on the figure to select coordinates,\n'
                 'x=${normX?.toStringAsFixed(2) ?? '--'}, y=${normY?.toStringAsFixed(2) ?? '--'}',
                 textAlign: TextAlign.center,
                 style: TextStyle(
                   color: coordinatesValid
                       ? Theme.of(context).textTheme.bodyMedium?.color
                       : Theme.of(context).colorScheme.error,
                 ),
               ),
               const SizedBox(height: 8),
               Builder(
                 builder: (ctx) => SizedBox(
                   width: size.width,
                   height: size.height,
                   child: GestureDetector(
                     onTapDown: (details) {
                       final RenderBox box = ctx.findRenderObject() as RenderBox;
                       final localPos = box.globalToLocal(details.globalPosition);
                       final newX = localPos.dx / size.width;
                       final newY = localPos.dy / size.height;

                       field.didChange(Offset(newX, newY));
                     },
                     child: Stack(
                       children: [
                         // TODO: unified drawing of the asset with correct bounding box
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
                         // Add a visual marker for the selected position
                         if (value != null)
                           Positioned(
                             left: normX! * size.width - 5,
                             top: normY! * size.height - 5,
                             child: Container(
                               width: 10,
                               height: 10,
                               decoration: BoxDecoration(
                                 color: Theme.of(context).colorScheme.primary,
                                 shape: BoxShape.circle,
                                 border: Border.all(
                                   color: Theme.of(context).colorScheme.surface,
                                   width: 2,
                                 ),
                               ),
                             ),
                           ),
                       ],
                     ),
                   ),
                 ),
               ),
               // Set error message on failed validation
               if (field.errorText != null)
                 Padding(
                   padding: const EdgeInsets.only(top: 8.0),
                   child: Text(
                     field.errorText!,
                     style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                   ),
                 ),
             ],
           );
         },
       );

  final BuildContext context;
  final Size size;
  final CategoryDialogController controller;
}

Widget _buildStaticCoordinateView(double normX, double normY) {
  return Text(
    'Coordinates selected:\nx=${normX.toStringAsFixed(2)}, y=${normY.toStringAsFixed(2)}',
    textAlign: TextAlign.center,
  );
}

/// Dialog where a new Clothing item can be created.
class AddClothingDialog extends StatelessWidget {
  const AddClothingDialog({super.key});

  Future<bool> show(BuildContext context) async {
    final AppDb db = context.read<AppDb>();
    // TODO: disable or add a warning if there are no categories or activities
    final success = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Provider(
          create: (_) => ClothingDialogController(db),
          child: AddClothingDialog(),
        );
      },
    );
    return success ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<ClothingDialogController>();

    return AlertDialog(
      title: Text('Add Clothing Item'),
      content: SingleChildScrollView(
        child: Form(
          key: vm.formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Name'),
                validator: vm.validateName,
                onSaved: vm.saveName,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Min Temperature'),
                validator: vm.validateMinTemp,
                onSaved: vm.saveMinTemp,
                keyboardType: TextInputType.numberWithOptions(signed: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*'))],
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Max Temperature'),
                validator: vm.validateMaxTemp,
                onSaved: vm.saveMaxTemp,
                keyboardType: TextInputType.numberWithOptions(signed: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*'))],
              ),
              Consumer<CategoryItemsProvider>(
                builder: (context, provider, _) {
                  return DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: 'Category'),
                    validator: vm.validateDropdown,
                    items: provider.names
                        .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                    onSaved: vm.saveCategory,
                    onChanged: (_) {},
                  );
                },
              ),
              Consumer<ActivityItemsProvider>(
                builder: (context, provider, _) {
                  return DropdownButtonFormField<String>(
                    decoration: InputDecoration(hintText: 'Activity'),
                    validator: vm.validateDropdown,
                    items: provider.items
                        .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                        .toList(),
                    onSaved: vm.saveActivity,
                    onChanged: (_) {},
                  );
                },
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
                      if (await vm.saveClothing()) {
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
    );
  }
}

Future<bool> showAddRowDialog({
  required BuildContext context,
  required String tableName,
}) async {
  switch (tableName) {
    case 'clothing':
      return await AddClothingDialog().show(context);
    case 'activities':
      return await AddActivityDialog().show(context);
    case 'categories':
      return await AddCategoryDialog().show(context);
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
    await AddCategoryDialog(normX: normX, normY: normY).show(context);
  }
}

/// Wrapper for showing a snackbar of a possible error when running [action].
void errorWrapper(
    BuildContext context,
    Future<void> Function() action,
    ) async {
  try {
    await action();
  } catch (e) {
    debugPrint('$e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$e'),
        backgroundColor: Theme.of(context).colorScheme.error,
      )
    );
  }
}
