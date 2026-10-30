import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:whatseat/data/database.dart';
import 'package:whatseat/data/models.dart';
import 'package:whatseat/export/protocol_export.dart';
import 'package:whatseat/l10n/app_localizations.dart';
import 'package:whatseat/ui/common.dart';

MealEntriesCompanion _entry(String day, int start, List<FoodItem> items, {String? templateId, bool binge = false}) =>
    MealEntriesCompanion.insert(
      id: newId(),
      day: day,
      meal: mealTypeForTime(start),
      startMinutes: start,
      items: items,
      hunger: const Value(70),
      binge: Value(binge),
      templateId: Value(templateId),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('day differences ignore DST switches', () {
    expect(daysBetween(DateTime(2026, 3, 28), DateTime(2026, 3, 30)), 2);
    expect(daysBetween(DateTime(2026, 10, 26), DateTime(2026, 10, 24)), -2);
  });

  test('drinks and foods suggest separately', () async {
    await db.saveEntry(_entry('2026-10-29', 8 * 60, const [
      FoodItem(quantity: 1, unit: 'Scheibe', food: 'Brot'),
      FoodItem(quantity: 200, unit: 'ml', food: 'Wasser', drink: true),
    ]));
    final suggestions = await db.foodSuggestions();
    expect([for (final s in suggestions.where((s) => s.last.drink)) s.food], ['Wasser']);
    expect(await db.unitHistory(drink: true), ['ml']);
    expect(FoodItem.fromJson(const {'quantity': 1, 'unit': 'Scheibe', 'food': 'Brot'}).drink, isFalse);
  });

  test('deleted entries are purged and left out of backups', () async {
    final entry = _entry('2026-10-29', 8 * 60, const [FoodItem(food: 'Brot')]);
    await db.saveEntry(entry);
    await db.setEntryDeleted(entry.id.value, true);
    expect((await db.exportBackup())['entries'], isEmpty);
    await db.purgeDeleted();
    expect(await db.select(db.mealEntries).get(), isEmpty);
  });

  test('CSV cells cannot start a formula', () async {
    final l = await AppLocalizations.delegate.load(const Locale('de'));
    await db.saveEntry(_entry('2026-10-29', 8 * 60, const [FoodItem(food: '=HYPERLINK("x")')]));
    final csv = buildProtocolCsv(l, await loadProtocol(db, DateTime(2026, 10, 29), DateTime(2026, 10, 29)));
    expect(csv, contains("'=HYPERLINK"));
  });

  test('legacy amount strings are parsed', () {
    final item = FoodItem.fromJson(const {'amount': '1,5 Scheiben', 'food': 'Brot'});
    expect(item.quantity, 1.5);
    expect(item.unit, 'Scheiben');
  });

  test('saving an entry from a template refreshes the template', () async {
    final id = await db.createTemplate('Frühstück', MealType.breakfast, const [FoodItem(quantity: 1, unit: 'Tasse', food: 'Kaffee')], '');
    await db.saveEntry(_entry('2026-10-29', 8 * 60, const [FoodItem(quantity: 2, unit: 'Tasse', food: 'Kaffee')], templateId: id));

    final t = (await db.watchTemplates().first).single;
    expect(t.items.single.quantity, 2);
    expect(t.useCount, 1);
  });

  test('food suggestions carry the latest amount', () async {
    await db.saveEntry(_entry('2026-10-28', 8 * 60, const [FoodItem(quantity: 1, unit: 'Scheibe', food: 'Brot')]));
    await db.saveEntry(_entry('2026-10-29', 8 * 60, const [FoodItem(quantity: 2, unit: 'Scheibe', food: 'brot')]));

    final s = (await db.foodSuggestions()).single;
    expect(s.last.quantity, 2);
    expect(s.count, 2);
  });

  test('backup import keeps the newer row', () async {
    await db.saveEntry(_entry('2026-10-29', 12 * 60, const [FoodItem(food: 'Nudeln')]));
    final backup = await db.exportBackup();

    final other = AppDatabase.forTesting(NativeDatabase.memory());
    expect(await other.importBackup(backup), 1);
    expect(await other.importBackup(backup), 0);
    expect((await other.entriesBetween('2026-10-29', '2026-10-29')).single.items.single.food, 'Nudeln');
    await other.close();
  });

  test('running meals stay out of exports until finished', () async {
    final entry = _entry('2026-10-29', 12 * 60, const []).copyWith(running: const Value(true));
    await db.saveEntry(entry);
    expect((await db.watchRunning().first)?.id, entry.id.value);
    expect(await db.entriesBetween('2026-10-29', '2026-10-29'), isEmpty);

    await db.saveEntry(entry.copyWith(running: const Value(false), items: const Value([FoodItem(food: 'Suppe')])));
    expect(await db.watchRunning().first, isNull);
    expect(await db.entriesBetween('2026-10-29', '2026-10-29'), hasLength(1));
  });

  test('schema 1 backups import', () async {
    await db.saveEntry(_entry('2026-10-29', 12 * 60, const [FoodItem(food: 'Nudeln')]));
    final backup = await db.exportBackup();
    for (final e in backup['entries'] as List) {
      (e as Map<String, dynamic>).remove('running');
    }

    final other = AppDatabase.forTesting(NativeDatabase.memory());
    expect(await other.importBackup(backup), 1);
    await other.close();
  });

  test('exports render', () async {
    await initializeDateFormatting('de');
    final l = lookupAppLocalizations(const Locale('de'));
    await db.saveEntry(_entry('2026-10-29', 12 * 60, const [FoodItem(quantity: 1.5, unit: 'Portion', food: 'Nudeln; gekocht')], binge: true));
    await db.saveDayNote('2026-10-29', diet: false, sick: true, note: '');
    final days = await loadProtocol(db, DateTime(2026, 10, 27), DateTime(2026, 10, 30));

    expect(days.single.entries, hasLength(1));
    final csv = buildProtocolCsv(l, days);
    expect(csv, contains('"Nudeln; gekocht"'));
    expect(csv, contains('Krank'));
    expect(csv, contains('1,5 Portionen'));
    expect(days.single.entries.single.items.single.unit, 'Portion');
    final pdf = await buildProtocolPdf(l, days, 'Test');
    expect(String.fromCharCodes(pdf.take(4)), '%PDF');
  });
}
