import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../data/models.dart';
import '../l10n/app_localizations.dart';
import '../providers.dart';
import 'common.dart';

int _nowMinutes() {
  final now = DateTime.now();
  return now.hour * 60 + now.minute;
}

bool _isToday(DateTime day) => dateOnly(day) == dateOnly(DateTime.now());

class EntryDraft {
  EntryDraft({
    this.id,
    required this.day,
    required this.meal,
    required this.start,
    this.end,
    required this.items,
    this.withWhom = '',
    this.appetiteFor = '',
    this.situationBefore = '',
    this.hunger,
    this.satiety,
    this.binge = false,
    this.measures = '',
    this.situationAfter = '',
    this.templateId,
    this.running = false,
    this.createdAt,
  });

  factory EntryDraft.fresh(DateTime day) {
    final start = _nowMinutes();
    return EntryDraft(day: dayKey(day), meal: mealTypeForTime(start), start: start, items: const []);
  }

  factory EntryDraft.fromTemplate(MealTemplate t, DateTime day) {
    final start = _nowMinutes();
    return EntryDraft(
      day: dayKey(day),
      meal: t.meal ?? mealTypeForTime(start),
      start: start,
      items: t.items,
      withWhom: t.withWhom,
      templateId: t.id,
    );
  }

  /// Copies every value of a past entry; only the day (and, for today, the time) is new.
  factory EntryDraft.repeat(MealEntry e, DateTime day) {
    final start = _isToday(day) ? _nowMinutes() : e.startMinutes;
    final duration = e.endMinutes == null ? null : e.endMinutes! - e.startMinutes;
    return EntryDraft(
      day: dayKey(day),
      meal: _isToday(day) ? mealTypeForTime(start) : e.meal,
      start: start,
      end: duration == null ? null : (start + duration).clamp(0, 24 * 60 - 1),
      items: e.items,
      withWhom: e.withWhom,
      appetiteFor: e.appetiteFor,
      situationBefore: e.situationBefore,
      hunger: e.hunger,
      satiety: e.satiety,
      binge: e.binge,
      measures: e.measures,
      situationAfter: e.situationAfter,
      templateId: e.templateId,
    );
  }

  factory EntryDraft.fromEntry(MealEntry e) => EntryDraft(
        id: e.id,
        day: e.day,
        meal: e.meal,
        start: e.startMinutes,
        end: e.endMinutes,
        items: e.items,
        withWhom: e.withWhom,
        appetiteFor: e.appetiteFor,
        situationBefore: e.situationBefore,
        hunger: e.hunger,
        satiety: e.satiety,
        binge: e.binge,
        measures: e.measures,
        situationAfter: e.situationAfter,
        templateId: e.templateId,
        running: e.running,
        createdAt: e.createdAt,
      );

  final String? id;
  final String day;
  MealType meal;
  int start;
  int? end;
  List<FoodItem> items;
  String withWhom;
  String appetiteFor;
  String situationBefore;
  int? hunger;
  int? satiety;
  bool binge;
  String measures;
  String situationAfter;
  String? templateId;
  bool running;
  final DateTime? createdAt;

  MealEntriesCompanion toCompanion() {
    final now = DateTime.now();
    return MealEntriesCompanion.insert(
      id: id ?? newId(),
      day: day,
      meal: meal,
      startMinutes: start,
      endMinutes: Value(end),
      items: items,
      withWhom: Value(withWhom),
      appetiteFor: Value(appetiteFor),
      situationBefore: Value(situationBefore),
      hunger: Value(hunger),
      satiety: Value(satiety),
      binge: Value(binge),
      measures: Value(measures),
      situationAfter: Value(situationAfter),
      templateId: Value(templateId),
      running: Value(running),
      createdAt: createdAt ?? now,
      updatedAt: now,
    );
  }
}

enum EditorMode { edit, start, finish }

Future<void> openEntryEditor(BuildContext context, EntryDraft draft, {EditorMode mode = EditorMode.edit}) => Navigator.push(
      context,
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => EntryEditor(draft: draft, mode: mode)),
    );

/// A meal left running for hours was most likely not stopped in time, so the end is asked for instead of assumed.
Future<void> finishEating(BuildContext context, MealEntry entry) async {
  final draft = EntryDraft.fromEntry(entry);
  final day = parseDayKey(entry.day);
  final started = DateTime(day.year, day.month, day.day, 0, entry.startMinutes);
  final now = DateTime.now();
  if (now.difference(started) > const Duration(hours: 2)) {
    final picked = await showTimePicker(
      context: context,
      helpText: AppLocalizations.of(context).whenDidYouStop,
      initialTime: TimeOfDay.fromDateTime(started.add(const Duration(minutes: 30))),
    );
    if (picked == null || !context.mounted) return;
    draft.end = picked.hour * 60 + picked.minute;
  } else {
    draft.end = now.hour * 60 + now.minute;
  }
  await openEntryEditor(context, draft, mode: EditorMode.finish);
}

class _ItemRow {
  _ItemRow(FoodItem item, String quantityText, {required this.touched})
      : drink = item.drink,
        quantity = TextEditingController(text: quantityText),
        unit = TextEditingController(text: item.unit),
        food = TextEditingController(text: item.food);

  final bool drink;
  final TextEditingController quantity;
  final TextEditingController unit;
  final TextEditingController food;
  final foodFocus = FocusNode();

  /// Untouched rows still hold the default amount and take over the last amount of a picked food.
  bool touched;

  void dispose() {
    quantity.dispose();
    unit.dispose();
    food.dispose();
    foodFocus.dispose();
  }
}

class EntryEditor extends ConsumerStatefulWidget {
  const EntryEditor({super.key, required this.draft, this.mode = EditorMode.edit});

  final EntryDraft draft;
  final EditorMode mode;

  @override
  ConsumerState<EntryEditor> createState() => _EntryEditorState();
}

class _EntryEditorState extends ConsumerState<EntryEditor> {
  late final EntryDraft _d = widget.draft;
  late final _quantityFormat = NumberFormat('#.##', AppLocalizations.of(context).localeName);
  late final List<_ItemRow> _foodRows = [
    for (final item in _d.items)
      if (!item.drink) _row(item),
    if (!_isDrink && !_d.items.any((i) => !i.drink)) _newRow(drink: false),
  ];
  late final List<_ItemRow> _drinkRows = [
    for (final item in _d.items)
      if (item.drink) _row(item),
    if (_isDrink && _d.items.isEmpty) _newRow(drink: true),
  ];
  late final _appetiteFor = TextEditingController(text: _d.appetiteFor);
  late final _before = TextEditingController(text: _d.situationBefore);
  late final _after = TextEditingController(text: _d.situationAfter);
  List<FoodSuggestion> _foods = const [];
  List<String> _whoHistory = const [];
  List<String> _measureHistory = const [];
  List<String> _unitHistory = const [];
  List<String> _drinkUnitHistory = const [];
  bool _dirty = false;

  bool get _isDrink => _d.meal == MealType.drink;

  bool get _staysRunning => widget.mode == EditorMode.start || (widget.mode == EditorMode.edit && _d.running);

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    final db = ref.read(databaseProvider);
    final foods = await db.foodSuggestions();
    final who = await db.tagHistory((e) => e.withWhom);
    final measures = await db.tagHistory((e) => e.measures);
    final units = await db.unitHistory(drink: false);
    final drinkUnits = await db.unitHistory(drink: true);
    if (!mounted) return;
    setState(() {
      _foods = foods;
      _whoHistory = who;
      _measureHistory = measures;
      _unitHistory = units;
      _drinkUnitHistory = drinkUnits;
    });
  }

  @override
  void dispose() {
    for (final r in [..._foodRows, ..._drinkRows]) {
      r.dispose();
    }
    _appetiteFor.dispose();
    _before.dispose();
    _after.dispose();
    super.dispose();
  }

  _ItemRow _row(FoodItem item) => _ItemRow(item, _formatQuantity(item.quantity), touched: true);

  _ItemRow _newRow({required bool drink}) {
    final l = AppLocalizations.of(context);
    final quantity = drink ? 200.0 : 1.0;
    return _ItemRow(
      FoodItem(quantity: quantity, unit: (drink ? drinkUnits(l) : foodUnits(l)).first, food: '', drink: drink),
      _formatQuantity(quantity),
      touched: false,
    );
  }

  String _formatQuantity(double? q) => q == null ? '' : _quantityFormat.format(q);

  void _change(VoidCallback fn) => setState(() {
        fn();
        _dirty = true;
      });

  /// Text fields change without setState; PopScope only sees the flag after a rebuild.
  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _addUnit(_ItemRow row) async {
    final l = AppLocalizations.of(context);
    final unit = (await showTextDialog(context, title: l.newUnit, label: l.unit))?.trim() ?? '';
    if (unit.isEmpty) return;
    await ref.read(settingsProvider.notifier).addUnit(unit);
    _change(() {
      row.unit.text = unit;
      row.touched = true;
    });
  }

  void _removeRow(_ItemRow row) {
    _change(() => (row.drink ? _drinkRows : _foodRows).remove(row));
    // Its text fields still reference the controllers until this frame unmounts them.
    WidgetsBinding.instance.addPostFrameCallback((_) => row.dispose());
  }

  List<FoodItem> _collectItems() => [
        for (final r in [..._foodRows, ..._drinkRows])
          if (r.food.text.trim().isNotEmpty)
            FoodItem(
              quantity: parseQuantity(r.quantity.text),
              unit: r.unit.text.trim(),
              food: r.food.text.trim(),
              drink: r.drink,
            ),
      ];

  void _applyTexts() {
    _d.items = _collectItems();
    _d.appetiteFor = _appetiteFor.text.trim();
    _d.situationBefore = _before.text.trim();
    _d.situationAfter = _after.text.trim();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    _applyTexts();
    _d.running = _staysRunning;
    if (_d.items.isEmpty && !_d.running) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.needOneItem)));
      (_isDrink ? _drinkRows : _foodRows).first.foodFocus.requestFocus();
      return;
    }
    await ref.read(databaseProvider).saveEntry(_d.toCompanion());
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _saveAsTemplate() async {
    final l = AppLocalizations.of(context);
    final items = _collectItems();
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.needOneItem)));
      return;
    }
    final name = await showTextDialog(
      context,
      title: l.saveAsTemplate,
      initial: '${mealLabel(l, _d.meal)}: ${items.first.food}',
      label: l.templateName,
    );
    if (name == null || name.isEmpty) return;
    final id = await ref.read(databaseProvider).createTemplate(name, _d.meal, items, _d.withWhom);
    _change(() => _d.templateId = id);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.templateSaved)));
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.deleteEntryQuestion),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.delete)),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(databaseProvider).setEntryDeleted(_d.id!, true);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickTime({required bool end}) async {
    final current = end ? (_d.end ?? _d.start + 15) : _d.start;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (current ~/ 60) % 24, minute: current % 60),
    );
    if (picked == null) return;
    final minutes = picked.hour * 60 + picked.minute;
    _change(() => end ? _d.end = minutes : _d.start = minutes);
  }

  void _addRow({required bool drink}) {
    final row = _newRow(drink: drink);
    setState(() => (drink ? _drinkRows : _foodRows).add(row));
    WidgetsBinding.instance.addPostFrameCallback((_) => row.foodFocus.requestFocus());
  }

  Widget _itemRow(AppLocalizations l, int index, _ItemRow row) {
    final units = {
      ...(row.drink ? drinkUnits(l) : foodUnits(l)),
      ...ref.watch(settingsProvider.select((s) => s.customUnits)),
      ...(row.drink ? _drinkUnitHistory : _unitHistory),
      if (row.unit.text.isNotEmpty) row.unit.text,
    };
    final foods = _foods.where((f) => f.last.drink == row.drink);
    final rows = row.drink ? _drinkRows : _foodRows;
    // The entry's own kind needs one row left; the other section can be emptied.
    final removable = row.drink != _isDrink || rows.length > 1;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        width: 52,
        child: TextField(
          controller: row.quantity,
          textAlign: TextAlign.center,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
          onTap: () => row.quantity.selection = TextSelection(baseOffset: 0, extentOffset: row.quantity.text.length),
          onChanged: (_) {
            row.touched = true;
            _markDirty();
          },
          decoration: InputDecoration(hintText: l.quantityHint, contentPadding: const EdgeInsets.symmetric(vertical: 12)),
        ),
      ),
      const SizedBox(width: 6),
      SizedBox(
        width: 100,
        child: _UnitPicker(
          unit: row.unit.text,
          units: units.toList(),
          newUnitLabel: l.newUnit,
          noUnitLabel: l.noUnit,
          onSelected: (unit) => _change(() {
            row.unit.text = unit;
            row.touched = true;
          }),
          onAdd: () => _addUnit(row),
        ),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: _SuggestField<FoodSuggestion>(
          controller: row.food,
          focusNode: row.foodFocus,
          hint: row.drink ? l.drinkHint : l.foodHint,
          autofocus: index == 0 &&
              row.drink == _isDrink &&
              _d.items.isEmpty &&
              (_d.id == null || widget.mode == EditorMode.finish),
          options: (q) => q.isEmpty
              ? foods.take(6).toList()
              : foods.where((f) => f.food.toLowerCase().contains(q.toLowerCase())).take(8).toList(),
          display: (f) => f.food,
          subtitle: (f) {
            final amount = formatAmount(l, f.last);
            return amount.isEmpty ? null : l.lastAmount(amount);
          },
          onSelected: (f) {
            if (row.touched) return;
            _change(() {
              row.quantity.text = _formatQuantity(f.last.quantity);
              row.unit.text = f.last.unit;
            });
          },
          onChanged: _markDirty,
        ),
      ),
      if (removable)
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.close_rounded),
          onPressed: () => _removeRow(row),
        ),
    ]);
  }


  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    const gap = SizedBox(height: 12);
    final saveLabel = widget.mode == EditorMode.start ? l.startEatingSave : l.save;

    final meal = SectionCard(title: l.sectionMeal, icon: Icons.schedule_rounded, children: [
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final m in MealType.values)
          if (m != MealType.drink)
            ChoiceChip(
              avatar: Icon(mealIcon(m), size: 18),
              label: Text(mealLabel(l, m)),
              selected: _d.meal == m,
              onSelected: (_) => _change(() => _d.meal = m),
            ),
      ]),
      gap,
      Row(children: [
        ActionChip(
          avatar: const Icon(Icons.play_arrow_rounded, size: 18),
          label: Text('${l.timeFrom} ${formatMinutes(_d.start)}'),
          onPressed: () => _pickTime(end: false),
        ),
        const SizedBox(width: 8),
        if (!_staysRunning)
          InputChip(
            avatar: const Icon(Icons.stop_rounded, size: 18),
            label: Text(_d.end == null ? l.timeToAdd : '${l.timeTo} ${formatMinutes(_d.end!)}'),
            onPressed: () => _pickTime(end: true),
            onDeleted: _d.end == null ? null : () => _change(() => _d.end = null),
          ),
      ]),
    ]);
    final time = SectionCard(title: l.time, icon: Icons.schedule_rounded, children: [
      Align(
        alignment: Alignment.centerLeft,
        child: ActionChip(
          avatar: const Icon(Icons.edit_outlined, size: 18),
          label: Text(formatMinutes(_d.start)),
          onPressed: () => _pickTime(end: false),
        ),
      ),
    ]);
    SectionCard items({required bool drink}) {
      final rows = drink ? _drinkRows : _foodRows;
      return SectionCard(
        title: drink ? l.sectionDrinks : l.sectionFood,
        icon: drink ? Icons.local_drink_outlined : Icons.restaurant_rounded,
        children: [
          for (final (i, row) in rows.indexed) ...[
            if (i > 0) const Divider(height: 24),
            KeyedSubtree(key: ObjectKey(row), child: _itemRow(l, i, row)),
          ],
          if (rows.isNotEmpty) const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _addRow(drink: drink),
              icon: const Icon(Icons.add_rounded),
              label: Text(drink ? l.addDrink : l.addItem),
            ),
          ),
        ],
      );
    }

    final food = items(drink: false);
    final drinks = items(drink: true);
    final who = SectionCard(title: l.withWhom, icon: Icons.people_outline_rounded, children: [
      TagPicker(
        value: _d.withWhom,
        suggestions: {..._whoHistory, ...l.withWhomDefaults.split('|')}.toList(),
        onChanged: (v) => _change(() => _d.withWhom = v),
      ),
    ]);
    final before = SectionCard(title: l.sectionBefore, icon: Icons.flatware_rounded, children: [
      PercentSlider(label: l.hunger, value: _d.hunger, onChanged: (v) => _change(() => _d.hunger = v)),
      gap,
      TextField(
        controller: _appetiteFor,
        onChanged: (_) => _markDirty(),
        decoration: InputDecoration(labelText: l.appetiteFor),
      ),
      gap,
      TextField(
        controller: _before,
        onChanged: (_) => _markDirty(),
        minLines: 2,
        maxLines: 6,
        decoration: InputDecoration(labelText: l.situationBefore, alignLabelWithHint: true),
      ),
    ]);
    final after = SectionCard(title: l.sectionAfter, icon: Icons.sentiment_satisfied_alt_rounded, children: [
      PercentSlider(label: l.satiety, value: _d.satiety, onChanged: (v) => _change(() => _d.satiety = v)),
      gap,
      TextField(
        controller: _after,
        onChanged: (_) => _markDirty(),
        minLines: 2,
        maxLines: 6,
        decoration: InputDecoration(labelText: l.situationAfter, alignLabelWithHint: true),
      ),
    ]);
    final behaviour = SectionCard(title: l.sectionBehaviour, icon: Icons.flag_outlined, children: [
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(l.binge),
        subtitle: Text(l.bingeHint),
        value: _d.binge,
        onChanged: (v) => _change(() => _d.binge = v),
      ),
      gap,
      Text(l.measures, style: theme.textTheme.bodyMedium),
      const SizedBox(height: 8),
      TagPicker(
        value: _d.measures,
        suggestions: {..._measureHistory, ...l.measureDefaults.split('|')}.toList(),
        onChanged: (v) => _change(() => _d.measures = v),
      ),
    ]);
    final sections = _isDrink
        ? [time, drinks]
        : switch (widget.mode) {
            EditorMode.start => [meal, who, before],
            EditorMode.finish => [food, drinks, after, behaviour, meal, who, before],
            EditorMode.edit => [meal, food, drinks, who, before, after, behaviour],
          };

    Widget hint(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
          ]),
        );

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l.discardQuestion),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.keepEditing)),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.discard)),
            ],
          ),
        );
        if (discard == true && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(switch (widget.mode) {
            EditorMode.start => l.startEating,
            EditorMode.finish => l.finishEating,
            EditorMode.edit => _d.id != null ? l.editEntry : (_isDrink ? l.drink : l.newEntry),
          }),
          actions: [
            TextButton(onPressed: _save, child: Text(saveLabel)),
            PopupMenuButton<VoidCallback>(
              onSelected: (action) => action(),
              itemBuilder: (_) => [
                if (widget.mode != EditorMode.start) PopupMenuItem(value: _saveAsTemplate, child: Text(l.saveAsTemplate)),
                if (_d.id != null) PopupMenuItem(value: _delete, child: Text(l.delete)),
              ],
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            if (_d.templateId != null) hint(Icons.bookmark_outline_rounded, l.fromTemplateHint),
            if (widget.mode == EditorMode.start) hint(Icons.timelapse_rounded, l.startEatingHint),
            for (final (i, section) in sections.indexed) ...[if (i > 0) gap, section],
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: _save,
              child: Text(saveLabel),
            ),
          ],
        ),
      ),
    );
  }
}

Future<String?> showTextDialog(BuildContext context, {required String title, String initial = '', String? label}) =>
    showDialog<String>(
      context: context,
      builder: (_) => _TextDialog(title: title, initial: initial, label: label),
    );

/// Owns its controller so it is disposed only after the closing animation, not when the future completes.
class _TextDialog extends StatefulWidget {
  const _TextDialog({required this.title, required this.initial, this.label});

  final String title;
  final String initial;
  final String? label;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: widget.label),
        onSubmitted: (v) => Navigator.pop(context, v.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, _controller.text.trim()), child: Text(l.ok)),
      ],
    );
  }
}

class _SuggestField<T extends Object> extends StatelessWidget {
  const _SuggestField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.options,
    required this.display,
    required this.onSelected,
    required this.onChanged,
    this.subtitle,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final List<T> Function(String query) options;
  final String Function(T) display;
  final String? Function(T)? subtitle;
  final ValueChanged<T> onSelected;
  final VoidCallback onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<T>(
      textEditingController: controller,
      focusNode: focusNode,
      optionsBuilder: (value) => options(value.text.trim()),
      displayStringForOption: display,
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focusNode, onSubmit) => TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        textCapitalization: TextCapitalization.sentences,
        onChanged: (_) => onChanged(),
        onSubmitted: (_) => onSubmit(),
        decoration: InputDecoration(hintText: hint),
      ),
      optionsViewBuilder: (context, select, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260, maxWidth: 320),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                for (final o in options)
                  ListTile(
                    dense: true,
                    title: Text(display(o)),
                    subtitle: switch (subtitle?.call(o)) { final s? => Text(s), null => null },
                    onTap: () => select(o),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PercentSlider extends StatelessWidget {
  const PercentSlider({super.key, required this.label, required this.value, required this.onChanged});

  final String label;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final v = value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Text(label, style: theme.textTheme.bodyLarge),
          const Spacer(),
          Text(v == null ? l.notSet : '$v %',
              style: theme.textTheme.titleMedium?.copyWith(
                  color: v == null ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.primary,
                  fontWeight: FontWeight.w700)),
          if (v != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: () => onChanged(null),
            ),
        ]),
        Opacity(
          opacity: v == null ? 0.45 : 1,
          child: Slider(
            value: (v ?? 0).toDouble(),
            max: 100,
            divisions: 10,
            onChanged: (x) => onChanged(x.round()),
          ),
        ),
        Row(children: [
          Text('0 %', style: theme.textTheme.bodySmall),
          const Spacer(),
          Text('100 %', style: theme.textTheme.bodySmall),
        ]),
      ],
    );
  }
}

class TagPicker extends StatelessWidget {
  const TagPicker({super.key, required this.value, required this.suggestions, required this.onChanged});

  final String value;
  final List<String> suggestions;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final selected = splitTags(value);
    final all = {...selected, ...suggestions}.toList();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tag in all)
          FilterChip(
            label: Text(tag),
            selected: selected.contains(tag),
            onSelected: (on) => onChanged(joinTags(on ? [...selected, tag] : selected.where((t) => t != tag))),
          ),
        ActionChip(
          avatar: const Icon(Icons.add_rounded, size: 18),
          label: Text(l.other),
          onPressed: () async {
            final tag = await showTextDialog(context, title: l.other);
            // Commas would split the value into several tags on reload.
            final clean = tag?.replaceAll(',', ' ').trim() ?? '';
            if (clean.isNotEmpty && !selected.contains(clean)) onChanged(joinTags([...selected, clean]));
          },
        ),
      ],
    );
  }
}

class _UnitPicker extends StatelessWidget {
  const _UnitPicker({
    required this.unit,
    required this.units,
    required this.newUnitLabel,
    required this.noUnitLabel,
    required this.onSelected,
    required this.onAdd,
  });

  static const _addSentinel = '\u0000add';

  final String unit;
  final List<String> units;
  final String newUnitLabel;
  final String noUnitLabel;
  final ValueChanged<String> onSelected;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      tooltip: '',
      initialValue: unit,
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(maxHeight: 360, minWidth: 160),
      onSelected: (v) => v == _addSentinel ? onAdd() : onSelected(v),
      itemBuilder: (_) => [
        for (final u in units)
          PopupMenuItem(
            value: u,
            height: 40,
            child: u.isEmpty
                ? Text(noUnitLabel, style: TextStyle(color: theme.colorScheme.onSurfaceVariant))
                : Text(u),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _addSentinel,
          height: 44,
          child: Row(children: [
            Icon(Icons.add_rounded, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(newUnitLabel, style: TextStyle(color: theme.colorScheme.primary)),
          ]),
        ),
      ],
      child: InputDecorator(
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.fromLTRB(12, 12, 4, 12),
          suffixIcon: Icon(Icons.arrow_drop_down_rounded),
          suffixIconConstraints: BoxConstraints(minWidth: 28),
        ),
        child: Text(unit.isEmpty ? '–' : unit, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
