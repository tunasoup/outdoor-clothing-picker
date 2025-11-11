import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:outdoor_clothing_picker/backend/dialog_controller.dart';
import 'package:outdoor_clothing_picker/backend/items_provider.dart';
import 'package:outdoor_clothing_picker/widgets/add_dialogs.dart';
import 'package:outdoor_clothing_picker/widgets/utils.dart';
import 'package:provider/provider.dart';

/// The Data visualization page shows the contents of the local data and allows modifying it.
class DataVisualizationPage extends StatefulWidget {
  const DataVisualizationPage({super.key});

  @override
  State<DataVisualizationPage> createState() => _DataVisualizationPageState();
}

class _DataVisualizationPageState extends State<DataVisualizationPage> {
  // TODO allow selecting and modifying multiple items at the same time
  // TODO change modification icon buttons to something cleane
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [ActivityDataView(), CategoryDataView(), ClothingDataView()],
      ),
    );
  }
}

Future<void> _deleteRow(
  BuildContext context,
  ItemsProvider provider,
  Map<String, dynamic> data,
) async {
  if (kDebugMode) debugPrint('Delete $provider data: $data');
  int referenceCount = await provider.referencedByCount(data);
  String message = _createDeleteMessage(data, referenceCount);
  final bool confirmed = await _showDeleteAlert(context, message);
  if (confirmed) {
    await provider.deleteItem(data);
    // Also refresh clothing table due to references
    if (referenceCount > 0 && provider.runtimeType != ClothingItemsProvider) {
      await Provider.of<ClothingItemsProvider>(context, listen: false).refresh();
    }
  }
}

String _createDeleteMessage(Map<String, dynamic> data, int referenceCount) {
  String msg = 'You are about to delete the following data item:';
  msg += '\n$data';
  if (referenceCount > 0) {
    msg += '\nThe item affects $referenceCount clothing item(s).';
  }
  msg += '\nAre you sure?';
  return msg;
}

Future<bool> _showDeleteAlert(BuildContext context, String message) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Confirm Deletion',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              Padding(padding: EdgeInsets.all(16.0)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.errorContainer,
                      foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ) ??
      false;
}

Future<void> _copyRow(
  BuildContext context,
  ItemsProvider provider,
  Map<String, dynamic> data,
  String tableName,
) async {
  if (kDebugMode) debugPrint('Copy $provider data: $data');
  await showRowDialog(
    context: context,
    tableName: tableName.toLowerCase(),
    mode: DialogMode.copy,
    initialData: data,
  );
}

Future<void> _editRow(
  BuildContext context,
  ItemsProvider provider,
  Map<String, dynamic> data,
  String tableName,
) async {
  if (kDebugMode) debugPrint('Edit $provider data: $data');
  await showRowDialog(
    context: context,
    tableName: tableName.toLowerCase(),
    mode: DialogMode.edit,
    initialData: data,
  );
}

abstract class DataView extends StatelessWidget {
  const DataView({super.key});

  ItemsProvider _getProvider(BuildContext context);

  String _cardText(Map<String, dynamic> row) {
    return row.entries
        .map((e) {
          return '${e.key}: ${e.value}';
        })
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final provider = _getProvider(context);
    final tableName = provider.tableName;
    final rows = provider.itemList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(tableName.toUpperCase(), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: provider.isLoading
                  ? null
                  : () async {
                      await showRowDialog(
                        context: context,
                        tableName: tableName.toLowerCase(),
                        mode: DialogMode.add,
                      );
                    },
              child: const Text('Add New'),
            ),
          ],
        ),
        Padding(padding: EdgeInsets.symmetric(vertical: 8)),
        if (provider.isLoading)
          Center(child: CircularProgressIndicator())
        else if (rows.isEmpty)
          Text('No data')
        else
          ...rows.map(
            (row) => Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: Text(_cardText(row)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        errorWrapper(context, () async {
                          await _editRow(context, provider, row, tableName.toLowerCase());
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        errorWrapper(context, () async {
                          await _copyRow(context, provider, row, tableName.toLowerCase());
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        errorWrapper(context, () async {
                          await _deleteRow(context, provider, row);
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        const Divider(height: 32),
      ],
    );
  }
}

class ActivityDataView extends DataView {
  const ActivityDataView({super.key});

  @override
  ItemsProvider _getProvider(BuildContext context) => context.watch<ActivityItemsProvider>();
}

class CategoryDataView extends DataView {
  const CategoryDataView({super.key});

  @override
  ItemsProvider _getProvider(BuildContext context) => context.watch<CategoryItemsProvider>();
}

class ClothingDataView extends DataView {
  const ClothingDataView({super.key});

  @override
  ItemsProvider _getProvider(BuildContext context) => context.watch<ClothingItemsProvider>();

  @override
  String _cardText(Map<String, dynamic> row) {
    // TODO list activities and change category id to name, provider is not enough,
    //  also need category names and clothing activity info
    return row.entries
        .map((e) {
          final key = e.key;
          final value = e.value;
          if (key == 'min_temp' && value == null) return '$key: -inf';
          if (key == 'max_temp' && value == null) return '$key: inf';
          return '$key: $value';
        })
        .join(', ');
  }
}
