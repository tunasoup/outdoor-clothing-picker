// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outdoor_clothing_picker/database/database.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;

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
  final v1ActivitiesData = [v1.ActivitiesData(name: 'Running')];
  final v2ActivitiesData = [v2.ActivitiesData(id: 1, name: 'Running')];
  final v3ActivitiesData = [v3.ActivitiesData(id: 1, name: 'Running')];

  final v1CategoriesData = [
    v1.CategoriesData(name: "Torso", normX: 0.0, normY: 0.5),
  ];
  final v2CategoriesData = [
    v2.CategoriesData(id: 1, name: "Torso", normX: 0.0, normY: 0.5),
  ];
  final v3CategoriesData = [
    v3.CategoriesData(id: 1, name: "Torso", normX: 0.0, normY: 0.5),
  ];

  final v1ClothingData = [
    v1.ClothingData(
      id: 1,
      name: "Clothing",
      minTemp: 2,
      maxTemp: 5,
      category: "Torso",
      activity: "Running",
    ),
  ];
  final v2ClothingData = [
    v2.ClothingData(
      id: 1,
      name: "Clothing",
      minTemp: 2,
      maxTemp: 5,
      category: "Torso",
      activity: "Running",
    ),
  ];
  final v3ClothingData = <v3.ClothingData>[
    v3.ClothingData(
      id: 1,
      name: "Clothing",
      minTemp: 2,
      maxTemp: 5,
      categoryId: 1,
    ),
  ];

  final v3ClothingActivitiesData = [v3.ClothingActivitiesData(clothingId: 1, activityId: 1)];

  // The following template shows how to write tests ensuring your migrations
  // preserve existing data.
  // Testing this can be useful for migrations that change existing columns
  // (e.g. by alterating their type or constraints). Migrations that only add
  // tables or columns typically don't need these advanced tests. For more
  // information, see https://drift.simonbinder.eu/migrations/tests/#verifying-data-integrity
  test('migration from v1 to v2 does not corrupt data', () async {
    // Add data to insert into the old database, and the expected rows after the migration.
    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: AppDb.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.categories, v1CategoriesData);
        batch.insertAll(oldDb.activities, v1ActivitiesData);
        batch.insertAll(oldDb.clothing, v1ClothingData);
      },
      validateItems: (newDb) async {
        expect(v2CategoriesData, await newDb.select(newDb.categories).get());
        expect(v2ActivitiesData, await newDb.select(newDb.activities).get());
        expect(v2ClothingData, await newDb.select(newDb.clothing).get());
      },
    );
  });

  test('migration from v2 to v3 does not corrupt data', () async {
    await verifier.testWithDataIntegrity(
      oldVersion: 2,
      newVersion: 3,
      createOld: v2.DatabaseAtV2.new,
      createNew: v3.DatabaseAtV3.new,
      openTestedDatabase: AppDb.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.categories, v2CategoriesData);
        batch.insertAll(oldDb.activities, v2ActivitiesData);
        batch.insertAll(oldDb.clothing, v2ClothingData);
      },
      validateItems: (newDb) async {
        expect(v3CategoriesData, await newDb.select(newDb.categories).get());
        expect(v3ActivitiesData, await newDb.select(newDb.activities).get());
        expect(v3ClothingData, await newDb.select(newDb.clothing).get());
        expect(v3ClothingActivitiesData, await newDb.select(newDb.clothingActivities).get());
      },
    );
  });
}
