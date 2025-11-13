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
  String? searchQuery;

  void _searchCallback(String query) {
    setState(() => searchQuery = query);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SelectionProvider(),
      child: Scaffold(
        appBar: DataAppBar(searchCallback: _searchCallback),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ActivityDataView(searchQuery: searchQuery),
            CategoryDataView(searchQuery: searchQuery),
            ClothingDataView(searchQuery: searchQuery),
          ],
        ),
      ),
    );
  }
}

class DataAppBar extends StatefulWidget implements PreferredSizeWidget {
  final ValueChanged<String> searchCallback;

  const DataAppBar({super.key, required this.searchCallback});

  @override
  State<DataAppBar> createState() => _DataAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _DataAppBarState extends State<DataAppBar> {
  bool _isSearching = false;
  bool _shouldAutofocus = false;
  final TextEditingController _searchController = TextEditingController();

  void _startSearch() {
    setState(() {
      _isSearching = true;
      _shouldAutofocus = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _shouldAutofocus = false;
      _searchController.clear();
      widget.searchCallback('');
    });
  }

  void _onSubmitted(String query) {
    _shouldAutofocus = false;
    widget.searchCallback(query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _startDuplication(BuildContext context) async {
    final selectionProvider = context.read<SelectionProvider>();
    final singleItem = selectionProvider.singleSelectedItem;
    if (singleItem == null) throw Exception('Only one item should be provided for duplication');
    final dataView = singleItem.key, rowId = singleItem.value;
    final provider = dataView.getProvider(context, false);
    final tableName = dataView.tableName;
    final item = provider.itemById(rowId);
    if (item == null) throw Exception('Got null item during duplication');
    await errorWrapper(context, () async {
      final success = await copyRow(context, provider, item, tableName);
      if (success) selectionProvider.clearSelection();
    });
  }

  Future<void> _startDeletion(BuildContext context) async {
    final selectionProvider = context.read<SelectionProvider>();
    final count = selectionProvider.selectedCount;
    if (count == 0) return;

    String? msg;
    // Show a different confirmation message for singe item deletions
    final singleItem = selectionProvider.singleSelectedItem;
    if (singleItem != null) {
      final dataView = singleItem.key, rowId = singleItem.value;
      final provider = dataView.getProvider(context, false);
      int referenceCount = await provider.referencedByCount(rowId);
      final item = provider.itemById(rowId);
      msg = createDeleteMessage(singular: item, referenceCount: referenceCount);
    } else {
      msg = createDeleteMessage(itemCount: count);
    }

    final confirmed = await showDeleteAlert(context, msg);
    if (!confirmed) return;

    for (final entry in selectionProvider.selectedItems.entries) {
      final dataView = entry.key;
      final ids = entry.value;
      await errorWrapper(context, () async {
        await dataView.getProvider(context, false).deleteItems(ids.toList());
      });
    }
    // Rebuild clothing in case its references were removed
    await context.read<ClothingItemsProvider>().refresh();
    selectionProvider.clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    final selectionProvider = context.watch<SelectionProvider>();
    final isSelectionMode = selectionProvider.isSelectionMode;

    return AppBar(
      iconTheme: IconThemeData(size: 28),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      title: isSelectionMode
          ? Row(
              children: [
                Text(
                  '${selectionProvider.selectedCount} Selected',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            )
          : _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: _shouldAutofocus,
              decoration: const InputDecoration(hintText: 'Search...', border: InputBorder.none),
              textInputAction: TextInputAction.search,
              onChanged: _onSubmitted,
            )
          : const Text('Data'),
      leading: isSelectionMode
          ? TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size(50, 50),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                if (selectionProvider.allSelected) {
                  selectionProvider.clearSelection();
                } else {
                  selectionProvider.selectAllVisible();
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    selectionProvider.allSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 28,
                  ),
                  Text('All', style: TextStyle(fontSize: 10)),
                ],
              ),
            )
          : null,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: isSelectionMode
              ? Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                      tooltip: 'Delete selected',
                      onPressed: () async {
                        await errorWrapper(context, () async {
                          await _startDeletion(context);
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.copy),
                      tooltip: 'Copy selected',
                      onPressed: selectionProvider.selectedCount != 1
                          ? null
                          : () async {
                              await errorWrapper(context, () async {
                                await _startDuplication(context);
                              });
                            },
                    ),
                  ],
                )
              : _isSearching
              ? IconButton(icon: const Icon(Icons.close), onPressed: _stopSearch)
              : IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Search',
                  onPressed: _startSearch,
                ),
        ),
      ],
    );
  }
}

String createDeleteMessage({
  int? itemCount,
  Map<String, dynamic>? singular,
  int referenceCount = 0,
}) {
  if ((itemCount == null || itemCount < 1) && singular == null) {
    throw ArgumentError('Either positive itemCount or singular must be provided.');
  } else if (itemCount != null && singular != null) {
    throw ArgumentError('Only itemCount or singular must be provided.');
  }

  String msg = 'You are about to delete ';
  if (singular != null) {
    msg += 'the following data item:';
    msg += '\n$singular';
    if (referenceCount > 0) {
      msg += '\nThe item affects $referenceCount clothing item(s).';
    }
  } else {
    msg += '$itemCount items.';
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

Future<bool> copyRow(
  BuildContext context,
  ItemsProvider provider,
  Map<String, dynamic> data,
  String tableName,
) async {
  if (kDebugMode) debugPrint('Copy $provider data: $data');
  return await showRowDialog(
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
  final String? searchQuery;

  const DataView({super.key, this.searchQuery});

  String get tableName;

  ItemsProvider getProvider(BuildContext context, bool listen);

  String _cardText(Map<String, dynamic> row) {
    return row.entries
        .map(modifyRowEntry)
        .where((e) => e != null) // Remove skipped pairs
        .map((e) => '${e!.key}: ${e.value}')
        .join(', ');
  }

  MapEntry<String, dynamic>? modifyRowEntry(MapEntry<String, dynamic> entry) {
    final base = _applyBaseRules(entry);
    if (base == null) return null;
    return rowEntryRules(base);
  }

  MapEntry<String, dynamic>? _applyBaseRules(MapEntry<String, dynamic> entry) {
    // Hide id in release
    if (entry.key == 'id' && !kDebugMode) return null;
    return entry;
  }

  /// OVerridable custom rules for children
  MapEntry<String, dynamic>? rowEntryRules(MapEntry<String, dynamic> entry) => entry;

  List<Map<String, dynamic>> filterByAnyValue(
    List<Map<String, dynamic>> items,
    String? searchQuery,
  ) {
    if (searchQuery == null || searchQuery.isEmpty) return items;

    final query = searchQuery.toLowerCase();

    return items.where((item) {
      // Check if any value contains the query
      return item.values.any((value) {
        if (value == null) return false;
        return value.toString().toLowerCase().contains(query);
      });
    }).toList();
  }

  Widget _buildDataRow(BuildContext context, Map<String, dynamic> row, ItemsProvider provider) {
    final selection = Provider.of<SelectionProvider>(context);
    final rowId = row['id'] as int;

    final isSelected = selection.isSelected(this, rowId);

    // FIXME something closer to root causes unnecessary rebuilds
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text('${row['name']}'),
        subtitle: Text(_cardText(row)),
        selected: isSelected,
        onLongPress: () => selection.toggleSelection(this, rowId),
        onTap: () async {
          if (selection.isSelectionMode) {
            selection.toggleSelection(this, rowId);
          } else {
            await errorWrapper(context, () async {
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
  }

  @override
  Widget build(BuildContext context) {
    final provider = getProvider(context, true);
    final selectionProvider = context.read<SelectionProvider>();
    List<Map<String, dynamic>> rows = provider.itemList;
    rows = filterByAnyValue(rows, searchQuery);

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
  const ActivityDataView({super.key, super.searchQuery});

  @override
  String get tableName => "Activities";

  @override
  ItemsProvider getProvider(BuildContext context, bool listen) =>
      Provider.of<ActivityItemsProvider>(context, listen: listen);
}

class CategoryDataView extends DataView {
  const CategoryDataView({super.key, super.searchQuery});

  @override
  String get tableName => "Categories";

  @override
  ItemsProvider getProvider(BuildContext context, bool listen) =>
      Provider.of<CategoryItemsProvider>(context, listen: listen);
}

class ClothingDataView extends DataView {
  const ClothingDataView({super.key, super.searchQuery});

  @override
  String get tableName => "Clothing";

  @override
  ItemsProvider getProvider(BuildContext context, bool listen) =>
      Provider.of<ClothingItemsProvider>(context, listen: listen);

  @override
  MapEntry<String, dynamic>? rowEntryRules(MapEntry<String, dynamic> entry) {
    String key = entry.key;
    dynamic value = entry.value;
    if (key == 'min_temp' && value == null) {
      value = '-inf';
    } else if (key == 'max_temp' && value == null) {
      value = 'inf';
    } else if (key == 'activities') {
      value = '${value?.join(', ')}';
    }
    return MapEntry(key, value);
  }
}

class SelectionProvider extends ChangeNotifier {
  // Key: table provider, value: set of row IDs
  final Map<DataView, Set<int>> visibleItems = {};
  final Map<DataView, Set<int>> selectedItems = {};

  bool isSelected(DataView key, int rowId) => selectedItems[key]?.contains(rowId) ?? false;

  bool get isSelectionMode => selectedItems.values.any((set) => set.isNotEmpty);

  // Total selected rows across all tables
  int get selectedCount => selectedItems.values.fold(0, (sum, set) => sum + set.length);

  // Total visible rows across all tables
  int get visibleCount => visibleItems.values.fold(0, (sum, set) => sum + set.length);

  // If only a single item is selected, return its key and value
  MapEntry<DataView, int>? get singleSelectedItem {
    // Filter out empty sets
    final nonEmpty = selectedItems.entries.where((entry) => entry.value.isNotEmpty).toList();

    if (nonEmpty.length == 1 && nonEmpty.first.value.length == 1) {
      final entry = nonEmpty.first;
      return MapEntry(entry.key, entry.value.first);
    }

    return null;
  }

  bool get allSelected =>
      visibleCount > 0 &&
      visibleItems.entries.every(
        (entry) => selectedItems[entry.key]?.containsAll(entry.value) ?? false,
      );

  void updateVisibleItems(DataView key, Set<int> ids) {
    final oldIds = visibleItems[key] ?? {};
    if (!setEquals(oldIds, ids)) {
      visibleItems[key] = ids;
      notifyListeners(); // Only trigger if changed
    }
  }

  void toggleSelection(DataView key, int rowId) {
    selectedItems.putIfAbsent(key, () => {});
    if (selectedItems[key]!.contains(rowId)) {
      selectedItems[key]!.remove(rowId);
    } else {
      selectedItems[key]!.add(rowId);
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
