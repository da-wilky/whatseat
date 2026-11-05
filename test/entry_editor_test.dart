import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatseat/data/database.dart';
import 'package:whatseat/data/models.dart';
import 'package:whatseat/l10n/app_localizations.dart';
import 'package:whatseat/providers.dart';
import 'package:whatseat/ui/entry_editor.dart';

class _Settings extends SettingsNotifier {
  @override
  AppSettings build() => const AppSettings(
        localeCode: 'de',
        patientName: '',
        lockEnabled: false,
        biometricEnabled: false,
        lockTimeoutSeconds: 60,
        pinLength: 4,
        customUnits: [],
      );
}

MealEntriesCompanion _entry(String day, List<FoodItem> items) => MealEntriesCompanion.insert(
      id: newId(),
      day: day,
      meal: MealType.lunch,
      startMinutes: 12 * 60,
      items: items,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> openEditor(WidgetTester tester, EntryDraft draft) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db), settingsProvider.overrideWith(_Settings.new)],
      child: MaterialApp(
        locale: const Locale('de'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
          builder: (context) => TextButton(onPressed: () => openEntryEditor(context, draft), child: const Text('open')),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // Suggestions load from the database in initState.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
  }

  Finder emptyPartFields() => find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == 'z. B. Tomate' && w.controller!.text.isEmpty);

  Future<List<MealEntry>> saved(WidgetTester tester) async =>
      (await tester.runAsync(() => db.entriesBetween('2026-11-05', '2026-11-05')))!;

  testWidgets('picking a food prefills its last parts and suggests only its own parts', (tester) async {
    await tester.runAsync(() async {
      await db.saveEntry(_entry('2026-11-03', const [
        FoodItem(food: 'Salat', parts: [FoodItem(food: 'Gurke')]),
        FoodItem(food: 'Brot', parts: [FoodItem(food: 'Butter')]),
      ]));
      await db.saveEntry(_entry('2026-11-04', const [
        FoodItem(quantity: 1, unit: 'Portion', food: 'Salat', parts: [FoodItem(food: 'Karotte'), FoodItem(food: 'Tomate')]),
      ]));
    });
    await openEditor(tester, EntryDraft(day: '2026-11-05', meal: MealType.lunch, start: 12 * 60, items: const []));

    await tester.enterText(find.widgetWithText(TextField, 'z. B. Vollkornbrot'), 'Sal');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salat').last);
    await tester.pumpAndSettle();
    expect(emptyPartFields(), findsNothing);
    expect(find.widgetWithText(TextField, 'Karotte'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Tomate'), findsOneWidget);

    await tester.tap(find.text('Zutat'));
    await tester.pumpAndSettle();
    expect(emptyPartFields(), findsOneWidget);
    expect(find.text('Butter'), findsNothing);
    expect(find.text('Karotte'), findsOneWidget, reason: 'parts already entered are not suggested again');
    await tester.tap(find.widgetWithText(ListTile, 'Gurke'));
    await tester.pumpAndSettle();

    final tomatoRow = find.ancestor(of: find.widgetWithText(TextField, 'Tomate'), matching: find.byType(Row)).first;
    await tester.tap(find.descendant(of: tomatoRow, matching: find.byIcon(Icons.close_rounded)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Zutat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    final item = (await saved(tester)).single.items.single;
    expect(item.food, 'Salat');
    expect(item.quantity, 1);
    expect(item.parts.map((p) => p.food), ['Karotte', 'Gurke'], reason: 'empty part rows are dropped');
  });

  testWidgets('existing parts are kept and a picked food does not overwrite them', (tester) async {
    await tester.runAsync(() => db.saveEntry(_entry('2026-11-04', const [
          FoodItem(food: 'Salat', parts: [FoodItem(food: 'Karotte')]),
        ])));
    final entry = _entry('2026-11-05', const [
      FoodItem(food: 'Bowl', parts: [FoodItem(food: 'Reis')]),
    ]);
    await tester.runAsync(() => db.saveEntry(entry));
    final stored = (await saved(tester)).single;
    await openEditor(tester, EntryDraft.fromEntry(stored));

    expect(find.widgetWithText(TextField, 'Reis'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Bowl'), 'Sal');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Salat'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Karotte'), findsNothing);

    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    final item = (await saved(tester)).single.items.single;
    expect(item.food, 'Salat');
    expect(item.parts.map((p) => p.food), ['Reis']);
  });

  testWidgets('removing an item with parts disposes cleanly', (tester) async {
    await openEditor(
      tester,
      EntryDraft(day: '2026-11-05', meal: MealType.lunch, start: 12 * 60, items: const [
        FoodItem(food: 'Salat', parts: [FoodItem(food: 'Karotte')]),
        FoodItem(food: 'Brot'),
      ]),
    );
    final saladRow = find.ancestor(of: find.widgetWithText(TextField, 'Salat'), matching: find.byType(Row)).first;
    await tester.tap(find.descendant(of: saladRow, matching: find.byIcon(Icons.close_rounded)));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Karotte'), findsNothing);

    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect((await saved(tester)).single.items.map((i) => i.food), ['Brot']);
  });

  testWidgets('adding parts is only offered on the focused item or one with parts', (tester) async {
    await openEditor(
      tester,
      EntryDraft(day: '2026-11-05', meal: MealType.lunch, start: 12 * 60, items: const [
        FoodItem(food: 'Salat', parts: [FoodItem(food: 'Karotte')]),
        FoodItem(food: 'Brot'),
      ]),
    );
    expect(find.text('Zutat'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextField, 'Brot'));
    await tester.pumpAndSettle();
    expect(find.text('Zutat'), findsNWidgets(2));
    await tester.tap(find.text('Zutat').last);
    await tester.pumpAndSettle();
    expect(emptyPartFields(), findsOneWidget);
  });

  test('nested parts from a backup are cut to one level', () {
    final item = FoodItem.fromJson(const {
      'food': 'Salat',
      'parts': [
        {
          'food': 'Dressing',
          'parts': [
            {'food': 'Öl'},
          ],
        },
      ],
    });
    expect(item.parts.single.food, 'Dressing');
    expect(item.parts.single.parts, isEmpty);
  });
}
