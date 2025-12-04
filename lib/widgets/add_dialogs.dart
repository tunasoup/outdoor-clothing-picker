import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:outdoor_clothing_picker/backend/dialog_viewmodel.dart';
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
            final activityProvider = context.read<ActivityItemsProvider>();
            final clothingProvider = context.read<ClothingItemsProvider>();
            return ActivityDialogViewModel(
              db: db,
              mode: mode,
              initialData: initialData,
              activityProvider: activityProvider,
              clothingProvider: clothingProvider,
            );
          },
          child: ActivityDialog(mode: mode, initialData: initialData),
        );
      },
    );
    return success ?? false;
  }

  Future<void> _submitForm(BuildContext context, ActivityDialogViewModel vm) async {
    await errorWrapper(context, () async {
      if (await vm.submitForm()) {
        Navigator.pop(context, true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<ActivityDialogViewModel>();

    return AlertDialog(
      title: Text(vm.getTitle()),
      content: Form(
        key: vm.formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: vm.initialName,
              decoration: InputDecoration(labelText: 'Activity Name'),
              validator: vm.validateName,
              onSaved: vm.saveName,
              autofocus: vm.mode == DialogMode.add,
              onFieldSubmitted: (_) async {
                if (vm.mode == DialogMode.add) {
                  await _submitForm(context, vm);
                }
              },
            ),
            if (vm.mode case DialogMode.copy || DialogMode.edit)
              CheckboxFormField(context: context, vm: vm),
            Padding(padding: EdgeInsets.all(16.0)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    await _submitForm(context, vm);
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

  const CategoryDialog({super.key, required this.mode, this.initialData});

  // Should be kept 1:1 ratio to maintain accuracy with the painting mannequin
  static const Size mannequinSize = Size(300, 300);

  Future<bool> show(BuildContext context) async {
    final AppDb db = context.read<AppDb>();
    final success = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Provider(
          create: (context) {
            final categoryProvider = context.read<CategoryItemsProvider>();
            final clothingProvider = context.read<ClothingItemsProvider>();
            return CategoryDialogViewModel(
              db: db,
              mode: mode,
              initialData: initialData,
              categoryProvider: categoryProvider,
              clothingProvider: clothingProvider,
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
    final vm = context.read<CategoryDialogViewModel>();

    return AlertDialog(
      title: Text(vm.getTitle()),
      content: Form(
        key: vm.formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: vm.initialName,
                decoration: InputDecoration(labelText: 'Category Name'),
                validator: vm.validateName,
                onSaved: vm.saveName,
                autofocus: false,
              ),
              InteractiveFigureFormField(context: context, size: mannequinSize, vm: vm),
              if (vm.mode case DialogMode.copy || DialogMode.edit)
                CheckboxFormField(context: context, vm: vm),
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
                      await errorWrapper(context, () async {
                        if (await vm.submitForm()) {
                          Navigator.pop(context, true);
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

/// Custom Form Field with a tappable figure of [size] to obtain normalized coordinates.
class InteractiveFigureFormField extends FormField<Offset> {
  InteractiveFigureFormField({
    super.key,
    required this.context,
    required this.size,
    required this.vm,
    AutovalidateMode super.autovalidateMode = AutovalidateMode.disabled,
  }) : super(
         initialValue: vm.getInitialCoords(),
         validator: (value) => vm.validateCoords(value?.dx, value?.dy),
         onSaved: (value) => vm.saveCoords(value?.dx, value?.dy),
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
                 width: size.width,
                 height: size.height,
                 child: Mannequin(
                   onTap: (normalizedOffset) => field.didChange(normalizedOffset),
                   isInteractiveMode: true,
                   initialCirclePosition: vm.getInitialCoords(),
                 ),
               ),
               buildErrorText(context, field.errorText),
             ],
           );
         },
       );

  final BuildContext context;
  final Size size;
  final CategoryDialogViewModel vm;
}

/// Dialog where a new Clothing item can be created or provided [initialData] modified.
class ClothingDialog extends StatelessWidget {
  final DialogMode mode;
  final Map<String, dynamic>? initialData;

  const ClothingDialog({super.key, required this.mode, this.initialData});
  // TODO: Indicate that empty temps are infinite in UI
  // TODO: Capital letter for all (or most) keyboards
  Future<bool> show(BuildContext context) async {
    final AppDb db = context.read<AppDb>();
    final success = await showDialog<bool>(
      context: context,
      builder: (context) {
        final clothingProvider = context.read<ClothingItemsProvider>();
        return Provider(
          create: (_) => ClothingDialogViewModel(
            db: db,
            mode: mode,
            initialData: initialData,
            clothingProvider: clothingProvider,
          ),
          child: ClothingDialog(mode: mode),
        );
      },
    );
    return success ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<ClothingDialogViewModel>();

    return AlertDialog(
      title: Text(vm.getTitle()),
      content: SingleChildScrollView(
        child: Form(
          key: vm.formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: vm.initialName,
                decoration: InputDecoration(labelText: 'Name'),
                validator: vm.validateName,
                onSaved: vm.saveName,
              ),
              TextFormField(
                initialValue: vm.initialMinTemp?.toString(),
                decoration: InputDecoration(labelText: 'Min Temperature'),
                validator: vm.validateMinTemp,
                onSaved: vm.saveMinTemp,
                keyboardType: TextInputType.numberWithOptions(signed: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*'))],
              ),
              TextFormField(
                initialValue: vm.initialMaxTemp?.toString(),
                decoration: InputDecoration(labelText: 'Max Temperature'),
                validator: vm.validateMaxTemp,
                onSaved: vm.saveMaxTemp,
                keyboardType: TextInputType.numberWithOptions(signed: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*'))],
              ),
              Consumer<CategoryItemsProvider>(
                builder: (context, provider, _) {
                  return DropdownButtonFormField<String>(
                    initialValue: vm.initialCategoryName,
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
              MultiSelectActivitiesFormField(
                initialValue: vm.initialActivities,
                validator: vm.validateMultiselect,
                onSaved: vm.saveActivities,
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
                      await errorWrapper(context, () async {
                        if (await vm.submitForm()) {
                          Navigator.pop(context, true);
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

/// Custom Form Field with a checkbox, controlled by a [vm], limited to one.
class CheckboxFormField extends FormField<bool> {
  CheckboxFormField({
    super.key,
    required this.context,
    required this.vm,
    AutovalidateMode super.autovalidateMode = AutovalidateMode.disabled,
  }) : super(
         initialValue: vm.isBoxChecked,
         validator: vm.validateCheckbox,
         onSaved: vm.saveCheckbox,
         builder: (FormFieldState<bool> state) {
           return Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               CheckboxListTile(
                 title: Text(
                   vm.getCheckboxLabel(),
                   style: TextStyle(
                     color: state.hasError
                         ? Theme.of(context).colorScheme.error
                         : Theme.of(context).textTheme.bodyMedium?.color,
                   ),
                 ),

                 contentPadding: EdgeInsets.symmetric(horizontal: 0),
                 value: vm.isBoxChecked,
                 onChanged: (v) {
                   state.didChange(v);
                   vm.checkboxChanged(v);
                 },
               ),
               buildErrorText(context, state.errorText),
             ],
           );
         },
       );

  final BuildContext context;
  final DialogViewModel vm;
}

class MultiSelectActivitiesFormField extends FormField<List<String>> {
  MultiSelectActivitiesFormField({
    super.key,
    List<String>? initialValue,
    super.onSaved,
    super.validator,
    AutovalidateMode super.autovalidateMode = AutovalidateMode.disabled,
  }) : super(
         initialValue: initialValue ?? <String>[],
         builder: (field) {
           return Consumer<ActivityItemsProvider>(
             builder: (context, provider, _) {
               return Column(
                 children: [
                   const SizedBox(height: 8),
                   Text('Activities', style: Theme.of(context).textTheme.bodyLarge),
                   const SizedBox(height: 8),
                   // Scrollable area
                   Container(
                     constraints: const BoxConstraints(maxHeight: 100, maxWidth: 300),
                     child: SingleChildScrollView(
                       child: Wrap(
                         spacing: 8,
                         runSpacing: 4,
                         children: provider.names.map((act) {
                           final isSelected = field.value!.contains(act);
                           return FilterChip(
                             label: Text(act),
                             selected: isSelected,
                             showCheckmark: false,
                             onSelected: (selected) {
                               final newSelected = List<String>.from(field.value!);
                               if (selected) {
                                 newSelected.add(act);
                               } else {
                                 newSelected.remove(act);
                               }
                               field.didChange(newSelected);
                             },
                           );
                         }).toList(),
                       ),
                     ),
                   ),
                   buildErrorText(context, field.errorText),
                 ],
               );
             },
           );
         },
       );
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
