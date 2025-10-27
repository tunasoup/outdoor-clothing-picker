import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:outdoor_clothing_picker/backend/item_controllers.dart';
import 'package:outdoor_clothing_picker/backend/items_provider.dart';
import 'package:outdoor_clothing_picker/database/database.dart';
import 'package:outdoor_clothing_picker/widgets/mannequin.dart';
import 'package:provider/provider.dart';

/// Dialog where a new Activity item can be created.
class AddActivityDialog extends StatelessWidget {
  final Map<String, dynamic>? editableData;

  const AddActivityDialog({super.key, this.editableData});

  Future<bool> show(BuildContext context) async {
    final AppDb db = context.read<AppDb>();
    final success = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Provider(
          create: (context) {
            final itemsProvider = context.read<ActivityItemsProvider>();
            return ActivityDialogController(db, itemsProvider.names, editableData);
          },
          child: AddActivityDialog(editableData: editableData),
        );
      },
    );
    return success ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<ActivityDialogController>();

    return AlertDialog(
      title: Text(controller.getTitle()),
      content: Form(
        key: controller.formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: controller.getInitialName(),
              decoration: InputDecoration(labelText: 'Activity Name'),
              validator: controller.validateName,
              onSaved: controller.saveName,
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
                      Navigator.pop(context, true);
                      await Provider.of<ActivityItemsProvider>(context, listen: false).refresh();
                      if (controller.editMode) {
                        // Refresh clothing in case references changed
                        await Provider.of<ClothingItemsProvider>(context, listen: false).refresh();
                      }
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
              validator: controller.validateName,
              onSaved: controller.saveName,
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
                      Navigator.pop(context, true);
                      await Provider.of<CategoryItemsProvider>(context, listen: false).refresh();
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
           final double? normX = field.value?.dx;
           final double? normY = field.value?.dy;
           final coordinatesValid = field.errorText == null;

           return Column(
             children: [
               Text(
                 'Tap on the figure to select coordinates,\n'
                 'x=${normX?.toStringAsFixed(2) ?? '--'}, y=${normY?.toStringAsFixed(2) ?? '--'}',
                 textAlign: TextAlign.center,
                 style: TextStyle(
                   color: coordinatesValid
                       ? Theme.of(context).textTheme.bodyMedium?.color
                       : Theme.of(context).colorScheme.error,
                 ),
               ),
               const SizedBox(height: 8),
               SizedBox(
                 width: 300,
                 height: 300,
                 child: Mannequin(
                   onTap: (normalizedOffset) => field.didChange(normalizedOffset),
                   isInteractiveMode: true,
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
        return Provider(create: (_) => ClothingDialogController(db), child: AddClothingDialog());
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
                    items: provider.names
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
                        await Provider.of<ClothingItemsProvider>(context, listen: false).refresh();
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
  Map<String, dynamic>? editableData,
}) async {
  switch (tableName) {
    case 'activities':
      return await AddActivityDialog(editableData: editableData).show(context);
    case 'categories':
      return await AddCategoryDialog().show(context);
    case 'clothing':
      return await AddClothingDialog().show(context);
  }
  throw Exception("Unknown table name $tableName");
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
