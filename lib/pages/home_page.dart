import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:outdoor_clothing_picker/pages/app_page.dart';
import 'package:outdoor_clothing_picker/pages/clothing_page.dart';
import 'package:outdoor_clothing_picker/pages/data_visualization_page.dart';
import 'package:outdoor_clothing_picker/pages/settings_page.dart';
import 'package:outdoor_clothing_picker/widgets/navigation.dart';

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

    return isWideScreen
        ? Row(
            children: [
              buildNavigationRail(context, onIndexChanged, currentPageIndex),
              Expanded(child: page),
            ],
          )
        : page;
  }
}
