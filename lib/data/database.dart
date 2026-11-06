import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

import 'backup_crypto.dart';
import 'models.dart';

part 'database.g.dart';

const _uuid = Uuid();
String newId() => _uuid.v4();

@DataClassName('MealEntry')
class MealEntries extends Table {
  TextColumn get id => text()();
  TextColumn get day => text()();
  IntColumn get meal => intEnum<MealType>()();
  IntColumn get startMinutes => integer()();
  IntColumn get endMinutes => integer().nullable()();
  TextColumn get items => text().map(const FoodItemsConverter())();
  TextColumn get withWhom => text().withDefault(const Constant(''))();
  TextColumn get appetiteFor => text().withDefault(const Constant(''))();
  TextColumn get situationBefore => text().withDefault(const Constant(''))();
  IntColumn get hunger => integer().nullable()();
  IntColumn get satiety => integer().nullable()();
  BoolColumn get binge => boolean().withDefault(const Constant(false))();
  TextColumn get measures => text().withDefault(const Constant(''))();
  TextColumn get sports => text().map(const SportsConverter()).withDefault(const Constant('[]'))();
  TextColumn get situationAfter => text().withDefault(const Constant(''))();
  // Started with "start eating" and not finished yet; kept out of exports.
  BoolColumn get running => boolean().withDefault(const Constant(false))();
  TextColumn get templateId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class DayNotes extends Table {
  TextColumn get day => text()();
  BoolColumn get diet => boolean().withDefault(const Constant(false))();
  BoolColumn get sick => boolean().withDefault(const Constant(false))();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {day};
}

@DataClassName('MealTemplate')
class MealTemplates extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get meal => intEnum<MealType>().nullable()();
  TextColumn get items => text().map(const FoodItemsConverter())();
  TextColumn get withWhom => text().withDefault(const Constant(''))();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
  IntColumn get useCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastUsedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// What the pickers offer; entries copy the value, so changes here never touch them.
@DataClassName('ListValue')
class ListValues extends Table {
  TextColumn get id => text()();
  IntColumn get kind => intEnum<ListKind>()();
  TextColumn get name => text()();
  TextColumn get plural => text().withDefault(const Constant(''))();
  IntColumn get position => integer()();
  DateTimeColumn get updatedAt => dateTime()();
  // Never purged: restoring an older backup would otherwise bring a deleted value back.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Per list, (name, plural) pairs.
typedef ListDefaults = Map<ListKind, List<(String, String)>>;

class FoodSuggestion {
  const FoodSuggestion(this.last, this.count);

  final FoodItem last;
  final int count;

  String get food => last.food;
}

@DriftDatabase(tables: [MealEntries, DayNotes, MealTemplates, ListValues])
class AppDatabase extends _$AppDatabase {
  /// [listDefaults] fill the lists once, when they are created.
  AppDatabase(String key, {this.listDefaults = const {}})
      : super(driftDatabase(
          name: 'whatseat',
          native: DriftNativeOptions(
            // sqlite3mc (see pubspec hooks); the key is hex, so quoting is safe.
            setup: (db) => db.execute("PRAGMA key = '$key'"),
          ),
        ));

  AppDatabase.forTesting(super.executor, {this.listDefaults = const {}});

  final ListDefaults listDefaults;

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.addColumn(mealEntries, mealEntries.running);
          if (from < 3) {
            await m.createTable(listValues);
            await m.addColumn(mealEntries, mealEntries.sports);
          }
        },
        beforeOpen: (details) async {
          if ((details.versionBefore ?? 0) < 3) await _fillLists(listDefaults);
        },
      );

  /// Adds [defaults] and every value the entries use, unless the list has or had a value of that name.
  Future<void> _fillLists(ListDefaults defaults) => transaction(() async {
        final candidates = {for (final kind in ListKind.values) kind: [...?defaults[kind]]};
        for (final e in await _history()) {
          for (final i in e.items.where((i) => i.unit.isNotEmpty)) {
            candidates[i.drink ? ListKind.drinkUnit : ListKind.foodUnit]!.add((i.unit, i.unitPlural));
          }
          candidates[ListKind.measure]!.addAll(splitTags(e.measures).map((t) => (t, '')));
          candidates[ListKind.withWhom]!.addAll(splitTags(e.withWhom).map((t) => (t, '')));
          candidates[ListKind.sport]!.addAll(e.sports.map((s) => (s.sport, '')));
        }
        final existing = await select(listValues).get();
        final taken = {for (final v in existing) (v.kind, v.name.toLowerCase())};
        var position = existing.fold(0, (p, v) => max(p, v.position + 1));
        for (final MapEntry(key: kind, value: values) in candidates.entries) {
          for (final (name, plural) in values) {
            if (!taken.add((kind, name.toLowerCase()))) continue;
            await into(listValues).insert(
              ListValuesCompanion.insert(
                // The same on every device, so lists filled separately merge on restore instead of doubling.
                id: '${kind.name}:${name.toLowerCase()}',
                kind: kind,
                name: name,
                plural: Value(plural),
                position: position++,
                // Older than any edit, so an edited copy from a backup wins.
                updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
              ),
              mode: InsertMode.insertOrIgnore,
            );
          }
        }
      });

  Stream<List<MealEntry>> watchDay(String day) => (select(mealEntries)
        ..where((e) => e.day.equals(day) & e.deletedAt.isNull())
        ..orderBy([(e) => OrderingTerm.asc(e.startMinutes)]))
      .watch();

  Stream<MealEntry?> watchRunning() => (select(mealEntries)
        ..where((e) => e.running & e.deletedAt.isNull())
        ..orderBy([(e) => OrderingTerm.desc(e.createdAt)])
        ..limit(1))
      .watchSingleOrNull();

  Stream<Set<String>> watchDaysWithEntries(String from, String to) {
    final q = selectOnly(mealEntries, distinct: true)
      ..addColumns([mealEntries.day])
      ..where(mealEntries.day.isBetweenValues(from, to) & mealEntries.deletedAt.isNull());
    return q.watch().map((rows) => {for (final r in rows) r.read(mealEntries.day)!});
  }

  Future<List<MealEntry>> entriesBetween(String from, String to) => (select(mealEntries)
        ..where((e) => e.day.isBetweenValues(from, to) & e.deletedAt.isNull() & e.running.not())
        ..orderBy([(e) => OrderingTerm.asc(e.day), (e) => OrderingTerm.asc(e.startMinutes)]))
      .get();

  Future<List<DayNote>> notesBetween(String from, String to) =>
      (select(dayNotes)..where((n) => n.day.isBetweenValues(from, to))).get();

  Stream<DayNote?> watchDayNote(String day) =>
      (select(dayNotes)..where((n) => n.day.equals(day))).watchSingleOrNull();

  Future<void> saveDayNote(String day, {required bool diet, required bool sick, required String note}) =>
      into(dayNotes).insertOnConflictUpdate(DayNotesCompanion.insert(
        day: day,
        diet: Value(diet),
        sick: Value(sick),
        note: Value(note),
        updatedAt: DateTime.now(),
      ));

  /// Saving an entry made from a template refreshes the template, so it always proposes the latest values.
  Future<void> saveEntry(MealEntriesCompanion entry) => transaction(() async {
        final now = DateTime.now();
        await into(mealEntries).insertOnConflictUpdate(entry.copyWith(updatedAt: Value(now)));
        final templateId = entry.templateId.present ? entry.templateId.value : null;
        if (templateId == null) return;
        await (update(mealTemplates)..where((t) => t.id.equals(templateId))).write(MealTemplatesCompanion(
          items: entry.items,
          withWhom: entry.withWhom,
          meal: Value(entry.meal.value),
          lastUsedAt: Value(now),
          updatedAt: Value(now),
        ));
        await customUpdate(
          'UPDATE meal_templates SET use_count = use_count + 1 WHERE id = ?',
          variables: [Variable.withString(templateId)],
          updates: {mealTemplates},
        );
      });

  Future<void> setEntryDeleted(String id, bool deleted) {
    final now = DateTime.now();
    return (update(mealEntries)..where((e) => e.id.equals(id))).write(MealEntriesCompanion(
      deletedAt: Value(deleted ? now : null),
      updatedAt: Value(now),
    ));
  }

  Future<List<MealEntry>> _history() => (select(mealEntries)
        ..where((e) => e.deletedAt.isNull())
        ..orderBy([(e) => OrderingTerm.desc(e.day), (e) => OrderingTerm.desc(e.startMinutes)])
        ..limit(2000))
      .get();

  Future<List<FoodSuggestion>> foodSuggestions() async {
    final byFood = <String, FoodSuggestion>{};
    for (final e in await _history()) {
      for (final item in e.items) {
        if (item.food.trim().isEmpty) continue;
        final key = foodKey(item);
        final known = byFood[key];
        byFood[key] = known == null
            ? FoodSuggestion(item, 1)
            : FoodSuggestion(known.last, known.count + 1);
      }
    }
    return byFood.values.toList()..sort((a, b) => b.count.compareTo(a.count));
  }

  static String foodKey(FoodItem item) => '${item.drink}|${item.food.trim().toLowerCase()}';

  /// Part names per [foodKey] of their parent, most used first; parts are only proposed under the same parent.
  Future<Map<String, List<String>>> partHistory() async {
    // Per parent: lower-cased part name -> (most recent spelling, count).
    final byParent = <String, Map<String, (String, int)>>{};
    for (final e in await _history()) {
      for (final item in e.items) {
        for (final part in item.parts) {
          final name = part.food.trim();
          if (name.isEmpty) continue;
          final parts = byParent.putIfAbsent(foodKey(item), () => {});
          final known = parts[name.toLowerCase()];
          parts[name.toLowerCase()] = (known?.$1 ?? name, (known?.$2 ?? 0) + 1);
        }
      }
    }
    return {
      for (final MapEntry(:key, value: parts) in byParent.entries)
        key: (parts.values.toList()..sort((a, b) => b.$2.compareTo(a.$2))).map((p) => p.$1).toList(),
    };
  }

  /// The latest duration per lower-cased sport, proposed when it is picked again.
  Future<Map<String, int>> lastSportMinutes() async {
    final result = <String, int>{};
    for (final e in await _history()) {
      for (final s in e.sports) {
        if (s.minutes != null) result.putIfAbsent(s.sport.toLowerCase(), () => s.minutes!);
      }
    }
    return result;
  }

  Stream<List<ListValue>> watchLists() => (select(listValues)
        ..where((v) => v.deletedAt.isNull())
        ..orderBy([(v) => OrderingTerm.asc(v.position)]))
      .watch();

  /// A deleted value of the same name comes back instead of a duplicate.
  Future<void> addListValue(ListKind kind, String name, {String plural = ''}) => transaction(() async {
        // Compared in Dart: SQLite's lower() leaves umlauts alone.
        final values = await (select(listValues)..where((v) => v.kind.equalsValue(kind))).get();
        final same = values.where((v) => v.name.toLowerCase() == name.toLowerCase()).firstOrNull;
        if (same != null) {
          if (same.deletedAt != null) await updateListValue(same.id, name: name, plural: plural, deleted: false);
          return;
        }
        await into(listValues).insert(ListValuesCompanion.insert(
          id: newId(),
          kind: kind,
          name: name,
          plural: Value(plural),
          position: values.fold(0, (p, v) => max(p, v.position + 1)),
          updatedAt: DateTime.now(),
        ));
      });

  Future<void> updateListValue(String id, {String? name, String? plural, bool? deleted}) {
    final now = DateTime.now();
    return (update(listValues)..where((v) => v.id.equals(id))).write(ListValuesCompanion(
      name: name == null ? const Value.absent() : Value(name),
      plural: plural == null ? const Value.absent() : Value(plural),
      deletedAt: deleted == null ? const Value.absent() : Value(deleted ? now : null),
      updatedAt: Value(now),
    ));
  }

  /// Number of entries using each value of [kind], by lower-cased name as the lists match names.
  Future<Map<String, int>> listUsage(ListKind kind) async {
    final counts = <String, int>{};
    for (final e in await (select(mealEntries)..where((e) => e.deletedAt.isNull())).get()) {
      final used = switch (kind) {
        ListKind.foodUnit => e.items.where((i) => !i.drink).map((i) => i.unit),
        ListKind.drinkUnit => e.items.where((i) => i.drink).map((i) => i.unit),
        ListKind.measure => splitTags(e.measures),
        ListKind.withWhom => splitTags(e.withWhom),
        ListKind.sport => e.sports.map((s) => s.sport),
      };
      for (final value in used.map((v) => v.toLowerCase()).toSet()) {
        counts[value] = (counts[value] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// Most recent meal per distinct set of foods; drinks have their own quick button.
  Future<List<MealEntry>> recentMeals({int limit = 8}) async {
    final seen = <String>{};
    final result = <MealEntry>[];
    for (final e in await _history()) {
      if (e.meal == MealType.drink) continue;
      final signature = (e.items.map((i) => i.food.trim().toLowerCase()).toList()..sort()).join('|');
      if (signature.isEmpty || !seen.add(signature)) continue;
      result.add(e);
      if (result.length == limit) break;
    }
    return result;
  }

  Stream<List<MealTemplate>> watchTemplates() => (select(mealTemplates)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([
          (t) => OrderingTerm.desc(t.pinned),
          (t) => OrderingTerm.desc(t.useCount),
          (t) => OrderingTerm.asc(t.name),
        ]))
      .watch();

  Future<String> createTemplate(String name, MealType meal, List<FoodItem> items, String withWhom) async {
    final id = newId();
    await into(mealTemplates).insert(MealTemplatesCompanion.insert(
      id: id,
      name: name,
      meal: Value(meal),
      items: items,
      withWhom: Value(withWhom),
      updatedAt: DateTime.now(),
    ));
    return id;
  }

  Future<void> updateTemplate(String id, {String? name, bool? pinned, bool? deleted}) {
    final now = DateTime.now();
    return (update(mealTemplates)..where((t) => t.id.equals(id))).write(MealTemplatesCompanion(
      name: name == null ? const Value.absent() : Value(name),
      pinned: pinned == null ? const Value.absent() : Value(pinned),
      deletedAt: deleted == null ? const Value.absent() : Value(deleted ? now : null),
      updatedAt: Value(now),
    ));
  }

  Future<void> purgeDeleted() => transaction(() async {
        await (delete(mealEntries)..where((e) => e.deletedAt.isNotNull())).go();
        await (delete(mealTemplates)..where((t) => t.deletedAt.isNotNull())).go();
      });

  Future<Map<String, dynamic>> exportBackup() async => {
        'format': backupFormat,
        'version': schemaVersion,
        'created': DateTime.now().toUtc().toIso8601String(),
        'entries': [
          for (final r in await (select(mealEntries)..where((e) => e.deletedAt.isNull())).get()) r.toJson(),
        ],
        'dayNotes': [for (final r in await select(dayNotes).get()) r.toJson()],
        'templates': [
          for (final r in await (select(mealTemplates)..where((t) => t.deletedAt.isNull())).get()) r.toJson(),
        ],
        // Deleted values included, so the deletion survives a restore elsewhere.
        'lists': [for (final r in await select(listValues).get()) r.toJson()],
      };

  // The UI parses days and times without checks; a backup file is untrusted input.
  static void _checkDay(String day) {
    final valid = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(day) && dayKey(parseDayKey(day)) == day;
    if (!valid) throw FormatException('Invalid day "$day"');
  }

  static bool _isMinuteOfDay(int minutes) => minutes >= 0 && minutes < 24 * 60;

  static bool _isPercent(int? value) => value == null || (value >= 0 && value <= 100);

  /// Merges by primary key; the row with the newer `updatedAt` wins.
  Future<int> importBackup(Map<String, dynamic> json) async {
    if (json['format'] != backupFormat) throw const FormatException('Not a WhatsEat backup');
    backupCreated(json);
    var changed = 0;
    List<Map<String, dynamic>> rows(String key) =>
        [for (final r in json[key] as List) r as Map<String, dynamic>];

    await transaction(() async {
      // Backups from older schemas lack these columns.
      for (final row in rows('entries').map((r) => MealEntry.fromJson({'running': false, 'sports': '[]', ...r}))) {
        _checkDay(row.day);
        if (!_isMinuteOfDay(row.startMinutes) || (row.endMinutes != null && !_isMinuteOfDay(row.endMinutes!))) {
          throw FormatException('Invalid time in entry ${row.id}');
        }
        if (!_isPercent(row.hunger) || !_isPercent(row.satiety)) {
          throw FormatException('Invalid hunger or satiety in entry ${row.id}');
        }
        // The duration picker only takes durations within a day.
        if (row.sports.any((s) => s.sport.trim().isEmpty || (s.minutes != null && !_isMinuteOfDay(s.minutes!)))) {
          throw FormatException('Invalid sport in entry ${row.id}');
        }
        final local = await (select(mealEntries)..where((e) => e.id.equals(row.id))).getSingleOrNull();
        if (local != null && !row.updatedAt.isAfter(local.updatedAt)) continue;
        await into(mealEntries).insertOnConflictUpdate(row);
        changed++;
      }
      for (final row in rows('dayNotes').map(DayNote.fromJson)) {
        _checkDay(row.day);
        final local = await (select(dayNotes)..where((n) => n.day.equals(row.day))).getSingleOrNull();
        if (local != null && !row.updatedAt.isAfter(local.updatedAt)) continue;
        await into(dayNotes).insertOnConflictUpdate(row);
        changed++;
      }
      for (final row in rows('templates').map(MealTemplate.fromJson)) {
        final local = await (select(mealTemplates)..where((t) => t.id.equals(row.id))).getSingleOrNull();
        if (local != null && !row.updatedAt.isAfter(local.updatedAt)) continue;
        await into(mealTemplates).insertOnConflictUpdate(row);
        changed++;
      }
      if (json['lists'] == null) {
        // From before the lists existed: their values are taken from the entries, as on the update.
        await _fillLists(const {});
      } else {
        for (final row in rows('lists').map(ListValue.fromJson)) {
          // An empty name would collide with "no unit" in the pickers.
          if (row.name.trim().isEmpty) throw FormatException('Empty list value ${row.id}');
          final local = await (select(listValues)..where((v) => v.id.equals(row.id))).getSingleOrNull();
          if (local != null && !row.updatedAt.isAfter(local.updatedAt)) continue;
          await into(listValues).insertOnConflictUpdate(row);
          changed++;
        }
      }
    });
    return changed;
  }
}
