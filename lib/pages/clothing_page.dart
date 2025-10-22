import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;

import 'package:outdoor_clothing_picker/backend/clothing_viewmodel.dart';
import 'package:outdoor_clothing_picker/backend/item_notifiers.dart';
import 'package:outdoor_clothing_picker/database/database.dart';
import 'package:outdoor_clothing_picker/widgets/addDialogs.dart';
import 'package:outdoor_clothing_picker/widgets/mannequin.dart';
import 'package:outdoor_clothing_picker/widgets/weather_widget.dart';

/// The clothing page visualizes which clothings from a local database would be appropriate
/// for the current/selected weather, while allowing the user to add new items.
class ClothingPage extends StatefulWidget {
  const ClothingPage({super.key, required this.title});

  final String title;

  @override
  State<ClothingPage> createState() => _ClothingPageState();
}

class _ClothingPageState extends State<ClothingPage> {
  List<ClothingData> items = [];
  final GlobalKey _fabKey = GlobalKey();
  int selectedIndex = 0;
  bool useRail = false;

  @override
  void initState() {
    super.initState();
    // Prevent right-click context menu on web
    html.document.onContextMenu.listen((event) => event.preventDefault());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // TODO: alone does not prevent resize
      floatingActionButton: FloatingActionButton(
        key: _fabKey,
        onPressed: () => showAddMenu(context: context, anchorKey: _fabKey),
        child: Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const WeatherWidget(),
            const SizedBox(height: 32),
            const Text('Select activity:'),
            SizedBox(
              width: 200,
              child: ActivityDropdown(
                initialValue: context.read<ClothingViewModel>().activity,
                onChanged: (value) => context.read<ClothingViewModel>().setActivity(value),
              ),
            ),
            Expanded(child: const Mannequin()),
          ],
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
      PopupMenuItem(value: 'clothing', child: Text('Add Clothing Item')),
      PopupMenuItem(value: 'activities', child: Text('Add Activity')),
      PopupMenuItem(value: 'categories', child: Text('Add Category')),
    ],
  );

  // If user selected an item
  if (selected != null) {
    bool success = await showAddRowDialog(context: context, tableName: selected);
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

  const ActivityDropdown({super.key, this.initialValue, required this.onChanged});

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
          decoration: InputDecoration(hintText: 'Activity'),
        );
      },
    );
  }
}
