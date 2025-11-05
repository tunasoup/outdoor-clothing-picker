// dart format width=80
// GENERATED CODE, DO NOT EDIT BY HAND.
// ignore_for_file: type=lint
import 'package:drift/drift.dart';

class Categories extends Table with TableInfo<Categories, CategoriesData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Categories(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    true,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY AUTOINCREMENT',
  );
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE',
  );
  late final GeneratedColumn<double> normX = GeneratedColumn<double>(
    'norm_x',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  late final GeneratedColumn<double> normY = GeneratedColumn<double>(
    'norm_y',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, normX, normY];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoriesData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoriesData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      normX: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}norm_x'],
      )!,
      normY: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}norm_y'],
      )!,
    );
  }

  @override
  Categories createAlias(String alias) {
    return Categories(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class CategoriesData extends DataClass implements Insertable<CategoriesData> {
  final int? id;
  final String name;
  final double normX;
  final double normY;
  const CategoriesData({
    this.id,
    required this.name,
    required this.normX,
    required this.normY,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<int>(id);
    }
    map['name'] = Variable<String>(name);
    map['norm_x'] = Variable<double>(normX);
    map['norm_y'] = Variable<double>(normY);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      name: Value(name),
      normX: Value(normX),
      normY: Value(normY),
    );
  }

  factory CategoriesData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoriesData(
      id: serializer.fromJson<int?>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      normX: serializer.fromJson<double>(json['normX']),
      normY: serializer.fromJson<double>(json['normY']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int?>(id),
      'name': serializer.toJson<String>(name),
      'normX': serializer.toJson<double>(normX),
      'normY': serializer.toJson<double>(normY),
    };
  }

  CategoriesData copyWith({
    Value<int?> id = const Value.absent(),
    String? name,
    double? normX,
    double? normY,
  }) => CategoriesData(
    id: id.present ? id.value : this.id,
    name: name ?? this.name,
    normX: normX ?? this.normX,
    normY: normY ?? this.normY,
  );
  CategoriesData copyWithCompanion(CategoriesCompanion data) {
    return CategoriesData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      normX: data.normX.present ? data.normX.value : this.normX,
      normY: data.normY.present ? data.normY.value : this.normY,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('normX: $normX, ')
          ..write('normY: $normY')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, normX, normY);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoriesData &&
          other.id == this.id &&
          other.name == this.name &&
          other.normX == this.normX &&
          other.normY == this.normY);
}

class CategoriesCompanion extends UpdateCompanion<CategoriesData> {
  final Value<int?> id;
  final Value<String> name;
  final Value<double> normX;
  final Value<double> normY;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.normX = const Value.absent(),
    this.normY = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required double normX,
    required double normY,
  }) : name = Value(name),
       normX = Value(normX),
       normY = Value(normY);
  static Insertable<CategoriesData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<double>? normX,
    Expression<double>? normY,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (normX != null) 'norm_x': normX,
      if (normY != null) 'norm_y': normY,
    });
  }

  CategoriesCompanion copyWith({
    Value<int?>? id,
    Value<String>? name,
    Value<double>? normX,
    Value<double>? normY,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      normX: normX ?? this.normX,
      normY: normY ?? this.normY,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (normX.present) {
      map['norm_x'] = Variable<double>(normX.value);
    }
    if (normY.present) {
      map['norm_y'] = Variable<double>(normY.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('normX: $normX, ')
          ..write('normY: $normY')
          ..write(')'))
        .toString();
  }
}

class Activities extends Table with TableInfo<Activities, ActivitiesData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Activities(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    true,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY AUTOINCREMENT',
  );
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE',
  );
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activities';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ActivitiesData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActivitiesData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  Activities createAlias(String alias) {
    return Activities(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class ActivitiesData extends DataClass implements Insertable<ActivitiesData> {
  final int? id;
  final String name;
  const ActivitiesData({this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<int>(id);
    }
    map['name'] = Variable<String>(name);
    return map;
  }

  ActivitiesCompanion toCompanion(bool nullToAbsent) {
    return ActivitiesCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      name: Value(name),
    );
  }

  factory ActivitiesData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActivitiesData(
      id: serializer.fromJson<int?>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int?>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  ActivitiesData copyWith({
    Value<int?> id = const Value.absent(),
    String? name,
  }) => ActivitiesData(
    id: id.present ? id.value : this.id,
    name: name ?? this.name,
  );
  ActivitiesData copyWithCompanion(ActivitiesCompanion data) {
    return ActivitiesData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActivitiesData(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivitiesData &&
          other.id == this.id &&
          other.name == this.name);
}

class ActivitiesCompanion extends UpdateCompanion<ActivitiesData> {
  final Value<int?> id;
  final Value<String> name;
  const ActivitiesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  ActivitiesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
  }) : name = Value(name);
  static Insertable<ActivitiesData> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  ActivitiesCompanion copyWith({Value<int?>? id, Value<String>? name}) {
    return ActivitiesCompanion(id: id ?? this.id, name: name ?? this.name);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivitiesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class Clothing extends Table with TableInfo<Clothing, ClothingData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Clothing(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    true,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY AUTOINCREMENT',
  );
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  late final GeneratedColumn<int> minTemp = GeneratedColumn<int>(
    'min_temp',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  late final GeneratedColumn<int> maxTemp = GeneratedColumn<int>(
    'max_temp',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'REFERENCES categories(name)ON UPDATE CASCADE ON DELETE SET NULL',
  );
  late final GeneratedColumn<String> activity = GeneratedColumn<String>(
    'activity',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'REFERENCES activities(name)ON UPDATE CASCADE ON DELETE SET NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    minTemp,
    maxTemp,
    category,
    activity,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clothing';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClothingData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClothingData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      minTemp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}min_temp'],
      ),
      maxTemp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_temp'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      activity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity'],
      ),
    );
  }

  @override
  Clothing createAlias(String alias) {
    return Clothing(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class ClothingData extends DataClass implements Insertable<ClothingData> {
  final int? id;
  final String name;
  final int? minTemp;
  final int? maxTemp;
  final String? category;
  final String? activity;
  const ClothingData({
    this.id,
    required this.name,
    this.minTemp,
    this.maxTemp,
    this.category,
    this.activity,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<int>(id);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || minTemp != null) {
      map['min_temp'] = Variable<int>(minTemp);
    }
    if (!nullToAbsent || maxTemp != null) {
      map['max_temp'] = Variable<int>(maxTemp);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || activity != null) {
      map['activity'] = Variable<String>(activity);
    }
    return map;
  }

  ClothingCompanion toCompanion(bool nullToAbsent) {
    return ClothingCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      name: Value(name),
      minTemp: minTemp == null && nullToAbsent
          ? const Value.absent()
          : Value(minTemp),
      maxTemp: maxTemp == null && nullToAbsent
          ? const Value.absent()
          : Value(maxTemp),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      activity: activity == null && nullToAbsent
          ? const Value.absent()
          : Value(activity),
    );
  }

  factory ClothingData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClothingData(
      id: serializer.fromJson<int?>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      minTemp: serializer.fromJson<int?>(json['minTemp']),
      maxTemp: serializer.fromJson<int?>(json['maxTemp']),
      category: serializer.fromJson<String?>(json['category']),
      activity: serializer.fromJson<String?>(json['activity']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int?>(id),
      'name': serializer.toJson<String>(name),
      'minTemp': serializer.toJson<int?>(minTemp),
      'maxTemp': serializer.toJson<int?>(maxTemp),
      'category': serializer.toJson<String?>(category),
      'activity': serializer.toJson<String?>(activity),
    };
  }

  ClothingData copyWith({
    Value<int?> id = const Value.absent(),
    String? name,
    Value<int?> minTemp = const Value.absent(),
    Value<int?> maxTemp = const Value.absent(),
    Value<String?> category = const Value.absent(),
    Value<String?> activity = const Value.absent(),
  }) => ClothingData(
    id: id.present ? id.value : this.id,
    name: name ?? this.name,
    minTemp: minTemp.present ? minTemp.value : this.minTemp,
    maxTemp: maxTemp.present ? maxTemp.value : this.maxTemp,
    category: category.present ? category.value : this.category,
    activity: activity.present ? activity.value : this.activity,
  );
  ClothingData copyWithCompanion(ClothingCompanion data) {
    return ClothingData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      minTemp: data.minTemp.present ? data.minTemp.value : this.minTemp,
      maxTemp: data.maxTemp.present ? data.maxTemp.value : this.maxTemp,
      category: data.category.present ? data.category.value : this.category,
      activity: data.activity.present ? data.activity.value : this.activity,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClothingData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('minTemp: $minTemp, ')
          ..write('maxTemp: $maxTemp, ')
          ..write('category: $category, ')
          ..write('activity: $activity')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, minTemp, maxTemp, category, activity);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClothingData &&
          other.id == this.id &&
          other.name == this.name &&
          other.minTemp == this.minTemp &&
          other.maxTemp == this.maxTemp &&
          other.category == this.category &&
          other.activity == this.activity);
}

class ClothingCompanion extends UpdateCompanion<ClothingData> {
  final Value<int?> id;
  final Value<String> name;
  final Value<int?> minTemp;
  final Value<int?> maxTemp;
  final Value<String?> category;
  final Value<String?> activity;
  const ClothingCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.minTemp = const Value.absent(),
    this.maxTemp = const Value.absent(),
    this.category = const Value.absent(),
    this.activity = const Value.absent(),
  });
  ClothingCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.minTemp = const Value.absent(),
    this.maxTemp = const Value.absent(),
    this.category = const Value.absent(),
    this.activity = const Value.absent(),
  }) : name = Value(name);
  static Insertable<ClothingData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? minTemp,
    Expression<int>? maxTemp,
    Expression<String>? category,
    Expression<String>? activity,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (minTemp != null) 'min_temp': minTemp,
      if (maxTemp != null) 'max_temp': maxTemp,
      if (category != null) 'category': category,
      if (activity != null) 'activity': activity,
    });
  }

  ClothingCompanion copyWith({
    Value<int?>? id,
    Value<String>? name,
    Value<int?>? minTemp,
    Value<int?>? maxTemp,
    Value<String?>? category,
    Value<String?>? activity,
  }) {
    return ClothingCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      minTemp: minTemp ?? this.minTemp,
      maxTemp: maxTemp ?? this.maxTemp,
      category: category ?? this.category,
      activity: activity ?? this.activity,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (minTemp.present) {
      map['min_temp'] = Variable<int>(minTemp.value);
    }
    if (maxTemp.present) {
      map['max_temp'] = Variable<int>(maxTemp.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (activity.present) {
      map['activity'] = Variable<String>(activity.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClothingCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('minTemp: $minTemp, ')
          ..write('maxTemp: $maxTemp, ')
          ..write('category: $category, ')
          ..write('activity: $activity')
          ..write(')'))
        .toString();
  }
}

class DatabaseAtV3 extends GeneratedDatabase {
  DatabaseAtV3(QueryExecutor e) : super(e);
  late final Categories categories = Categories(this);
  late final Activities activities = Activities(this);
  late final Clothing clothing = Clothing(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    categories,
    activities,
    clothing,
  ];
  @override
  int get schemaVersion => 3;
}
