import 'package:flutter/material.dart';

/// Each [AppPage] should include a Scaffold in their build method with bottomNavigationBar
/// attribute set to the [bottomNavigationBar].
abstract class AppPage extends StatefulWidget {
  final NavigationBar? bottomNavigationBar;
  const AppPage({super.key, required this.bottomNavigationBar});
}
