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
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SelectionProvider(),
      child: Scaffold(
        appBar: DataAppBar(),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [ActivityDataView(), CategoryDataView(), ClothingDataView()],
        ),
      ),
    );
  }
}

class DataAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DataAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final selectionProvider = context.watch<SelectionProvider>();
    final isSelectionMode = selectionProvider.isSelectionMode;

    return AppBar(
      title: isSelectionMode
          ? Row(
              children: [
                Text(
                  '${selectionProvider.selectedCount}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            )
          : const Text('Data'),
      leading: isSelectionMode
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    selectionProvider.allSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                  ),
                  tooltip: selectionProvider.allSelected ? 'Cancel selection' : 'Select all',
                  onPressed: () {
                    if (selectionProvider.allSelected) {
                      selectionProvider.clearSelection();
                    } else {
                      selectionProvider.selectAllVisible();
                    }
                  },
                ),
                // const Text('All', style: TextStyle(fontSize: 12)),
              ],
            )
          : null,
      actions: [
        if (isSelectionMode)
          IconButton(
            icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
            tooltip: 'Delete selected',
            onPressed: () async {
              final count = selectionProvider.selectedCount;
              if (count == 1) {
                selectionProvider.selectedItems.forEach((dataView, ids) {
                  errorWrapper(context, () async {
                    // FIXME: singular should have a distinct confirmation alert, but not trigger
                    //  when more tables are selected as well
                    await dataView.deleteRows(context, ids);
                  });
                });
              } else if (count > 1) {
                // TODO: deletion message for multiple items
                final bool confirmed = await showDeleteAlert(context, 'Delete $count items?');
                if (confirmed) {
                  selectionProvider.selectedItems.forEach((dataView, ids) {
                    errorWrapper(context, () async {
                      await dataView.deleteRows(context, ids);
                    });
                  });
                }
              }
              selectionProvider.clearSelection();
            },
          )
        else
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () {
              // TODO: implement search
            },
          ),
      ],
    );
  }
}

Future<void> deleteRow(BuildContext context, ItemsProvider provider, int rowId) async {
  if (kDebugMode) debugPrint('Delete $provider data: $rowId');
  int referenceCount = await provider.referencedByCount(rowId);
  String message = createDeleteMessage(rowId, referenceCount);
  final bool confirmed = await showDeleteAlert(context, message);
  if (confirmed) {
    await provider.deleteItem(rowId);
    // Also refresh clothing table due to references
    if (referenceCount > 0 && provider.runtimeType != ClothingItemsProvider) {
      await context.read<ClothingItemsProvider>().refresh();
    }
  }
}

Future<void> deleteRows(BuildContext context, ItemsProvider provider, int rowId) async {
  if (kDebugMode) debugPrint('Delete $provider data: $rowId');
  int referenceCount = await provider.referencedByCount(rowId);
  String message = createDeleteMessage(rowId, referenceCount);
  final bool confirmed = await showDeleteAlert(context, message);
  if (confirmed) {
    await provider.deleteItem(rowId);
    // Also refresh clothing table due to references
    if (referenceCount > 0 && provider.runtimeType != ClothingItemsProvider) {
      await context.read<ClothingItemsProvider>().refresh();
    }
  }
}

String createDeleteMessage(int id, int referenceCount) {
  // TODO include whole data contents and not just id
  String msg = 'You are about to delete the following data item:';
  msg += '\n$id';
  if (referenceCount > 0) {
    msg += '\nThe item affects $referenceCount clothing item(s).';
  }
  msg += '\nAre you sure?';
  return msg;
}

Future<bool> showDeleteAlert(BuildContext context, String message) async {
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

Future<void> copyRow(
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

Future<void> editRow(
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

  String get tableName;

  ItemsProvider _getProvider(BuildContext context, bool listen);

  Future<void> deleteRows(BuildContext context, Iterable<int> rowIds) async {
    if (rowIds.isEmpty) return;
    final provider = _getProvider(context, false);
    await provider.deleteItems(rowIds.toList());
  }

  String _cardText(Map<String, dynamic> row) {
    return row.entries
        .map((e) {
          return '${e.key}: ${e.value}';
        })
        .join(', ');
  }

  Widget _buildDataRow(BuildContext context, Map<String, dynamic> row, ItemsProvider provider) {
    final rowId = row['id'] as int;

    // FIXME something closer to root causes unnecessary rebuilds
    // FIXME Selector disables rebuild of checkmarks when isSelectionMode changes
    // Use a selector to avoid rebuild when selection has not changed
    return Selector<SelectionProvider, bool>(
      selector: (_, selProvider) => selProvider.isSelected(this, rowId),
      builder: (_, isSelected, _) {
        final selection = context.read<SelectionProvider>();
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text('${row['name']}'),
            subtitle: Text(_cardText(row)),
            selected: isSelected,
            onLongPress: () => selection.toggleSelection(this, rowId),
            onTap: () {
              if (selection.isSelectionMode) {
                selection.toggleSelection(this, rowId);
              } else {
                errorWrapper(context, () async {
                  await editRow(context, provider, row, tableName.toLowerCase());
                });
              }
            },
            trailing: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: selection.isSelectionMode
                  ? Icon(
                      isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = _getProvider(context, true);
    final selectionProvider = context.read<SelectionProvider>();
    final rows = provider.itemList;
    // TODO filter rows according to an optional query

    // Update provider (in the next frame) with currently visible rows for this table
    final visibleIds = rows.map((row) => row['id'] as int).toSet();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      selectionProvider.updateVisibleItems(this, visibleIds);
    });

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
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              child: const Text('Add New'),
            ),
          ],
        ),
        Padding(padding: EdgeInsets.symmetric(vertical: 4)),
        if (provider.isLoading)
          Center(child: CircularProgressIndicator())
        else if (rows.isEmpty)
          Text('No data')
        else
          ...rows.map((row) => _buildDataRow(context, row, provider)),
        const Divider(height: 32),
      ],
    );
  }
}

class ActivityDataView extends DataView {
  const ActivityDataView({super.key});

  @override
  String get tableName => "Activities";

  @override
  ItemsProvider _getProvider(BuildContext context, bool listen) =>
      Provider.of<ActivityItemsProvider>(context, listen: listen);
}

class CategoryDataView extends DataView {
  const CategoryDataView({super.key});

  @override
  String get tableName => "Categories";

  @override
  ItemsProvider _getProvider(BuildContext context, bool listen) =>
      Provider.of<CategoryItemsProvider>(context, listen: listen);
}

class ClothingDataView extends DataView {
  const ClothingDataView({super.key});

  @override
  String get tableName => "Clothing";

  @override
  ItemsProvider _getProvider(BuildContext context, bool listen) =>
      Provider.of<ClothingItemsProvider>(context, listen: listen);

  @override
  String _cardText(Map<String, dynamic> row) {
    return row.entries
        .map((e) {
          final key = e.key;
          final value = e.value;
          if (key == 'min_temp' && value == null) return '$key: -inf';
          if (key == 'max_temp' && value == null) return '$key: inf';
          if (key == 'activities') return '$key: ${value?.join(', ')}';
          return '$key: $value';
        })
        .join(', ');
  }
}

class SelectionProvider extends ChangeNotifier {
  // Key: table, value: set of row IDs
  final Map<DataView, Set<int>> visibleItems = {};
  final Map<DataView, Set<int>> selectedItems = {};

  bool isSelected(DataView table, int rowId) => selectedItems[table]?.contains(rowId) ?? false;

  bool get isSelectionMode => selectedItems.values.any((set) => set.isNotEmpty);

  // Total selected rows across all tables
  int get selectedCount => selectedItems.values.fold(0, (sum, set) => sum + set.length);

  // Total visible rows across all tables
  int get visibleCount => visibleItems.values.fold(0, (sum, set) => sum + set.length);

  bool get allSelected =>
      visibleCount > 0 &&
      visibleItems.entries.every(
        (entry) => selectedItems[entry.key]?.containsAll(entry.value) ?? false,
      );

  void updateVisibleItems(DataView table, Set<int> ids) {
    final oldIds = visibleItems[table] ?? {};
    if (!setEquals(oldIds, ids)) {
      visibleItems[table] = ids;
      notifyListeners(); // Only trigger if changed
    }
  }

  void toggleSelection(DataView table, int rowId) {
    selectedItems.putIfAbsent(table, () => {});
    if (selectedItems[table]!.contains(rowId)) {
      selectedItems[table]!.remove(rowId);
    } else {
      selectedItems[table]!.add(rowId);
    }
    notifyListeners();
  }

  void selectAllVisible() {
    for (var entry in visibleItems.entries) {
      selectedItems.putIfAbsent(entry.key, () => {});
      selectedItems[entry.key]!.addAll(entry.value);
    }
    notifyListeners();
  }

  void clearSelection() {
    selectedItems.clear();
    notifyListeners();
  }
}
