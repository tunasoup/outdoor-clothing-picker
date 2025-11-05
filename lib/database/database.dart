import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'database.steps.dart';

part 'database.g.dart';

@DriftDatabase(include: {'tables.drift'})
class AppDb extends _$AppDb {
  AppDb([QueryExecutor? e])
    : super(
        e ??
            driftDatabase(
              name: 'outdoor-clothing-picker-app',
              native: const DriftNativeOptions(databaseDirectory: getApplicationSupportDirectory),
              web: DriftWebOptions(
                sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                driftWorker: Uri.parse('drift_worker.js'),
                onResult: (result) {
                  if (result.missingFeatures.isNotEmpty) {
                    debugPrint(
                      'Using ${result.chosenImplementation} due to unsupported '
                      'browser features: ${result.missingFeatures}',
                    );
                  }
                },
              ),
            ),
      );

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');

      // Insert default data
      if (kDebugMode && details.wasCreated) {
        await createDefaultActivities();
        await createDefaultCategories();
        await createDefaultClothing();
        await createDefaultActivityLinks();
      }
    },
    onUpgrade: _schemaUpgrade,
  );
}

extension Migrations on GeneratedDatabase {
  // Extracting the `stepByStep` call into a static field or method ensures that you're not
  // accidentally referring to the current database schema (via a getter on the database class).
  // This ensures that each step brings the database into the correct snapshot.
  OnUpgrade get _schemaUpgrade => stepByStep(
    // Add autoincrementing primary keys to 2 tables
    from1To2: (Migrator m, Schema2 schema) async {
      await customStatement('PRAGMA foreign_keys = OFF;');

      await customStatement('''
        CREATE TABLE categories_temp (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          norm_x REAL NOT NULL,
          norm_y REAL NOT NULL
        );
      ''');

      await customStatement('''
        INSERT INTO categories_temp (name, norm_x, norm_y)
        SELECT name, norm_x, norm_y FROM categories;
      ''');

      await m.deleteTable('categories');
      await customStatement('ALTER TABLE categories_temp RENAME TO categories;');

      await customStatement('''
        CREATE TABLE activities_temp (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE
        );
      ''');

      await customStatement('''
        INSERT INTO activities_temp (name)
        SELECT name FROM activities;
      ''');

      await m.deleteTable('activities');
      await customStatement('ALTER TABLE activities_temp RENAME TO activities;');
    },
    from2To3: (Migrator m, Schema3 schema) async {
      await customStatement('PRAGMA foreign_keys = OFF;');
      await m.alterTable(TableMigration(schema.clothing));
    },
  );
}
