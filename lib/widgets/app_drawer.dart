import 'package:flutter/material.dart';

/// Drawer for navigation.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
            child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(
            title: Text('Clothing Picker'),
            onTap: () {
              Navigator.pop(context);
              if (ModalRoute.of(context)?.settings.name != '/clothing') {
                Navigator.pushNamed(context, '/clothing');
              }
            },
          ),
          ListTile(
            title: Text('Database Visualization'),
            onTap: () {
              Navigator.pop(context);
              if (ModalRoute.of(context)?.settings.name != '/database') {
                Navigator.pushNamed(context, '/database');
              }
            },
          ),
        ],
      ),
    );
  }
}
