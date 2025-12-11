import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:outdoor_clothing_picker/core/configs/settings.dart';
import 'package:outdoor_clothing_picker/core/ui/app_page.dart';
import 'package:outdoor_clothing_picker/features/clother/clothing_page.dart';
import 'package:outdoor_clothing_picker/features/database_editor/data_visualization_page.dart';
import 'package:outdoor_clothing_picker/features/settings/settings_page.dart';
import 'package:outdoor_clothing_picker/core/ui/navigation.dart';
import 'package:provider/provider.dart';

/// Parent widget for the real UI pages, managing navigation.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentPageIndex = 0;
  bool isWideScreen = false;

  late final List<AppPage Function(NavigationBar? navBar)> pages = [
    // First page is the landing page
    (bottomNav) => ClothingPage(bottomNavigationBar: bottomNav),
    (bottomNav) => DataVisualizationPage(bottomNavigationBar: bottomNav),
    (bottomNav) => SettingsPage(bottomNavigationBar: bottomNav),
  ];

  void onIndexChanged(int index) {
    setState(() {
      currentPageIndex = index;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (kIsWeb) {
      final double width = MediaQuery.of(context).size.width;
      isWideScreen = width > 600;
    } else {
      isWideScreen = MediaQuery.orientationOf(context) == Orientation.landscape;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomNavigationBar = isWideScreen
        ? null
        : buildNavigationBar(context, onIndexChanged, currentPageIndex);
    final page = pages[currentPageIndex](bottomNavigationBar);
    final textDirection = Provider.of<SettingsProvider>(context, listen: true).textDirection;

    // Setting Directionality at this level does not affect widgets such as alert dialogs and
    // MaterialPageRoutes, but most of their contents should not change anyway for left-handed
    // mode, rather, buttons and such should be modified manually
    return Directionality(
      textDirection: textDirection,
      child: isWideScreen
          ? Row(
              children: [
                buildNavigationRail(context, onIndexChanged, currentPageIndex),
                Expanded(child: page),
              ],
            )
          : page,
    );
  }
}
