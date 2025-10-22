import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:outdoor_clothing_picker/backend/item_notifiers.dart';
import 'package:outdoor_clothing_picker/database/database.dart';
import 'package:outdoor_clothing_picker/widgets/addDialogs.dart';
import 'package:outdoor_clothing_picker/widgets/utils.dart';

/// The Data visualization page shows the contents of the local [db], and allows modifying it.
class DataVisualizationPage extends StatefulWidget {
  final AppDb db;

  const DataVisualizationPage({super.key, required this.db});

  @override
  State<DataVisualizationPage> createState() => _DataVisualizationPageState();
}

class _DataVisualizationPageState extends State<DataVisualizationPage> {
  late Future<Map<String, List<Map<String, dynamic>>>> _tableDataFuture;

  // TODO do not fetch all the tables as associations are not relevant to visualize twice,
  //  likely could rely on providers.
  @override
  void initState() {
    super.initState();
    _tableDataFuture = _fetchAllTableData();
  }

  Future<void> _refresh() async {
    setState(() {
      _tableDataFuture = _fetchAllTableData();
    });
  }

  Future<Map<String, List<Map<String, dynamic>>>> _fetchAllTableData() async {
    final data = <String, List<Map<String, dynamic>>>{};
    final allTables = widget.db.allTables;
    for (final table in allTables) {
      final tableName = table.actualTableName;
      final rows = await widget.db
          .customSelect('SELECT * FROM $tableName', readsFrom: {table})
          .get();
      data[tableName] = rows.map((row) => row.data).toList();
    }
    return data;
  }


  Future<void> _deleteRow(BuildContext context, ItemsProvider provider, Map<String, dynamic> data)
  async {
    if (kDebugMode) debugPrint('Delete $provider data: $data');
    int referenceCount = await provider.referencedByCount(data);
    String message = _createDeleteMessage(data, referenceCount);
    final bool confirmed = await _showDeleteAlert(context, message);
    if (confirmed) {
      await provider.deleteItem(data);
      await _refresh();
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
                TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
                ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.errorContainer,
                      foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    ) ?? false;
  }

  // TODO: implement remaining data modifications
  void _copyRow(String tableNAme, Map<String, dynamic> row) async {
    if (kDebugMode) {
      debugPrint('Copy $tableNAme row: $row');
    }
  }

  void _editRow(String tableName, Map<String, dynamic> row) {
    if (kDebugMode) {
      debugPrint('Edit $tableName row: $row');
    }
  }

ItemsProvider _getProvider(String tableName, BuildContext context) {
    switch (tableName) {
      case 'clothing':
        return Provider.of<ClothingItemsProvider>(context, listen: false);
      case 'activities':
        return Provider.of<ActivityItemsProvider>(context, listen: false);
      case 'categories':
        return Provider.of<CategoryItemsProvider>(context, listen: false);
    }
    throw Exception('No provider implemented for $tableName.');

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
        future: _tableDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final tableData = snapshot.data ?? {};
          if (tableData.isEmpty) {
            return const Center(child: Text('No data found.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: tableData.entries.map((entry) {
              final tableName = entry.key;
              final rows = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(tableName.toUpperCase(), style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          bool success = await showAddRowDialog(
                            context: context,
                            tableName: tableName,
                          );
                          if (success) _refresh();
                        },
                        child: Text('Add New'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...rows.map(
                    (row) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(row.entries.map((e) => '${e.key}: ${e.value}').join(', ')),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editRow(tableName, row),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () => _copyRow(tableName, row),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                errorWrapper(context, () async {
                                  final provider = _getProvider(tableName, context);
                                  await _deleteRow(context, provider, row);
                                });
                              }
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 32),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
