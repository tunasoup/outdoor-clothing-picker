import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:outdoor_clothing_picker/core/configs/settings.dart';
import 'package:outdoor_clothing_picker/core/database/items_provider.dart';
import 'package:outdoor_clothing_picker/core/ui/add_dialog/add_dialogs.dart';
import 'package:outdoor_clothing_picker/core/ui/add_dialog/dialog_viewmodel.dart';
import 'package:outdoor_clothing_picker/core/ui/app_page.dart';
import 'package:outdoor_clothing_picker/core/ui/mannequin.dart';
import 'package:outdoor_clothing_picker/core/ui/ui_helpers.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;

import './clothing_viewmodel.dart';
import './weather_widget.dart';

/// The clothing page visualizes which clothings from a local database would be appropriate
/// for the current/selected weather, while allowing the user to add new items.
class ClothingPage extends AppPage {
  final ClothingViewModel viewModel;

  const ClothingPage({super.key, super.bottomNavigationBar, required this.viewModel});

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
          onRefresh: () async => await errorWrapper(context, () => widget.viewModel.refresh()),
          child: SingleChildScrollView(
            // Required by refresh indicator for large screens
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: ListenableBuilder(
              listenable: widget.viewModel,
              builder: (context, _) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 16,
                  children: [
                    WeatherWidget(viewModel: widget.viewModel.weatherViewModel),
                    SizedBox(
                      width: 200,
                      child: ActivityDropdown(
                        initialValue: widget.viewModel.activity,
                        onChanged: widget.viewModel.setActivity,
                      ),
                    ),
                    SizedBox(
                      height: 400,
                      child: Mannequin(clothing: widget.viewModel.filteredClothing),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
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
