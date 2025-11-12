import 'package:flutter/material.dart';
import 'package:outdoor_clothing_picker/backend/clothing_viewmodel.dart';
import 'package:outdoor_clothing_picker/backend/dialog_controller.dart';
import 'package:outdoor_clothing_picker/backend/items_provider.dart';
import 'package:outdoor_clothing_picker/backend/weather_viewmodel.dart';
import 'package:outdoor_clothing_picker/widgets/add_dialogs.dart';
import 'package:outdoor_clothing_picker/widgets/mannequin.dart';
import 'package:outdoor_clothing_picker/widgets/utils.dart';
import 'package:outdoor_clothing_picker/widgets/weather_widget.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;

/// The clothing page visualizes which clothings from a local database would be appropriate
/// for the current/selected weather, while allowing the user to add new items.
class ClothingPage extends StatefulWidget {
  const ClothingPage({super.key});

  @override
  State<ClothingPage> createState() => _ClothingPageState();
}

class _ClothingPageState extends State<ClothingPage> {
  final GlobalKey _fabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Prevent right-click context menu on web
    html.document.onContextMenu.listen((event) => event.preventDefault());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        key: _fabKey,
        onPressed: () => showAddMenu(context: context, anchorKey: _fabKey),
        child: Icon(Icons.add),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async =>
              errorWrapper(context, () => context.read<WeatherViewModel>().refresh()),
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

/// Menu for starting the creation of items to the [db].
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

  // If user selected an item
  if (selected != null) {
    bool success = await showRowDialog(
      context: context,
      tableName: selected,
      mode: DialogMode.add,
    );
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Added $selected successfully')));
    }
  }
}

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
        return DropdownButtonFormField<String>(
          initialValue: initialValue,
          items: provider.names
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(labelText: text),
        );
      },
    );
  }
}
