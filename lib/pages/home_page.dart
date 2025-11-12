import 'package:flutter/material.dart';
import 'package:outdoor_clothing_picker/backend/theme.dart';
import 'package:outdoor_clothing_picker/database/database.dart';
import 'package:outdoor_clothing_picker/pages/clothing_page.dart';
import 'package:outdoor_clothing_picker/pages/data_visualization_page.dart';
import 'package:outdoor_clothing_picker/pages/settings_page.dart';
import 'package:outdoor_clothing_picker/widgets/navigation.dart';
import 'package:provider/provider.dart';

/// Parent widget for the real pages, managing navigation.
class HomePage extends StatefulWidget {
  final AppDb db;

  const HomePage({super.key, required this.db});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentPageIndex = 0;
  bool wideScreen = false;

  late final List<Widget> pages = [
    ClothingPage(), // Landing page
    DataVisualizationPage(),
    const SettingsPage(),
  ];

  void onIndexChanged(int index) {
    setState(() {
      currentPageIndex = index;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final double width = MediaQuery.of(context).size.width;
    wideScreen = width > 600;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: wideScreen
          ? Row(
              children: [
                buildNavigationRail(context, onIndexChanged, currentPageIndex),
                Expanded(child: pages[currentPageIndex]),
              ],
            )
          : pages[currentPageIndex],
      bottomNavigationBar: wideScreen
          ? null
          : buildNavigationBar(context, onIndexChanged, currentPageIndex),
    );
  }
}
