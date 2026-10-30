import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

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

class FoodSuggestion {
  const FoodSuggestion(this.last, this.count);

  final FoodItem last;
  final int count;

  String get food => last.food;
}

@DriftDatabase(tables: [MealEntries, DayNotes, MealTemplates])
class AppDatabase extends _$AppDatabase {
  AppDatabase(String key)
      : super(driftDatabase(
          name: 'whatseat',
          native: DriftNativeOptions(
            // sqlite3mc (see pubspec hooks); the key is hex, so quoting is safe.
            setup: (db) => db.execute("PRAGMA key = '$key'"),
          ),
        ));

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.addColumn(mealEntries, mealEntries.running);
        },
      );

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
        final name = item.food.trim().toLowerCase();
        if (name.isEmpty) continue;
        final key = '${item.drink}|$name';
        final known = byFood[key];
        byFood[key] = known == null
            ? FoodSuggestion(item, 1)
            : FoodSuggestion(known.last, known.count + 1);
      }
    }
    return byFood.values.toList()..sort((a, b) => b.count.compareTo(a.count));
  }

  Future<List<String>> unitHistory({required bool drink}) async {
    final counts = <String, int>{};
    for (final e in await _history()) {
      for (final unit in e.items.where((i) => i.drink == drink).map((i) => i.unit).where((u) => u.isNotEmpty)) {
        counts[unit] = (counts[unit] ?? 0) + 1;
      }
    }
    return counts.keys.toList()..sort((a, b) => counts[b]!.compareTo(counts[a]!));
  }

  Future<List<String>> tagHistory(String Function(MealEntry) column) async {
    final counts = <String, int>{};
    for (final e in await _history()) {
      for (final tag in splitTags(column(e))) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    return counts.keys.toList()..sort((a, b) => counts[b]!.compareTo(counts[a]!));
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

  Future<Map<String, dynamic>> exportBackup() async => {
        'format': 'whatseat-backup',
        'version': schemaVersion,
        'entries': [for (final r in await select(mealEntries).get()) r.toJson()],
        'dayNotes': [for (final r in await select(dayNotes).get()) r.toJson()],
        'templates': [for (final r in await select(mealTemplates).get()) r.toJson()],
      };

  /// Merges by primary key; the row with the newer `updatedAt` wins.
  Future<int> importBackup(Map<String, dynamic> json) async {
    if (json['format'] != 'whatseat-backup') throw const FormatException('Not a WhatsEat backup');
    var changed = 0;
    List<Map<String, dynamic>> rows(String key) =>
        [for (final r in json[key] as List) r as Map<String, dynamic>];

    await transaction(() async {
      // Backups from schema 1 lack the column.
      for (final row in rows('entries').map((r) => MealEntry.fromJson({'running': false, ...r}))) {
        final local = await (select(mealEntries)..where((e) => e.id.equals(row.id))).getSingleOrNull();
        if (local != null && !row.updatedAt.isAfter(local.updatedAt)) continue;
        await into(mealEntries).insertOnConflictUpdate(row);
        changed++;
      }
      for (final row in rows('dayNotes').map(DayNote.fromJson)) {
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
    });
    return changed;
  }
}
