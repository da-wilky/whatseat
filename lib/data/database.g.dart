// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $MealEntriesTable extends MealEntries
    with TableInfo<$MealEntriesTable, MealEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MealType, int> meal =
      GeneratedColumn<int>(
        'meal',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<MealType>($MealEntriesTable.$convertermeal);
  static const VerificationMeta _startMinutesMeta = const VerificationMeta(
    'startMinutes',
  );
  @override
  late final GeneratedColumn<int> startMinutes = GeneratedColumn<int>(
    'start_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endMinutesMeta = const VerificationMeta(
    'endMinutes',
  );
  @override
  late final GeneratedColumn<int> endMinutes = GeneratedColumn<int>(
    'end_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<FoodItem>, String> items =
      GeneratedColumn<String>(
        'items',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<FoodItem>>($MealEntriesTable.$converteritems);
  static const VerificationMeta _withWhomMeta = const VerificationMeta(
    'withWhom',
  );
  @override
  late final GeneratedColumn<String> withWhom = GeneratedColumn<String>(
    'with_whom',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _appetiteForMeta = const VerificationMeta(
    'appetiteFor',
  );
  @override
  late final GeneratedColumn<String> appetiteFor = GeneratedColumn<String>(
    'appetite_for',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _situationBeforeMeta = const VerificationMeta(
    'situationBefore',
  );
  @override
  late final GeneratedColumn<String> situationBefore = GeneratedColumn<String>(
    'situation_before',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _hungerMeta = const VerificationMeta('hunger');
  @override
  late final GeneratedColumn<int> hunger = GeneratedColumn<int>(
    'hunger',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _satietyMeta = const VerificationMeta(
    'satiety',
  );
  @override
  late final GeneratedColumn<int> satiety = GeneratedColumn<int>(
    'satiety',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bingeMeta = const VerificationMeta('binge');
  @override
  late final GeneratedColumn<bool> binge = GeneratedColumn<bool>(
    'binge',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("binge" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _measuresMeta = const VerificationMeta(
    'measures',
  );
  @override
  late final GeneratedColumn<String> measures = GeneratedColumn<String>(
    'measures',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _situationAfterMeta = const VerificationMeta(
    'situationAfter',
  );
  @override
  late final GeneratedColumn<String> situationAfter = GeneratedColumn<String>(
    'situation_after',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    day,
    meal,
    startMinutes,
    endMinutes,
    items,
    withWhom,
    appetiteFor,
    situationBefore,
    hunger,
    satiety,
    binge,
    measures,
    situationAfter,
    templateId,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<MealEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('start_minutes')) {
      context.handle(
        _startMinutesMeta,
        startMinutes.isAcceptableOrUnknown(
          data['start_minutes']!,
          _startMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startMinutesMeta);
    }
    if (data.containsKey('end_minutes')) {
      context.handle(
        _endMinutesMeta,
        endMinutes.isAcceptableOrUnknown(data['end_minutes']!, _endMinutesMeta),
      );
    }
    if (data.containsKey('with_whom')) {
      context.handle(
        _withWhomMeta,
        withWhom.isAcceptableOrUnknown(data['with_whom']!, _withWhomMeta),
      );
    }
    if (data.containsKey('appetite_for')) {
      context.handle(
        _appetiteForMeta,
        appetiteFor.isAcceptableOrUnknown(
          data['appetite_for']!,
          _appetiteForMeta,
        ),
      );
    }
    if (data.containsKey('situation_before')) {
      context.handle(
        _situationBeforeMeta,
        situationBefore.isAcceptableOrUnknown(
          data['situation_before']!,
          _situationBeforeMeta,
        ),
      );
    }
    if (data.containsKey('hunger')) {
      context.handle(
        _hungerMeta,
        hunger.isAcceptableOrUnknown(data['hunger']!, _hungerMeta),
      );
    }
    if (data.containsKey('satiety')) {
      context.handle(
        _satietyMeta,
        satiety.isAcceptableOrUnknown(data['satiety']!, _satietyMeta),
      );
    }
    if (data.containsKey('binge')) {
      context.handle(
        _bingeMeta,
        binge.isAcceptableOrUnknown(data['binge']!, _bingeMeta),
      );
    }
    if (data.containsKey('measures')) {
      context.handle(
        _measuresMeta,
        measures.isAcceptableOrUnknown(data['measures']!, _measuresMeta),
      );
    }
    if (data.containsKey('situation_after')) {
      context.handle(
        _situationAfterMeta,
        situationAfter.isAcceptableOrUnknown(
          data['situation_after']!,
          _situationAfterMeta,
        ),
      );
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MealEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      meal: $MealEntriesTable.$convertermeal.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}meal'],
        )!,
      ),
      startMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_minutes'],
      )!,
      endMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_minutes'],
      ),
      items: $MealEntriesTable.$converteritems.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}items'],
        )!,
      ),
      withWhom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}with_whom'],
      )!,
      appetiteFor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}appetite_for'],
      )!,
      situationBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}situation_before'],
      )!,
      hunger: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hunger'],
      ),
      satiety: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}satiety'],
      ),
      binge: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}binge'],
      )!,
      measures: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}measures'],
      )!,
      situationAfter: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}situation_after'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $MealEntriesTable createAlias(String alias) {
    return $MealEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MealType, int, int> $convertermeal =
      const EnumIndexConverter<MealType>(MealType.values);
  static JsonTypeConverter2<List<FoodItem>, String, String> $converteritems =
      const FoodItemsConverter();
}

class MealEntry extends DataClass implements Insertable<MealEntry> {
  final String id;
  final String day;
  final MealType meal;
  final int startMinutes;
  final int? endMinutes;
  final List<FoodItem> items;
  final String withWhom;
  final String appetiteFor;
  final String situationBefore;
  final int? hunger;
  final int? satiety;
  final bool binge;
  final String measures;
  final String situationAfter;
  final String? templateId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const MealEntry({
    required this.id,
    required this.day,
    required this.meal,
    required this.startMinutes,
    this.endMinutes,
    required this.items,
    required this.withWhom,
    required this.appetiteFor,
    required this.situationBefore,
    this.hunger,
    this.satiety,
    required this.binge,
    required this.measures,
    required this.situationAfter,
    this.templateId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['day'] = Variable<String>(day);
    {
      map['meal'] = Variable<int>($MealEntriesTable.$convertermeal.toSql(meal));
    }
    map['start_minutes'] = Variable<int>(startMinutes);
    if (!nullToAbsent || endMinutes != null) {
      map['end_minutes'] = Variable<int>(endMinutes);
    }
    {
      map['items'] = Variable<String>(
        $MealEntriesTable.$converteritems.toSql(items),
      );
    }
    map['with_whom'] = Variable<String>(withWhom);
    map['appetite_for'] = Variable<String>(appetiteFor);
    map['situation_before'] = Variable<String>(situationBefore);
    if (!nullToAbsent || hunger != null) {
      map['hunger'] = Variable<int>(hunger);
    }
    if (!nullToAbsent || satiety != null) {
      map['satiety'] = Variable<int>(satiety);
    }
    map['binge'] = Variable<bool>(binge);
    map['measures'] = Variable<String>(measures);
    map['situation_after'] = Variable<String>(situationAfter);
    if (!nullToAbsent || templateId != null) {
      map['template_id'] = Variable<String>(templateId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  MealEntriesCompanion toCompanion(bool nullToAbsent) {
    return MealEntriesCompanion(
      id: Value(id),
      day: Value(day),
      meal: Value(meal),
      startMinutes: Value(startMinutes),
      endMinutes: endMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(endMinutes),
      items: Value(items),
      withWhom: Value(withWhom),
      appetiteFor: Value(appetiteFor),
      situationBefore: Value(situationBefore),
      hunger: hunger == null && nullToAbsent
          ? const Value.absent()
          : Value(hunger),
      satiety: satiety == null && nullToAbsent
          ? const Value.absent()
          : Value(satiety),
      binge: Value(binge),
      measures: Value(measures),
      situationAfter: Value(situationAfter),
      templateId: templateId == null && nullToAbsent
          ? const Value.absent()
          : Value(templateId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory MealEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealEntry(
      id: serializer.fromJson<String>(json['id']),
      day: serializer.fromJson<String>(json['day']),
      meal: $MealEntriesTable.$convertermeal.fromJson(
        serializer.fromJson<int>(json['meal']),
      ),
      startMinutes: serializer.fromJson<int>(json['startMinutes']),
      endMinutes: serializer.fromJson<int?>(json['endMinutes']),
      items: $MealEntriesTable.$converteritems.fromJson(
        serializer.fromJson<String>(json['items']),
      ),
      withWhom: serializer.fromJson<String>(json['withWhom']),
      appetiteFor: serializer.fromJson<String>(json['appetiteFor']),
      situationBefore: serializer.fromJson<String>(json['situationBefore']),
      hunger: serializer.fromJson<int?>(json['hunger']),
      satiety: serializer.fromJson<int?>(json['satiety']),
      binge: serializer.fromJson<bool>(json['binge']),
      measures: serializer.fromJson<String>(json['measures']),
      situationAfter: serializer.fromJson<String>(json['situationAfter']),
      templateId: serializer.fromJson<String?>(json['templateId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'day': serializer.toJson<String>(day),
      'meal': serializer.toJson<int>(
        $MealEntriesTable.$convertermeal.toJson(meal),
      ),
      'startMinutes': serializer.toJson<int>(startMinutes),
      'endMinutes': serializer.toJson<int?>(endMinutes),
      'items': serializer.toJson<String>(
        $MealEntriesTable.$converteritems.toJson(items),
      ),
      'withWhom': serializer.toJson<String>(withWhom),
      'appetiteFor': serializer.toJson<String>(appetiteFor),
      'situationBefore': serializer.toJson<String>(situationBefore),
      'hunger': serializer.toJson<int?>(hunger),
      'satiety': serializer.toJson<int?>(satiety),
      'binge': serializer.toJson<bool>(binge),
      'measures': serializer.toJson<String>(measures),
      'situationAfter': serializer.toJson<String>(situationAfter),
      'templateId': serializer.toJson<String?>(templateId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  MealEntry copyWith({
    String? id,
    String? day,
    MealType? meal,
    int? startMinutes,
    Value<int?> endMinutes = const Value.absent(),
    List<FoodItem>? items,
    String? withWhom,
    String? appetiteFor,
    String? situationBefore,
    Value<int?> hunger = const Value.absent(),
    Value<int?> satiety = const Value.absent(),
    bool? binge,
    String? measures,
    String? situationAfter,
    Value<String?> templateId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => MealEntry(
    id: id ?? this.id,
    day: day ?? this.day,
    meal: meal ?? this.meal,
    startMinutes: startMinutes ?? this.startMinutes,
    endMinutes: endMinutes.present ? endMinutes.value : this.endMinutes,
    items: items ?? this.items,
    withWhom: withWhom ?? this.withWhom,
    appetiteFor: appetiteFor ?? this.appetiteFor,
    situationBefore: situationBefore ?? this.situationBefore,
    hunger: hunger.present ? hunger.value : this.hunger,
    satiety: satiety.present ? satiety.value : this.satiety,
    binge: binge ?? this.binge,
    measures: measures ?? this.measures,
    situationAfter: situationAfter ?? this.situationAfter,
    templateId: templateId.present ? templateId.value : this.templateId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  MealEntry copyWithCompanion(MealEntriesCompanion data) {
    return MealEntry(
      id: data.id.present ? data.id.value : this.id,
      day: data.day.present ? data.day.value : this.day,
      meal: data.meal.present ? data.meal.value : this.meal,
      startMinutes: data.startMinutes.present
          ? data.startMinutes.value
          : this.startMinutes,
      endMinutes: data.endMinutes.present
          ? data.endMinutes.value
          : this.endMinutes,
      items: data.items.present ? data.items.value : this.items,
      withWhom: data.withWhom.present ? data.withWhom.value : this.withWhom,
      appetiteFor: data.appetiteFor.present
          ? data.appetiteFor.value
          : this.appetiteFor,
      situationBefore: data.situationBefore.present
          ? data.situationBefore.value
          : this.situationBefore,
      hunger: data.hunger.present ? data.hunger.value : this.hunger,
      satiety: data.satiety.present ? data.satiety.value : this.satiety,
      binge: data.binge.present ? data.binge.value : this.binge,
      measures: data.measures.present ? data.measures.value : this.measures,
      situationAfter: data.situationAfter.present
          ? data.situationAfter.value
          : this.situationAfter,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealEntry(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('meal: $meal, ')
          ..write('startMinutes: $startMinutes, ')
          ..write('endMinutes: $endMinutes, ')
          ..write('items: $items, ')
          ..write('withWhom: $withWhom, ')
          ..write('appetiteFor: $appetiteFor, ')
          ..write('situationBefore: $situationBefore, ')
          ..write('hunger: $hunger, ')
          ..write('satiety: $satiety, ')
          ..write('binge: $binge, ')
          ..write('measures: $measures, ')
          ..write('situationAfter: $situationAfter, ')
          ..write('templateId: $templateId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    day,
    meal,
    startMinutes,
    endMinutes,
    items,
    withWhom,
    appetiteFor,
    situationBefore,
    hunger,
    satiety,
    binge,
    measures,
    situationAfter,
    templateId,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealEntry &&
          other.id == this.id &&
          other.day == this.day &&
          other.meal == this.meal &&
          other.startMinutes == this.startMinutes &&
          other.endMinutes == this.endMinutes &&
          other.items == this.items &&
          other.withWhom == this.withWhom &&
          other.appetiteFor == this.appetiteFor &&
          other.situationBefore == this.situationBefore &&
          other.hunger == this.hunger &&
          other.satiety == this.satiety &&
          other.binge == this.binge &&
          other.measures == this.measures &&
          other.situationAfter == this.situationAfter &&
          other.templateId == this.templateId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class MealEntriesCompanion extends UpdateCompanion<MealEntry> {
  final Value<String> id;
  final Value<String> day;
  final Value<MealType> meal;
  final Value<int> startMinutes;
  final Value<int?> endMinutes;
  final Value<List<FoodItem>> items;
  final Value<String> withWhom;
  final Value<String> appetiteFor;
  final Value<String> situationBefore;
  final Value<int?> hunger;
  final Value<int?> satiety;
  final Value<bool> binge;
  final Value<String> measures;
  final Value<String> situationAfter;
  final Value<String?> templateId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const MealEntriesCompanion({
    this.id = const Value.absent(),
    this.day = const Value.absent(),
    this.meal = const Value.absent(),
    this.startMinutes = const Value.absent(),
    this.endMinutes = const Value.absent(),
    this.items = const Value.absent(),
    this.withWhom = const Value.absent(),
    this.appetiteFor = const Value.absent(),
    this.situationBefore = const Value.absent(),
    this.hunger = const Value.absent(),
    this.satiety = const Value.absent(),
    this.binge = const Value.absent(),
    this.measures = const Value.absent(),
    this.situationAfter = const Value.absent(),
    this.templateId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MealEntriesCompanion.insert({
    required String id,
    required String day,
    required MealType meal,
    required int startMinutes,
    this.endMinutes = const Value.absent(),
    required List<FoodItem> items,
    this.withWhom = const Value.absent(),
    this.appetiteFor = const Value.absent(),
    this.situationBefore = const Value.absent(),
    this.hunger = const Value.absent(),
    this.satiety = const Value.absent(),
    this.binge = const Value.absent(),
    this.measures = const Value.absent(),
    this.situationAfter = const Value.absent(),
    this.templateId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       day = Value(day),
       meal = Value(meal),
       startMinutes = Value(startMinutes),
       items = Value(items),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<MealEntry> custom({
    Expression<String>? id,
    Expression<String>? day,
    Expression<int>? meal,
    Expression<int>? startMinutes,
    Expression<int>? endMinutes,
    Expression<String>? items,
    Expression<String>? withWhom,
    Expression<String>? appetiteFor,
    Expression<String>? situationBefore,
    Expression<int>? hunger,
    Expression<int>? satiety,
    Expression<bool>? binge,
    Expression<String>? measures,
    Expression<String>? situationAfter,
    Expression<String>? templateId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (day != null) 'day': day,
      if (meal != null) 'meal': meal,
      if (startMinutes != null) 'start_minutes': startMinutes,
      if (endMinutes != null) 'end_minutes': endMinutes,
      if (items != null) 'items': items,
      if (withWhom != null) 'with_whom': withWhom,
      if (appetiteFor != null) 'appetite_for': appetiteFor,
      if (situationBefore != null) 'situation_before': situationBefore,
      if (hunger != null) 'hunger': hunger,
      if (satiety != null) 'satiety': satiety,
      if (binge != null) 'binge': binge,
      if (measures != null) 'measures': measures,
      if (situationAfter != null) 'situation_after': situationAfter,
      if (templateId != null) 'template_id': templateId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MealEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? day,
    Value<MealType>? meal,
    Value<int>? startMinutes,
    Value<int?>? endMinutes,
    Value<List<FoodItem>>? items,
    Value<String>? withWhom,
    Value<String>? appetiteFor,
    Value<String>? situationBefore,
    Value<int?>? hunger,
    Value<int?>? satiety,
    Value<bool>? binge,
    Value<String>? measures,
    Value<String>? situationAfter,
    Value<String?>? templateId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return MealEntriesCompanion(
      id: id ?? this.id,
      day: day ?? this.day,
      meal: meal ?? this.meal,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
      items: items ?? this.items,
      withWhom: withWhom ?? this.withWhom,
      appetiteFor: appetiteFor ?? this.appetiteFor,
      situationBefore: situationBefore ?? this.situationBefore,
      hunger: hunger ?? this.hunger,
      satiety: satiety ?? this.satiety,
      binge: binge ?? this.binge,
      measures: measures ?? this.measures,
      situationAfter: situationAfter ?? this.situationAfter,
      templateId: templateId ?? this.templateId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (meal.present) {
      map['meal'] = Variable<int>(
        $MealEntriesTable.$convertermeal.toSql(meal.value),
      );
    }
    if (startMinutes.present) {
      map['start_minutes'] = Variable<int>(startMinutes.value);
    }
    if (endMinutes.present) {
      map['end_minutes'] = Variable<int>(endMinutes.value);
    }
    if (items.present) {
      map['items'] = Variable<String>(
        $MealEntriesTable.$converteritems.toSql(items.value),
      );
    }
    if (withWhom.present) {
      map['with_whom'] = Variable<String>(withWhom.value);
    }
    if (appetiteFor.present) {
      map['appetite_for'] = Variable<String>(appetiteFor.value);
    }
    if (situationBefore.present) {
      map['situation_before'] = Variable<String>(situationBefore.value);
    }
    if (hunger.present) {
      map['hunger'] = Variable<int>(hunger.value);
    }
    if (satiety.present) {
      map['satiety'] = Variable<int>(satiety.value);
    }
    if (binge.present) {
      map['binge'] = Variable<bool>(binge.value);
    }
    if (measures.present) {
      map['measures'] = Variable<String>(measures.value);
    }
    if (situationAfter.present) {
      map['situation_after'] = Variable<String>(situationAfter.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealEntriesCompanion(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('meal: $meal, ')
          ..write('startMinutes: $startMinutes, ')
          ..write('endMinutes: $endMinutes, ')
          ..write('items: $items, ')
          ..write('withWhom: $withWhom, ')
          ..write('appetiteFor: $appetiteFor, ')
          ..write('situationBefore: $situationBefore, ')
          ..write('hunger: $hunger, ')
          ..write('satiety: $satiety, ')
          ..write('binge: $binge, ')
          ..write('measures: $measures, ')
          ..write('situationAfter: $situationAfter, ')
          ..write('templateId: $templateId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DayNotesTable extends DayNotes with TableInfo<$DayNotesTable, DayNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DayNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dietMeta = const VerificationMeta('diet');
  @override
  late final GeneratedColumn<bool> diet = GeneratedColumn<bool>(
    'diet',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("diet" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sickMeta = const VerificationMeta('sick');
  @override
  late final GeneratedColumn<bool> sick = GeneratedColumn<bool>(
    'sick',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sick" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [day, diet, sick, note, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'day_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<DayNote> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('diet')) {
      context.handle(
        _dietMeta,
        diet.isAcceptableOrUnknown(data['diet']!, _dietMeta),
      );
    }
    if (data.containsKey('sick')) {
      context.handle(
        _sickMeta,
        sick.isAcceptableOrUnknown(data['sick']!, _sickMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {day};
  @override
  DayNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DayNote(
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      diet: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}diet'],
      )!,
      sick: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sick'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DayNotesTable createAlias(String alias) {
    return $DayNotesTable(attachedDatabase, alias);
  }
}

class DayNote extends DataClass implements Insertable<DayNote> {
  final String day;
  final bool diet;
  final bool sick;
  final String note;
  final DateTime updatedAt;
  const DayNote({
    required this.day,
    required this.diet,
    required this.sick,
    required this.note,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day'] = Variable<String>(day);
    map['diet'] = Variable<bool>(diet);
    map['sick'] = Variable<bool>(sick);
    map['note'] = Variable<String>(note);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DayNotesCompanion toCompanion(bool nullToAbsent) {
    return DayNotesCompanion(
      day: Value(day),
      diet: Value(diet),
      sick: Value(sick),
      note: Value(note),
      updatedAt: Value(updatedAt),
    );
  }

  factory DayNote.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DayNote(
      day: serializer.fromJson<String>(json['day']),
      diet: serializer.fromJson<bool>(json['diet']),
      sick: serializer.fromJson<bool>(json['sick']),
      note: serializer.fromJson<String>(json['note']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'day': serializer.toJson<String>(day),
      'diet': serializer.toJson<bool>(diet),
      'sick': serializer.toJson<bool>(sick),
      'note': serializer.toJson<String>(note),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DayNote copyWith({
    String? day,
    bool? diet,
    bool? sick,
    String? note,
    DateTime? updatedAt,
  }) => DayNote(
    day: day ?? this.day,
    diet: diet ?? this.diet,
    sick: sick ?? this.sick,
    note: note ?? this.note,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DayNote copyWithCompanion(DayNotesCompanion data) {
    return DayNote(
      day: data.day.present ? data.day.value : this.day,
      diet: data.diet.present ? data.diet.value : this.diet,
      sick: data.sick.present ? data.sick.value : this.sick,
      note: data.note.present ? data.note.value : this.note,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DayNote(')
          ..write('day: $day, ')
          ..write('diet: $diet, ')
          ..write('sick: $sick, ')
          ..write('note: $note, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(day, diet, sick, note, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DayNote &&
          other.day == this.day &&
          other.diet == this.diet &&
          other.sick == this.sick &&
          other.note == this.note &&
          other.updatedAt == this.updatedAt);
}

class DayNotesCompanion extends UpdateCompanion<DayNote> {
  final Value<String> day;
  final Value<bool> diet;
  final Value<bool> sick;
  final Value<String> note;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DayNotesCompanion({
    this.day = const Value.absent(),
    this.diet = const Value.absent(),
    this.sick = const Value.absent(),
    this.note = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DayNotesCompanion.insert({
    required String day,
    this.diet = const Value.absent(),
    this.sick = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : day = Value(day),
       updatedAt = Value(updatedAt);
  static Insertable<DayNote> custom({
    Expression<String>? day,
    Expression<bool>? diet,
    Expression<bool>? sick,
    Expression<String>? note,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (day != null) 'day': day,
      if (diet != null) 'diet': diet,
      if (sick != null) 'sick': sick,
      if (note != null) 'note': note,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DayNotesCompanion copyWith({
    Value<String>? day,
    Value<bool>? diet,
    Value<bool>? sick,
    Value<String>? note,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DayNotesCompanion(
      day: day ?? this.day,
      diet: diet ?? this.diet,
      sick: sick ?? this.sick,
      note: note ?? this.note,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (diet.present) {
      map['diet'] = Variable<bool>(diet.value);
    }
    if (sick.present) {
      map['sick'] = Variable<bool>(sick.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DayNotesCompanion(')
          ..write('day: $day, ')
          ..write('diet: $diet, ')
          ..write('sick: $sick, ')
          ..write('note: $note, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MealTemplatesTable extends MealTemplates
    with TableInfo<$MealTemplatesTable, MealTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MealType?, int> meal =
      GeneratedColumn<int>(
        'meal',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<MealType?>($MealTemplatesTable.$convertermealn);
  @override
  late final GeneratedColumnWithTypeConverter<List<FoodItem>, String> items =
      GeneratedColumn<String>(
        'items',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<FoodItem>>($MealTemplatesTable.$converteritems);
  static const VerificationMeta _withWhomMeta = const VerificationMeta(
    'withWhom',
  );
  @override
  late final GeneratedColumn<String> withWhom = GeneratedColumn<String>(
    'with_whom',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _pinnedMeta = const VerificationMeta('pinned');
  @override
  late final GeneratedColumn<bool> pinned = GeneratedColumn<bool>(
    'pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _useCountMeta = const VerificationMeta(
    'useCount',
  );
  @override
  late final GeneratedColumn<int> useCount = GeneratedColumn<int>(
    'use_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastUsedAtMeta = const VerificationMeta(
    'lastUsedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastUsedAt = GeneratedColumn<DateTime>(
    'last_used_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    meal,
    items,
    withWhom,
    pinned,
    useCount,
    lastUsedAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<MealTemplate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('with_whom')) {
      context.handle(
        _withWhomMeta,
        withWhom.isAcceptableOrUnknown(data['with_whom']!, _withWhomMeta),
      );
    }
    if (data.containsKey('pinned')) {
      context.handle(
        _pinnedMeta,
        pinned.isAcceptableOrUnknown(data['pinned']!, _pinnedMeta),
      );
    }
    if (data.containsKey('use_count')) {
      context.handle(
        _useCountMeta,
        useCount.isAcceptableOrUnknown(data['use_count']!, _useCountMeta),
      );
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
        _lastUsedAtMeta,
        lastUsedAt.isAcceptableOrUnknown(
          data['last_used_at']!,
          _lastUsedAtMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MealTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealTemplate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      meal: $MealTemplatesTable.$convertermealn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}meal'],
        ),
      ),
      items: $MealTemplatesTable.$converteritems.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}items'],
        )!,
      ),
      withWhom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}with_whom'],
      )!,
      pinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pinned'],
      )!,
      useCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}use_count'],
      )!,
      lastUsedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_used_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $MealTemplatesTable createAlias(String alias) {
    return $MealTemplatesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MealType, int, int> $convertermeal =
      const EnumIndexConverter<MealType>(MealType.values);
  static JsonTypeConverter2<MealType?, int?, int?> $convertermealn =
      JsonTypeConverter2.asNullable($convertermeal);
  static JsonTypeConverter2<List<FoodItem>, String, String> $converteritems =
      const FoodItemsConverter();
}

class MealTemplate extends DataClass implements Insertable<MealTemplate> {
  final String id;
  final String name;
  final MealType? meal;
  final List<FoodItem> items;
  final String withWhom;
  final bool pinned;
  final int useCount;
  final DateTime? lastUsedAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const MealTemplate({
    required this.id,
    required this.name,
    this.meal,
    required this.items,
    required this.withWhom,
    required this.pinned,
    required this.useCount,
    this.lastUsedAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || meal != null) {
      map['meal'] = Variable<int>(
        $MealTemplatesTable.$convertermealn.toSql(meal),
      );
    }
    {
      map['items'] = Variable<String>(
        $MealTemplatesTable.$converteritems.toSql(items),
      );
    }
    map['with_whom'] = Variable<String>(withWhom);
    map['pinned'] = Variable<bool>(pinned);
    map['use_count'] = Variable<int>(useCount);
    if (!nullToAbsent || lastUsedAt != null) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  MealTemplatesCompanion toCompanion(bool nullToAbsent) {
    return MealTemplatesCompanion(
      id: Value(id),
      name: Value(name),
      meal: meal == null && nullToAbsent ? const Value.absent() : Value(meal),
      items: Value(items),
      withWhom: Value(withWhom),
      pinned: Value(pinned),
      useCount: Value(useCount),
      lastUsedAt: lastUsedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUsedAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory MealTemplate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealTemplate(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      meal: $MealTemplatesTable.$convertermealn.fromJson(
        serializer.fromJson<int?>(json['meal']),
      ),
      items: $MealTemplatesTable.$converteritems.fromJson(
        serializer.fromJson<String>(json['items']),
      ),
      withWhom: serializer.fromJson<String>(json['withWhom']),
      pinned: serializer.fromJson<bool>(json['pinned']),
      useCount: serializer.fromJson<int>(json['useCount']),
      lastUsedAt: serializer.fromJson<DateTime?>(json['lastUsedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'meal': serializer.toJson<int?>(
        $MealTemplatesTable.$convertermealn.toJson(meal),
      ),
      'items': serializer.toJson<String>(
        $MealTemplatesTable.$converteritems.toJson(items),
      ),
      'withWhom': serializer.toJson<String>(withWhom),
      'pinned': serializer.toJson<bool>(pinned),
      'useCount': serializer.toJson<int>(useCount),
      'lastUsedAt': serializer.toJson<DateTime?>(lastUsedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  MealTemplate copyWith({
    String? id,
    String? name,
    Value<MealType?> meal = const Value.absent(),
    List<FoodItem>? items,
    String? withWhom,
    bool? pinned,
    int? useCount,
    Value<DateTime?> lastUsedAt = const Value.absent(),
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => MealTemplate(
    id: id ?? this.id,
    name: name ?? this.name,
    meal: meal.present ? meal.value : this.meal,
    items: items ?? this.items,
    withWhom: withWhom ?? this.withWhom,
    pinned: pinned ?? this.pinned,
    useCount: useCount ?? this.useCount,
    lastUsedAt: lastUsedAt.present ? lastUsedAt.value : this.lastUsedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  MealTemplate copyWithCompanion(MealTemplatesCompanion data) {
    return MealTemplate(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      meal: data.meal.present ? data.meal.value : this.meal,
      items: data.items.present ? data.items.value : this.items,
      withWhom: data.withWhom.present ? data.withWhom.value : this.withWhom,
      pinned: data.pinned.present ? data.pinned.value : this.pinned,
      useCount: data.useCount.present ? data.useCount.value : this.useCount,
      lastUsedAt: data.lastUsedAt.present
          ? data.lastUsedAt.value
          : this.lastUsedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealTemplate(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('meal: $meal, ')
          ..write('items: $items, ')
          ..write('withWhom: $withWhom, ')
          ..write('pinned: $pinned, ')
          ..write('useCount: $useCount, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    meal,
    items,
    withWhom,
    pinned,
    useCount,
    lastUsedAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealTemplate &&
          other.id == this.id &&
          other.name == this.name &&
          other.meal == this.meal &&
          other.items == this.items &&
          other.withWhom == this.withWhom &&
          other.pinned == this.pinned &&
          other.useCount == this.useCount &&
          other.lastUsedAt == this.lastUsedAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class MealTemplatesCompanion extends UpdateCompanion<MealTemplate> {
  final Value<String> id;
  final Value<String> name;
  final Value<MealType?> meal;
  final Value<List<FoodItem>> items;
  final Value<String> withWhom;
  final Value<bool> pinned;
  final Value<int> useCount;
  final Value<DateTime?> lastUsedAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const MealTemplatesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.meal = const Value.absent(),
    this.items = const Value.absent(),
    this.withWhom = const Value.absent(),
    this.pinned = const Value.absent(),
    this.useCount = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MealTemplatesCompanion.insert({
    required String id,
    required String name,
    this.meal = const Value.absent(),
    required List<FoodItem> items,
    this.withWhom = const Value.absent(),
    this.pinned = const Value.absent(),
    this.useCount = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       items = Value(items),
       updatedAt = Value(updatedAt);
  static Insertable<MealTemplate> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? meal,
    Expression<String>? items,
    Expression<String>? withWhom,
    Expression<bool>? pinned,
    Expression<int>? useCount,
    Expression<DateTime>? lastUsedAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (meal != null) 'meal': meal,
      if (items != null) 'items': items,
      if (withWhom != null) 'with_whom': withWhom,
      if (pinned != null) 'pinned': pinned,
      if (useCount != null) 'use_count': useCount,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MealTemplatesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<MealType?>? meal,
    Value<List<FoodItem>>? items,
    Value<String>? withWhom,
    Value<bool>? pinned,
    Value<int>? useCount,
    Value<DateTime?>? lastUsedAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return MealTemplatesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      meal: meal ?? this.meal,
      items: items ?? this.items,
      withWhom: withWhom ?? this.withWhom,
      pinned: pinned ?? this.pinned,
      useCount: useCount ?? this.useCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (meal.present) {
      map['meal'] = Variable<int>(
        $MealTemplatesTable.$convertermealn.toSql(meal.value),
      );
    }
    if (items.present) {
      map['items'] = Variable<String>(
        $MealTemplatesTable.$converteritems.toSql(items.value),
      );
    }
    if (withWhom.present) {
      map['with_whom'] = Variable<String>(withWhom.value);
    }
    if (pinned.present) {
      map['pinned'] = Variable<bool>(pinned.value);
    }
    if (useCount.present) {
      map['use_count'] = Variable<int>(useCount.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('meal: $meal, ')
          ..write('items: $items, ')
          ..write('withWhom: $withWhom, ')
          ..write('pinned: $pinned, ')
          ..write('useCount: $useCount, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MealEntriesTable mealEntries = $MealEntriesTable(this);
  late final $DayNotesTable dayNotes = $DayNotesTable(this);
  late final $MealTemplatesTable mealTemplates = $MealTemplatesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    mealEntries,
    dayNotes,
    mealTemplates,
  ];
}

typedef $$MealEntriesTableCreateCompanionBuilder =
    MealEntriesCompanion Function({
      required String id,
      required String day,
      required MealType meal,
      required int startMinutes,
      Value<int?> endMinutes,
      required List<FoodItem> items,
      Value<String> withWhom,
      Value<String> appetiteFor,
      Value<String> situationBefore,
      Value<int?> hunger,
      Value<int?> satiety,
      Value<bool> binge,
      Value<String> measures,
      Value<String> situationAfter,
      Value<String?> templateId,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$MealEntriesTableUpdateCompanionBuilder =
    MealEntriesCompanion Function({
      Value<String> id,
      Value<String> day,
      Value<MealType> meal,
      Value<int> startMinutes,
      Value<int?> endMinutes,
      Value<List<FoodItem>> items,
      Value<String> withWhom,
      Value<String> appetiteFor,
      Value<String> situationBefore,
      Value<int?> hunger,
      Value<int?> satiety,
      Value<bool> binge,
      Value<String> measures,
      Value<String> situationAfter,
      Value<String?> templateId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$MealEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $MealEntriesTable> {
  $$MealEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MealType, MealType, int> get meal =>
      $composableBuilder(
        column: $table.meal,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get startMinutes => $composableBuilder(
    column: $table.startMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endMinutes => $composableBuilder(
    column: $table.endMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<FoodItem>, List<FoodItem>, String>
  get items => $composableBuilder(
    column: $table.items,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get withWhom => $composableBuilder(
    column: $table.withWhom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appetiteFor => $composableBuilder(
    column: $table.appetiteFor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get situationBefore => $composableBuilder(
    column: $table.situationBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hunger => $composableBuilder(
    column: $table.hunger,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get satiety => $composableBuilder(
    column: $table.satiety,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get binge => $composableBuilder(
    column: $table.binge,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get measures => $composableBuilder(
    column: $table.measures,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get situationAfter => $composableBuilder(
    column: $table.situationAfter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MealEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $MealEntriesTable> {
  $$MealEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get meal => $composableBuilder(
    column: $table.meal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMinutes => $composableBuilder(
    column: $table.startMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endMinutes => $composableBuilder(
    column: $table.endMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get items => $composableBuilder(
    column: $table.items,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get withWhom => $composableBuilder(
    column: $table.withWhom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appetiteFor => $composableBuilder(
    column: $table.appetiteFor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get situationBefore => $composableBuilder(
    column: $table.situationBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hunger => $composableBuilder(
    column: $table.hunger,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get satiety => $composableBuilder(
    column: $table.satiety,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get binge => $composableBuilder(
    column: $table.binge,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get measures => $composableBuilder(
    column: $table.measures,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get situationAfter => $composableBuilder(
    column: $table.situationAfter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MealEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealEntriesTable> {
  $$MealEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MealType, int> get meal =>
      $composableBuilder(column: $table.meal, builder: (column) => column);

  GeneratedColumn<int> get startMinutes => $composableBuilder(
    column: $table.startMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endMinutes => $composableBuilder(
    column: $table.endMinutes,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<FoodItem>, String> get items =>
      $composableBuilder(column: $table.items, builder: (column) => column);

  GeneratedColumn<String> get withWhom =>
      $composableBuilder(column: $table.withWhom, builder: (column) => column);

  GeneratedColumn<String> get appetiteFor => $composableBuilder(
    column: $table.appetiteFor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get situationBefore => $composableBuilder(
    column: $table.situationBefore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get hunger =>
      $composableBuilder(column: $table.hunger, builder: (column) => column);

  GeneratedColumn<int> get satiety =>
      $composableBuilder(column: $table.satiety, builder: (column) => column);

  GeneratedColumn<bool> get binge =>
      $composableBuilder(column: $table.binge, builder: (column) => column);

  GeneratedColumn<String> get measures =>
      $composableBuilder(column: $table.measures, builder: (column) => column);

  GeneratedColumn<String> get situationAfter => $composableBuilder(
    column: $table.situationAfter,
    builder: (column) => column,
  );

  GeneratedColumn<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$MealEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MealEntriesTable,
          MealEntry,
          $$MealEntriesTableFilterComposer,
          $$MealEntriesTableOrderingComposer,
          $$MealEntriesTableAnnotationComposer,
          $$MealEntriesTableCreateCompanionBuilder,
          $$MealEntriesTableUpdateCompanionBuilder,
          (
            MealEntry,
            BaseReferences<_$AppDatabase, $MealEntriesTable, MealEntry>,
          ),
          MealEntry,
          PrefetchHooks Function()
        > {
  $$MealEntriesTableTableManager(_$AppDatabase db, $MealEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<MealType> meal = const Value.absent(),
                Value<int> startMinutes = const Value.absent(),
                Value<int?> endMinutes = const Value.absent(),
                Value<List<FoodItem>> items = const Value.absent(),
                Value<String> withWhom = const Value.absent(),
                Value<String> appetiteFor = const Value.absent(),
                Value<String> situationBefore = const Value.absent(),
                Value<int?> hunger = const Value.absent(),
                Value<int?> satiety = const Value.absent(),
                Value<bool> binge = const Value.absent(),
                Value<String> measures = const Value.absent(),
                Value<String> situationAfter = const Value.absent(),
                Value<String?> templateId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MealEntriesCompanion(
                id: id,
                day: day,
                meal: meal,
                startMinutes: startMinutes,
                endMinutes: endMinutes,
                items: items,
                withWhom: withWhom,
                appetiteFor: appetiteFor,
                situationBefore: situationBefore,
                hunger: hunger,
                satiety: satiety,
                binge: binge,
                measures: measures,
                situationAfter: situationAfter,
                templateId: templateId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String day,
                required MealType meal,
                required int startMinutes,
                Value<int?> endMinutes = const Value.absent(),
                required List<FoodItem> items,
                Value<String> withWhom = const Value.absent(),
                Value<String> appetiteFor = const Value.absent(),
                Value<String> situationBefore = const Value.absent(),
                Value<int?> hunger = const Value.absent(),
                Value<int?> satiety = const Value.absent(),
                Value<bool> binge = const Value.absent(),
                Value<String> measures = const Value.absent(),
                Value<String> situationAfter = const Value.absent(),
                Value<String?> templateId = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MealEntriesCompanion.insert(
                id: id,
                day: day,
                meal: meal,
                startMinutes: startMinutes,
                endMinutes: endMinutes,
                items: items,
                withWhom: withWhom,
                appetiteFor: appetiteFor,
                situationBefore: situationBefore,
                hunger: hunger,
                satiety: satiety,
                binge: binge,
                measures: measures,
                situationAfter: situationAfter,
                templateId: templateId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MealEntriesTable, MealEntry>(table),
                  BaseReferences<_$AppDatabase, $MealEntriesTable, MealEntry>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MealEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MealEntriesTable,
      MealEntry,
      $$MealEntriesTableFilterComposer,
      $$MealEntriesTableOrderingComposer,
      $$MealEntriesTableAnnotationComposer,
      $$MealEntriesTableCreateCompanionBuilder,
      $$MealEntriesTableUpdateCompanionBuilder,
      (MealEntry, BaseReferences<_$AppDatabase, $MealEntriesTable, MealEntry>),
      MealEntry,
      PrefetchHooks Function()
    >;
typedef $$DayNotesTableCreateCompanionBuilder = DayNotesCompanion Function({
  required String day,
  Value<bool> diet,
  Value<bool> sick,
  Value<String> note,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$DayNotesTableUpdateCompanionBuilder = DayNotesCompanion Function({
  Value<String> day,
  Value<bool> diet,
  Value<bool> sick,
  Value<String> note,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$DayNotesTableFilterComposer
    extends Composer<_$AppDatabase, $DayNotesTable> {
  $$DayNotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get diet => $composableBuilder(
    column: $table.diet,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get sick => $composableBuilder(
    column: $table.sick,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DayNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $DayNotesTable> {
  $$DayNotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get diet => $composableBuilder(
    column: $table.diet,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sick => $composableBuilder(
    column: $table.sick,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DayNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DayNotesTable> {
  $$DayNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<bool> get diet =>
      $composableBuilder(column: $table.diet, builder: (column) => column);

  GeneratedColumn<bool> get sick =>
      $composableBuilder(column: $table.sick, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DayNotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DayNotesTable,
          DayNote,
          $$DayNotesTableFilterComposer,
          $$DayNotesTableOrderingComposer,
          $$DayNotesTableAnnotationComposer,
          $$DayNotesTableCreateCompanionBuilder,
          $$DayNotesTableUpdateCompanionBuilder,
          (DayNote, BaseReferences<_$AppDatabase, $DayNotesTable, DayNote>),
          DayNote,
          PrefetchHooks Function()
        > {
  $$DayNotesTableTableManager(_$AppDatabase db, $DayNotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DayNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DayNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DayNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> day = const Value.absent(),
                Value<bool> diet = const Value.absent(),
                Value<bool> sick = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DayNotesCompanion(
                day: day,
                diet: diet,
                sick: sick,
                note: note,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String day,
                Value<bool> diet = const Value.absent(),
                Value<bool> sick = const Value.absent(),
                Value<String> note = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DayNotesCompanion.insert(
                day: day,
                diet: diet,
                sick: sick,
                note: note,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DayNotesTable, DayNote>(table),
                  BaseReferences<_$AppDatabase, $DayNotesTable, DayNote>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DayNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DayNotesTable,
      DayNote,
      $$DayNotesTableFilterComposer,
      $$DayNotesTableOrderingComposer,
      $$DayNotesTableAnnotationComposer,
      $$DayNotesTableCreateCompanionBuilder,
      $$DayNotesTableUpdateCompanionBuilder,
      (DayNote, BaseReferences<_$AppDatabase, $DayNotesTable, DayNote>),
      DayNote,
      PrefetchHooks Function()
    >;
typedef $$MealTemplatesTableCreateCompanionBuilder =
    MealTemplatesCompanion Function({
      required String id,
      required String name,
      Value<MealType?> meal,
      required List<FoodItem> items,
      Value<String> withWhom,
      Value<bool> pinned,
      Value<int> useCount,
      Value<DateTime?> lastUsedAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$MealTemplatesTableUpdateCompanionBuilder =
    MealTemplatesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<MealType?> meal,
      Value<List<FoodItem>> items,
      Value<String> withWhom,
      Value<bool> pinned,
      Value<int> useCount,
      Value<DateTime?> lastUsedAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$MealTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $MealTemplatesTable> {
  $$MealTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MealType?, MealType, int> get meal =>
      $composableBuilder(
        column: $table.meal,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<List<FoodItem>, List<FoodItem>, String>
  get items => $composableBuilder(
    column: $table.items,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get withWhom => $composableBuilder(
    column: $table.withWhom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get useCount => $composableBuilder(
    column: $table.useCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MealTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $MealTemplatesTable> {
  $$MealTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get meal => $composableBuilder(
    column: $table.meal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get items => $composableBuilder(
    column: $table.items,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get withWhom => $composableBuilder(
    column: $table.withWhom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get useCount => $composableBuilder(
    column: $table.useCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MealTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealTemplatesTable> {
  $$MealTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MealType?, int> get meal =>
      $composableBuilder(column: $table.meal, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<FoodItem>, String> get items =>
      $composableBuilder(column: $table.items, builder: (column) => column);

  GeneratedColumn<String> get withWhom =>
      $composableBuilder(column: $table.withWhom, builder: (column) => column);

  GeneratedColumn<bool> get pinned =>
      $composableBuilder(column: $table.pinned, builder: (column) => column);

  GeneratedColumn<int> get useCount =>
      $composableBuilder(column: $table.useCount, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$MealTemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MealTemplatesTable,
          MealTemplate,
          $$MealTemplatesTableFilterComposer,
          $$MealTemplatesTableOrderingComposer,
          $$MealTemplatesTableAnnotationComposer,
          $$MealTemplatesTableCreateCompanionBuilder,
          $$MealTemplatesTableUpdateCompanionBuilder,
          (
            MealTemplate,
            BaseReferences<_$AppDatabase, $MealTemplatesTable, MealTemplate>,
          ),
          MealTemplate,
          PrefetchHooks Function()
        > {
  $$MealTemplatesTableTableManager(_$AppDatabase db, $MealTemplatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealTemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<MealType?> meal = const Value.absent(),
                Value<List<FoodItem>> items = const Value.absent(),
                Value<String> withWhom = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
                Value<int> useCount = const Value.absent(),
                Value<DateTime?> lastUsedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MealTemplatesCompanion(
                id: id,
                name: name,
                meal: meal,
                items: items,
                withWhom: withWhom,
                pinned: pinned,
                useCount: useCount,
                lastUsedAt: lastUsedAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<MealType?> meal = const Value.absent(),
                required List<FoodItem> items,
                Value<String> withWhom = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
                Value<int> useCount = const Value.absent(),
                Value<DateTime?> lastUsedAt = const Value.absent(),
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MealTemplatesCompanion.insert(
                id: id,
                name: name,
                meal: meal,
                items: items,
                withWhom: withWhom,
                pinned: pinned,
                useCount: useCount,
                lastUsedAt: lastUsedAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MealTemplatesTable, MealTemplate>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $MealTemplatesTable,
                    MealTemplate
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MealTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MealTemplatesTable,
      MealTemplate,
      $$MealTemplatesTableFilterComposer,
      $$MealTemplatesTableOrderingComposer,
      $$MealTemplatesTableAnnotationComposer,
      $$MealTemplatesTableCreateCompanionBuilder,
      $$MealTemplatesTableUpdateCompanionBuilder,
      (
        MealTemplate,
        BaseReferences<_$AppDatabase, $MealTemplatesTable, MealTemplate>,
      ),
      MealTemplate,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MealEntriesTableTableManager get mealEntries =>
      $$MealEntriesTableTableManager(_db, _db.mealEntries);
  $$DayNotesTableTableManager get dayNotes =>
      $$DayNotesTableTableManager(_db, _db.dayNotes);
  $$MealTemplatesTableTableManager get mealTemplates =>
      $$MealTemplatesTableTableManager(_db, _db.mealTemplates);
}
