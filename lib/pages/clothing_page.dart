import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:outdoor_clothing_picker/backend/clothing_viewmodel.dart';
import 'package:outdoor_clothing_picker/backend/dialog_viewmodel.dart';
import 'package:outdoor_clothing_picker/backend/items_provider.dart';
import 'package:outdoor_clothing_picker/backend/settings.dart';
import 'package:outdoor_clothing_picker/backend/weather_viewmodel.dart';
import 'package:outdoor_clothing_picker/pages/app_page.dart';
import 'package:outdoor_clothing_picker/widgets/add_dialogs.dart';
import 'package:outdoor_clothing_picker/widgets/mannequin.dart';
import 'package:outdoor_clothing_picker/widgets/utils.dart';
import 'package:outdoor_clothing_picker/widgets/weather_widget.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;

/// The clothing page visualizes which clothings from a local database would be appropriate
/// for the current/selected weather, while allowing the user to add new items.
class ClothingPage extends AppPage {
  const ClothingPage({super.key, super.bottomNavigationBar});

  @override
  State<ClothingPage> createState() => _ClothingPageState();
}

class _ClothingPageState extends State<ClothingPage> {
  final _fabKey = GlobalKey<ExpandableFabState>();

  @override
  void initState() {
    super.initState();
    // Prevent right-click context menu on web
    html.document.onContextMenu.listen((event) => event.preventDefault());
  }

  Future<void> startAddDialog(BuildContext context, String tableName) async {
    bool success = await showRowDialog(
      context: context,
      tableName: tableName,
      mode: DialogMode.add,
    );
    if (success) {
      showSnackBar(context: context, text: 'Item added successfully', seconds: 3);
    }
  }

  void toggleFABState() {
    final state = _fabKey.currentState;
    if (state != null) {
      state.toggle();
    }
  }

  ExpandableFab createEFAB({required BuildContext context}) {
    final isLeftHanded = context.read<SettingsProvider>().isLeftHanded;
    final pos = isLeftHanded ? ExpandableFabPos.left : ExpandableFabPos.right;
    return ExpandableFab(
      key: _fabKey,
      pos: pos,
      type: ExpandableFabType.up,
      childrenAnimation: ExpandableFabAnimation.none,
      distance: 70,
      overlayStyle: ExpandableFabOverlayStyle(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
      ),
      openButtonBuilder: RotateFloatingActionButtonBuilder(
        child: const Icon(Icons.add),
        fabSize: ExpandableFabSize.regular,
      ),
      children: [
        // TODO: 3rd party icon for clothing
        createEFABChild(
          context: context,
          text: 'Clothing',
          tableName: 'clothing',
          icon: Icons.inventory,
        ),
        createEFABChild(
          context: context,
          text: 'Category',
          tableName: 'categories',
          icon: Icons.man,
        ),
        createEFABChild(
          context: context,
          text: 'Activity',
          tableName: 'activities',
          icon: Icons.directions_run,
        ),
      ],
    );
  }

  Widget createEFABChild({
    required BuildContext context,
    required String text,
    required String tableName,
    required IconData icon,
  }) {
    return Row(
      children: [
        Text(text),
        const SizedBox(width: 10),
        FloatingActionButton.small(
          onPressed: () async {
            await startAddDialog(context, tableName);
            // Need to close after the dialog, otherwise the animation breaks a possible autofocus
            toggleFABState();
          },
          heroTag: text,
          child: Icon(icon),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: widget.bottomNavigationBar,
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: createEFAB(context: context),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async =>
              await errorWrapper(context, () => context.read<WeatherViewModel>().refresh()),
          child: SingleChildScrollView(
            // Required by refresh indicator for large screens
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 16,
              children: [
                const WeatherWidget(),
                SizedBox(
                  width: 200,
                  child: ActivityDropdown(
                    initialValue: context.watch<ClothingViewModel>().activity,
                    onChanged: (value) =>
                        context.read<ClothingViewModel>().setActivity(activity: value),
                  ),
                ),
                const SizedBox(height: 400, child: Mannequin()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Menu for starting the creation of items to the database.
Future<void> showAddMenu({required BuildContext context, required GlobalKey anchorKey}) async {
  // Get the position of the button to anchor the menu
  final RenderBox renderBox = anchorKey.currentContext!.findRenderObject() as RenderBox;
  final Offset offset = renderBox.localToGlobal(Offset.zero);
  final Size size = renderBox.size;

  // Show the popup menu manually
  final selected = await showMenu<String>(
    context: context,
    position: RelativeRect.fromLTRB(
      offset.dx,
      offset.dy,
      offset.dx + size.width,
      offset.dy + size.height,
    ),
    items: const [
      PopupMenuItem(value: 'activities', child: Text('Add Activity')),
      PopupMenuItem(value: 'categories', child: Text('Add Category')),
      PopupMenuItem(value: 'clothing', child: Text('Add Clothing Item')),
    ],
  );

  // Open user selected dialog
  if (selected != null) {
    bool success = await showRowDialog(
      context: context,
      tableName: selected,
      mode: DialogMode.add,
    );
    if (success) {
      showSnackBar(context: context, text: 'Added $selected successfully');
    }
  }
}

/// Dropdown for the user to choose the selected activity for clothing filtering.
class ActivityDropdown extends StatelessWidget {
  final String? initialValue;
  final void Function(String?) onChanged;
  final String? text;

  const ActivityDropdown({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.text = 'Selected Activity',
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityItemsProvider>(
      builder: (context, ActivityItemsProvider provider, _) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: DropdownButtonFormField<String>(
            initialValue: initialValue,
            items:
                (provider.names.toList()
                      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())))
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(item, overflow: TextOverflow.clip),
                      ),
                    )
                    .toList(),
            onChanged: onChanged,
            isExpanded: true,
            decoration: InputDecoration(labelText: text),
          ),
        );
      },
    );
  }
}
