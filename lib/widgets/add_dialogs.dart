import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:outdoor_clothing_picker/backend/dialog_controller.dart';
import 'package:outdoor_clothing_picker/backend/items_provider.dart';
import 'package:outdoor_clothing_picker/database/database.dart';
import 'package:outdoor_clothing_picker/widgets/mannequin.dart';
import 'package:outdoor_clothing_picker/widgets/utils.dart';
import 'package:provider/provider.dart';

/// Dialog where a new Activity item can be created or provided [initialData] modified.
class ActivityDialog extends StatelessWidget {
  final DialogMode mode;
  final Map<String, dynamic>? initialData;

  const ActivityDialog({super.key, required this.mode, this.initialData});

  Future<bool> show(BuildContext context) async {
    final AppDb db = context.read<AppDb>();
    final success = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Provider(
          create: (context) {
            final itemsProvider = context.read<ActivityItemsProvider>();
            return ActivityDialogController(
              db: db,
              mode: mode,
              initialData: initialData,
              availableActivities: itemsProvider.names,
            );
          },
          child: ActivityDialog(mode: mode, initialData: initialData),
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
            if (controller.mode case DialogMode.copy || DialogMode.edit)
              CheckboxFormField(context: context, controller: controller),
            Padding(padding: EdgeInsets.all(16.0)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    errorWrapper(context, () async {
                      if (await controller.submitForm()) {
                        Navigator.pop(context, true);
                        await Provider.of<ActivityItemsProvider>(context, listen: false).refresh();
                        if (controller.mode != DialogMode.add) {
                          // Refresh clothing in case references changed
                          await Provider.of<ClothingItemsProvider>(
                            context,
                            listen: false,
                          ).refresh();
                        }
                      }
                    });
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

/// Dialog where a new Category item can be created or provided [initialData] modified.
/// The user is prompted to click a spot on a figure for filling some of the data.
class CategoryDialog extends StatelessWidget {
  final DialogMode mode;
  final Map<String, dynamic>? initialData;

  CategoryDialog({super.key, required this.mode, this.initialData});

  final Size size = Size(100, 200);

  Future<bool> show(BuildContext context) async {
    final AppDb db = context.read<AppDb>();
    final success = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Provider(
          create: (context) {
            final itemsProvider = context.read<CategoryItemsProvider>();
            return CategoryDialogController(
              db: db,
              mode: mode,
              initialData: initialData,
              availableCategories: itemsProvider.names,
            );
          },
          child: CategoryDialog(mode: mode, initialData: initialData),
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
                  onPressed: () {
                    errorWrapper(context, () async {
                      if (await controller.submitForm()) {
                        Navigator.pop(context, true);
                        await Provider.of<CategoryItemsProvider>(context, listen: false).refresh();
                        if (controller.mode != DialogMode.add) {
                          // Refresh clothing in case references changed
                          await Provider.of<ClothingItemsProvider>(
                            context,
                            listen: false,
                          ).refresh();
                        }
                      }
                    });
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
               buildErrorText(context, field.errorText),
             ],
           );
         },
       );

  final BuildContext context;
  final Size size;
  final CategoryDialogController controller;
}

/// Dialog where a new Clothing item can be created or provided [initialData] modified.
class ClothingDialog extends StatelessWidget {
  final DialogMode mode;
  final Map<String, dynamic>? initialData;

  const ClothingDialog({super.key, required this.mode, this.initialData});

  Future<bool> show(BuildContext context) async {
    final AppDb db = context.read<AppDb>();
    // TODO: disable or add a warning if there are no categories or activities
    final success = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Provider(
          create: (_) => ClothingDialogController(db: db, mode: mode, initialData: initialData),
          child: ClothingDialog(mode: mode),
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
                    onPressed: () {
                      errorWrapper(context, () async {
                        if (await controller.submitForm()) {
                          Navigator.pop(context, true);
                          await Provider.of<ClothingItemsProvider>(
                            context,
                            listen: false,
                          ).refresh();
                        }
                      });
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

/// Custom Form Field with a checkbox, controlled by a [controller], limited to one.
class CheckboxFormField extends FormField<bool> {
  CheckboxFormField({
    super.key,
    required this.context,
    required this.controller,
    AutovalidateMode super.autovalidateMode = AutovalidateMode.disabled,
  }) : super(
         initialValue: controller.isBoxChecked,
         validator: controller.validateCheckbox,
         onSaved: controller.saveCheckbox,
         builder: (FormFieldState<bool> state) {
           return Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               CheckboxListTile(
                 title: Text(
                   controller.getCheckboxLabel(),
                   style: TextStyle(
                     color: state.hasError
                         ? Theme.of(context).colorScheme.error
                         : Theme.of(context).textTheme.bodyMedium?.color,
                   ),
                 ),

                 contentPadding: EdgeInsets.symmetric(horizontal: 0),
                 value: controller.isBoxChecked,
                 onChanged: (v) {
                   state.didChange(v);
                   controller.checkboxChanged(v);
                 },
               ),
               buildErrorText(context, state.errorText),
             ],
           );
         },
       );

  final BuildContext context;
  final DialogController controller;
}

/// Show [errorText]] if it exists, meant for failed validation on custom Form Fields.
Widget buildErrorText(BuildContext context, String? errorText) {
  if (errorText == null) return const SizedBox.shrink();

  return Padding(
    padding: const EdgeInsets.only(top: 2.0, left: 2.0),
    child: Text(
      errorText,
      style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
    ),
  );
}

/// Show a dialog for adding/modifying (dictated by [mode]) a row's data for database's
/// [tableName]. Certain actions expect specific keys in [initialData].
Future<bool> showRowDialog({
  required BuildContext context,
  required String tableName,
  required DialogMode mode,
  Map<String, dynamic>? initialData,
}) async {
  switch (tableName) {
    case 'activities':
      return await ActivityDialog(mode: mode, initialData: initialData).show(context);
    case 'categories':
      return await CategoryDialog(mode: mode, initialData: initialData).show(context);
    case 'clothing':
      return await ClothingDialog(mode: mode, initialData: initialData).show(context);
  }
  throw Exception("Unknown table name $tableName");
}
