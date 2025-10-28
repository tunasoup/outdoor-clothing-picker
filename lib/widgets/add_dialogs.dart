import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:outdoor_clothing_picker/backend/item_controllers.dart';
import 'package:outdoor_clothing_picker/backend/items_provider.dart';
import 'package:outdoor_clothing_picker/database/database.dart';
import 'package:outdoor_clothing_picker/widgets/mannequin.dart';
import 'package:provider/provider.dart';

/// Dialog where a new Activity item can be created or provided [editableData] modified.
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

/// Dialog where a new Category item can be created or provided [editableData] modified.
/// The user is prompted to click a spot on a figure for filling the data.
class AddCategoryDialog extends StatelessWidget {
  final Map<String, dynamic>? editableData;

  AddCategoryDialog({super.key, this.editableData});

  final Size size = Size(100, 200);

  Future<bool> show(BuildContext context) async {
    final AppDb db = context.read<AppDb>();
    final success = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Provider(
          create: (context) {
            final itemsProvider = context.read<CategoryItemsProvider>();
            return CategoryDialogController(db, itemsProvider.names, editableData);
          },
          child: AddCategoryDialog(editableData: editableData),
        );
      },
    );
    return success ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<CategoryDialogController>();

    return AlertDialog(
      title: Text(controller.getTitle()),
      content: Form(
        key: controller.formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: controller.getInitialName(),
              decoration: InputDecoration(labelText: 'Category Name'),
              validator: controller.validateName,
              onSaved: controller.saveName,
              autofocus: true,
            ),
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

/// Custom Form Field with a tappable figure of [size] to obtain normalized coordinates.
class InteractiveFigureFormField extends FormField<Offset> {
  InteractiveFigureFormField({
    super.key,
    required this.context,
    required this.size,
    required this.controller,
    AutovalidateMode super.autovalidateMode = AutovalidateMode.disabled,
  }) : super(
         initialValue: controller.getInitialCoords(),
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
                   initialCirclePosition: controller.getInitialCoords(),
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

/// Dialog where a new Clothing item can be created.
class AddClothingDialog extends StatelessWidget {
  final Map<String, dynamic>? editableData;

  const AddClothingDialog({super.key, this.editableData});

  Future<bool> show(BuildContext context) async {
    final AppDb db = context.read<AppDb>();
    // TODO: disable or add a warning if there are no categories or activities
    final success = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Provider(
          create: (_) => ClothingDialogController(db, editableData),
          child: AddClothingDialog(),
        );
      },
    );
    return success ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<ClothingDialogController>();

    return AlertDialog(
      title: Text(controller.getTitle()),
      content: SingleChildScrollView(
        child: Form(
          key: controller.formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: controller.getInitialName(),
                decoration: InputDecoration(labelText: 'Name'),
                validator: controller.validateName,
                onSaved: controller.saveName,
              ),
              TextFormField(
                initialValue: controller.getInitialMinTemp()?.toString(),
                decoration: InputDecoration(labelText: 'Min Temperature'),
                validator: controller.validateMinTemp,
                onSaved: controller.saveMinTemp,
                keyboardType: TextInputType.numberWithOptions(signed: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*'))],
              ),
              TextFormField(
                initialValue: controller.getInitialMaxTemp()?.toString(),
                decoration: InputDecoration(labelText: 'Max Temperature'),
                validator: controller.validateMaxTemp,
                onSaved: controller.saveMaxTemp,
                keyboardType: TextInputType.numberWithOptions(signed: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*'))],
              ),
              Consumer<CategoryItemsProvider>(
                builder: (context, provider, _) {
                  return DropdownButtonFormField<String>(
                    initialValue: controller.getInitialCategory(),
                    decoration: InputDecoration(labelText: 'Category'),
                    validator: controller.validateDropdown,
                    items: provider.names
                        .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                    onSaved: controller.saveCategory,
                    onChanged: (_) {},
                  );
                },
              ),
              Consumer<ActivityItemsProvider>(
                builder: (context, provider, _) {
                  return DropdownButtonFormField<String>(
                    initialValue: controller.getInitialActivity(),
                    decoration: InputDecoration(hintText: 'Activity'),
                    validator: controller.validateDropdown,
                    items: provider.names
                        .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                        .toList(),
                    onSaved: controller.saveActivity,
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
                      if (await controller.saveClothing()) {
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
      return await AddCategoryDialog(editableData: editableData).show(context);
    case 'clothing':
      return await AddClothingDialog(editableData: editableData).show(context);
  }
  throw Exception("Unknown table name $tableName");
}
