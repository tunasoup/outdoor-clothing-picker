import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:outdoor_clothing_picker/widgets/app_drawer.dart';
import 'package:outdoor_clothing_picker/database/database.dart';
import 'package:outdoor_clothing_picker/widgets/utils.dart';

/// The Data visualization page shows the contents of the local [db], and allows modifying it.
class DataVisualizationPage extends StatefulWidget {
  final AppDb db;

  const DataVisualizationPage({super.key, required this.db});

  @override
  State<DataVisualizationPage> createState() =>
      _DataVisualizationPageState();
}

class _DataVisualizationPageState
    extends State<DataVisualizationPage> {
  late Future<Map<String, List<Map<String, dynamic>>>> _tableDataFuture;

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

  // TODO: implement data modifications
  void _deleteRow(String tableName, int id) async {
    if (kDebugMode) {
      debugPrint('Delete $tableName id: $id');
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Database Viewer')),
      drawer: const AppDrawer(),
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
                      Text(
                        tableName.toUpperCase(),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          await showAddRowDialog(
                            context: context,
                            tableName: tableName,
                            db: widget.db,
                            onRowAdded: _refresh,
                          );
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
                        title: Text(
                          row.entries
                              .map((e) => '${e.key}: ${e.value}')
                              .join(', '),
                        ),
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
                                final id = row['id'];
                                if (id is int) {
                                  _deleteRow(tableName, id);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Cannot delete row: No ID field.',
                                      ),
                                    ),
                                  );
                                }
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
            }).toList(),
          );
        },
      ),
    );
  }
}