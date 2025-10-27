// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:outdoor_clothing_picker/database/database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDb(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  // The following template shows how to write tests ensuring your migrations
  // preserve existing data.
  // Testing this can be useful for migrations that change existing columns
  // (e.g. by alterating their type or constraints). Migrations that only add
  // tables or columns typically don't need these advanced tests. For more
  // information, see https://drift.simonbinder.eu/migrations/tests/#verifying-data-integrity
  test('migration from v1 to v2 does not corrupt data', () async {
    // Add data to insert into the old database, and the expected rows after the
    // migration.
    final oldCategoriesData = <v1.CategoriesData>[v1.CategoriesData(name: "Torso", normX: 0.0,
        normY: 0.5)];
    final expectedNewCategoriesData = <v2.CategoriesData>[v2.CategoriesData(id: 1, name: "Torso",
        normX: 0.0, normY: 0.5)];

    final oldActivitiesData = <v1.ActivitiesData>[v1.ActivitiesData(name: 'Running')];
    final expectedNewActivitiesData = <v2.ActivitiesData>[v2.ActivitiesData(id: 1, name: 'Running'
        '')];

    final oldClothingData = <v1.ClothingData>[v1.ClothingData(id: 1, name: "Clothing", minTemp:
    2, maxTemp: 5, category: "Torso", activity: "Running")];
    final expectedNewClothingData = <v2.ClothingData>[v2.ClothingData(id: 1, name: "Clothing",
        minTemp: 2, maxTemp: 5, category: "Torso", activity: "Running")];

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: AppDb.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.categories, oldCategoriesData);
        batch.insertAll(oldDb.activities, oldActivitiesData);
        batch.insertAll(oldDb.clothing, oldClothingData);
      },
      validateItems: (newDb) async {
        expect(
          expectedNewCategoriesData,
          await newDb.select(newDb.categories).get(),
        );
        expect(
          expectedNewActivitiesData,
          await newDb.select(newDb.activities).get(),
        );
        expect(
          expectedNewClothingData,
          await newDb.select(newDb.clothing).get(),
        );
      },
    );
  });
}
