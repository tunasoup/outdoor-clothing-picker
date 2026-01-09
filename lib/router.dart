import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:outdoor_clothing_picker/core/configs/settings.dart';
import 'package:outdoor_clothing_picker/features/clother/clothing_page.dart';
import 'package:outdoor_clothing_picker/features/clother/clothing_viewmodel.dart';
import 'package:outdoor_clothing_picker/features/clother/weather_config_page.dart';
import 'package:outdoor_clothing_picker/features/clother/weather_viewmodel.dart';
import 'package:outdoor_clothing_picker/features/database_editor/data_visualization_page.dart';
import 'package:outdoor_clothing_picker/features/settings/settings_page.dart';
import 'package:outdoor_clothing_picker/features/settings/settings_viewmodel.dart';
import 'package:provider/provider.dart';

import './routes.dart';

// Set landing page, find its index by matching route name and label
final homeRoute = Routes.clothing;
final homeIndex = destinations.indexWhere(
  (dest) => homeRoute.toLowerCase().contains(dest.label.toLowerCase()),
);

// FIXME: First time opening of a tab is really slow
final goRouter = GoRouter(
  initialLocation: homeRoute,
  debugLogDiagnostics: true,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainScaffold(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: Routes.database, builder: (context, state) => DataVisualizationPage()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.clothing,
              builder: (context, state) {
                final weatherVM = WeatherViewModel(weatherRepository: context.read());
                final clothingVM = ClothingViewModel(
                  clothingRepository: context.read(),
                  weatherViewModel: weatherVM,
                );
                return ClothingPage(viewModel: clothingVM);
              },
              routes: [
                // FIXME: Going to and from a subroute recreates earlier VMs
                GoRoute(
                  path: Routes.forecastConfigsRelative,
                  builder: (context, state) => WeatherConfigPage(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.settings,
              builder: (context, state) {
                final settingsVM = SettingsViewModel(settingsRepository: context.read());
                return SettingsPage(viewModel: settingsVM);
              },
            ),
          ],
        ),
      ],
    ),
  ],
);

class MainScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    // FIXME: FAB/snackbar syngergy breaks again (multiple scaffolds)
    // FIXME: settings do not immediately take effect on other tabs
    // Setting Directionality at this level does not affect widgets such as alert dialogs and
    // MaterialPageRoutes, but most of their contents should not change anyway for left-handed
    // mode, rather, buttons and such should be modified manually
    return Selector<SettingsProvider, TextDirection>(
      selector: (_, p) => p.textDirection,
      builder: (context, textDirection, _) {
        return Directionality(
          textDirection: textDirection,
          child: PopScope(
            // On back press go to home page, or close app (default pop) if there
            canPop: navigationShell.currentIndex == homeIndex,
            onPopInvokedWithResult: (bool didPop, Object? result) {
              debugPrint('main didPop: $didPop, result: $result');
              if (navigationShell.currentIndex != homeIndex) {
                navigationShell.goBranch(homeIndex);
              }
            },
            child: LayoutBuilder(
              // Show NavigationRail instead of a bar on wide web views and on landscape
              builder: (context, constraints) {
                if ((kIsWeb && constraints.maxWidth > 600) ||
                    MediaQuery.orientationOf(context) == Orientation.landscape) {
                  return _buildRailScaffold(context, navigationShell);
                } else {
                  return _buildBarScaffold(context, navigationShell);
                }
              },
            ),
          ),
        );
      },
    );
  }

  void _onTap(int index) {
    // Pressing the same index icon closes a possible subroute
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  }

  Scaffold _buildBarScaffold(BuildContext context, StatefulNavigationShell shell) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: buildNavigationBar(context, _onTap, shell.currentIndex),
    );
  }

  Scaffold _buildRailScaffold(BuildContext context, StatefulNavigationShell shell) {
    return Scaffold(
      body: Row(
        children: [
          buildNavigationRail(context, _onTap, shell.currentIndex),
          Expanded(child: shell),
        ],
      ),
    );
  }
}

/// Define pages for navigation widgets.
const List<NavigationDestination> destinations = <NavigationDestination>[
  NavigationDestination(
    icon: Icon(Icons.storage),
    selectedIcon: Icon(Icons.storage_outlined),
    label: 'Database',
  ),
  NavigationDestination(
    icon: Icon(Icons.man),
    selectedIcon: Icon(Icons.man_outlined),
    label: 'Clothing',
  ),
  NavigationDestination(
    icon: Icon(Icons.settings),
    selectedIcon: Icon(Icons.settings_outlined),
    label: 'Settings',
  ),
];

/// Convert navigation destinations for use in Navigation Rail.
List<NavigationRailDestination> navigationRailDestinations = destinations
    .map(
      (d) => NavigationRailDestination(
        icon: d.icon,
        selectedIcon: d.selectedIcon,
        label: Text(d.label),
      ),
    )
    .toList();

NavigationRail buildNavigationRail(
  BuildContext context,
  void Function(int) onDestinationSelected,
  int selectedIndex,
) {
  return NavigationRail(
    selectedIndex: selectedIndex,
    onDestinationSelected: onDestinationSelected,
    labelType: NavigationRailLabelType.all,
    destinations: navigationRailDestinations,
    indicatorColor: Theme.of(context).colorScheme.primaryContainer,
    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
  );
}

NavigationBar buildNavigationBar(
  BuildContext context,
  void Function(int) onDestinationSelected,
  int selectedIndex,
) {
  return NavigationBar(
    selectedIndex: selectedIndex,
    onDestinationSelected: onDestinationSelected,
    destinations: destinations,
    indicatorColor: Theme.of(context).colorScheme.primaryContainer,
    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
    animationDuration: Duration(seconds: 1),
    labelTextStyle: WidgetStateProperty.all(
      TextStyle(
        color: Theme.of(context).colorScheme.onSecondaryContainer,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
