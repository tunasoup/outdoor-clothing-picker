import 'package:flutter/material.dart';

const List<NavigationDestination> destinations = <NavigationDestination>[
  NavigationDestination(
    icon: Icon(Icons.man),
    selectedIcon: Icon(Icons.man_outlined),
    label: 'Clothing',
  ),
  NavigationDestination(
    icon: Icon(Icons.storage),
    selectedIcon: Icon(Icons.storage_outlined),
    label: 'Database',
  ),
  NavigationDestination(
    icon: Icon(Icons.settings),
    selectedIcon: Icon(Icons.settings_outlined),
    label: 'Settings',
  ),
];

List<NavigationRailDestination> navigationRailDestinations = destinations
    .map(
      (d) => NavigationRailDestination(
        icon: d.icon,
        selectedIcon: d.selectedIcon,
        label: Text(d.label),
      ),
    )
    .toList();

Widget buildNavigationRail(
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

Widget buildNavigationBar(
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
