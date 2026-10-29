import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../data/models.dart';
import '../l10n/app_localizations.dart';
import '../providers.dart';
import 'common.dart';
import 'entry_editor.dart';
import 'export_screen.dart';
import 'quick_add_sheet.dart';
import 'settings_screen.dart';
import 'templates_screen.dart';

const _basePage = 100000;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  DateTime _today = dateOnly(DateTime.now());
  final _pages = PageController(initialPage: _basePage);
  late DateTime _day = _today;
  Timer? _midnight;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleMidnight();
  }

  // Timers don't fire while the app is suspended, hence also the check on resume.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _onDateMaybeChanged();
  }

  void _scheduleMidnight() {
    _midnight?.cancel();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    _midnight = Timer(next.difference(now) + const Duration(seconds: 1), _onDateMaybeChanged);
  }

  void _onDateMaybeChanged() {
    _scheduleMidnight();
    final today = dateOnly(DateTime.now());
    if (today == _today) return;
    setState(() {
      if (_day == _today) _day = today;
      _today = today;
    });
    // Pages are numbered relative to today, so the current page must move with it.
    _pages.jumpToPage(_basePage + daysBetween(today, _day));
  }

  DateTime _dayForPage(int page) => DateTime(_today.year, _today.month, _today.day + page - _basePage);

  void _goTo(DateTime day) {
    final page = _basePage + daysBetween(_today, day);
    if ((page - _pages.page!.round()).abs() > 1) {
      _pages.jumpToPage(page);
    } else {
      _pages.animateToPage(page, duration: const Duration(milliseconds: 250), curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnight?.cancel();
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    void push(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

    return Scaffold(
      appBar: AppBar(
        title: Text(relativeDayLabel(context, _day)),
        actions: [
          if (_day != _today) IconButton(tooltip: l.today, icon: const Icon(Icons.today_outlined), onPressed: () => _goTo(_today)),
          IconButton(
            tooltip: l.pickDate,
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _day,
                firstDate: DateTime(2020),
                lastDate: _today.add(const Duration(days: 365)),
              );
              if (picked != null) _goTo(picked);
            },
          ),
          PopupMenuButton<VoidCallback>(
            onSelected: (action) => action(),
            itemBuilder: (_) => [
              PopupMenuItem(value: () => push(ExportScreen(initialDay: _day)), child: Text(l.export)),
              PopupMenuItem(value: () => push(const TemplatesScreen()), child: Text(l.templates)),
              PopupMenuItem(value: () => push(const SettingsScreen()), child: Text(l.settings)),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _WeekStrip(selected: _day, today: _today, onSelect: _goTo),
          const _RunningMealBanner(),
          Expanded(
            child: PageView.builder(
              controller: _pages,
              onPageChanged: (page) => setState(() => _day = _dayForPage(page)),
              itemBuilder: (_, page) => _DayView(day: _dayForPage(page)),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showQuickAddSheet(context, _day),
        icon: const Icon(Icons.add_rounded),
        label: Text(l.addEntry),
      ),
    );
  }
}

class _RunningMealBanner extends ConsumerWidget {
  const _RunningMealBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.watch(runningMealProvider).value;
    if (entry == null) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Card(
        color: scheme.primaryContainer,
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          leading: Icon(Icons.timelapse_rounded, color: scheme.onPrimaryContainer),
          title: Text(l.runningSince(mealLabel(l, entry.meal), formatMinutes(entry.startMinutes)),
              style: TextStyle(color: scheme.onPrimaryContainer)),
          trailing: FilledButton(onPressed: () => finishEating(context, entry), child: Text(l.finishEating)),
          onTap: () => openEntryEditor(context, EntryDraft.fromEntry(entry)),
        ),
      ),
    );
  }
}

class _WeekStrip extends ConsumerWidget {
  const _WeekStrip({required this.selected, required this.today, required this.onSelect});

  final DateTime selected;
  final DateTime today;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final monday = DateTime(selected.year, selected.month, selected.day - selected.weekday + 1);
    final days = [for (var i = 0; i < 7; i++) DateTime(monday.year, monday.month, monday.day + i)];
    final filled = ref.watch(daysWithEntriesProvider((dayKey(days.first), dayKey(days.last)))).value ?? const {};

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => onSelect(DateTime(selected.year, selected.month, selected.day - 7)),
          ),
          for (final day in days)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelect(day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: day == selected ? scheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat.E(locale).format(day),
                        style: TextStyle(
                          fontSize: 12,
                          color: day == selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: day == today ? FontWeight.w800 : FontWeight.w500,
                          color: day == selected ? scheme.onPrimary : (day == today ? scheme.primary : scheme.onSurface),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled.contains(dayKey(day))
                              ? (day == selected ? scheme.onPrimary : scheme.primary)
                              : Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () => onSelect(DateTime(selected.year, selected.month, selected.day + 7)),
          ),
        ],
      ),
    );
  }
}

class _DayView extends ConsumerStatefulWidget {
  const _DayView({required this.day});

  final DateTime day;

  @override
  ConsumerState<_DayView> createState() => _DayViewState();
}

class _DayViewState extends ConsumerState<_DayView> {
  // A dismissed Dismissible must leave the tree at once, before the DB stream catches up.
  final _dismissed = <String>{};

  void _delete(MealEntry entry) {
    final l = AppLocalizations.of(context);
    final db = ref.read(databaseProvider);
    setState(() => _dismissed.add(entry.id));
    db.setEntryDeleted(entry.id, true);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(l.entryDeleted),
        action: SnackBarAction(
          label: l.undo,
          onPressed: () async {
            await db.setEntryDeleted(entry.id, false);
            if (mounted) setState(() => _dismissed.remove(entry.id));
          },
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final key = dayKey(widget.day);
    final entries = ref.watch(dayEntriesProvider(key)).value?.where((e) => !_dismissed.contains(e.id)).toList();
    final note = ref.watch(dayNoteProvider(key)).value;
    if (entries == null) return const SizedBox();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      children: [
        if (entries.isNotEmpty) ...[_DayTimeline(entries: entries), const SizedBox(height: 12)],
        _DayNoteTile(day: key, note: note),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Column(
              children: [
                Icon(Icons.restaurant_outlined, size: 56, color: Theme.of(context).colorScheme.outlineVariant),
                const SizedBox(height: 12),
                Text(l.emptyDay, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(l.emptyDayHint, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        for (final entry in entries)
          Padding(padding: const EdgeInsets.only(bottom: 10), child: _EntryCard(entry: entry, onDismissed: () => _delete(entry))),
      ],
    );
  }
}

/// Shows when meals happened; long gaps stand out without counting or averaging anything.
class _DayTimeline extends StatelessWidget {
  const _DayTimeline({required this.entries});

  final List<MealEntry> entries;

  static const _marker = 26.0;

  (Color, Color) _colors(ColorScheme s, MealType meal) => switch (meal) {
        MealType.breakfast => (s.tertiaryContainer, s.onTertiaryContainer),
        MealType.lunch => (s.primary, s.onPrimary),
        MealType.dinner => (s.secondary, s.onSecondary),
        MealType.snack => (s.secondaryContainer, s.onSecondaryContainer),
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant);
    var from = 5 * 60;
    var to = 23 * 60;
    for (final e in entries) {
      from = min(from, e.startMinutes ~/ 60 * 60);
      to = min(max(to, (max(e.startMinutes, e.endMinutes ?? 0) ~/ 60 + 1) * 60), 24 * 60);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: SizedBox(
          height: _marker + 18,
          child: LayoutBuilder(builder: (context, box) {
            double x(int minutes) => (minutes - from) / (to - from) * (box.maxWidth - _marker);
            return Stack(children: [
              Positioned(
                left: _marker / 2,
                right: _marker / 2,
                top: _marker / 2 - 1,
                child: Container(height: 2, color: scheme.outlineVariant),
              ),
              for (final hour in const [6, 12, 18])
                if (hour * 60 > from && hour * 60 < to)
                  Positioned(
                    left: x(hour * 60) + _marker / 2 - 20,
                    width: 40,
                    top: _marker + 2,
                    child: Text('$hour:00', textAlign: TextAlign.center, style: labelStyle),
                  ),
              for (final e in entries) ...[
                if (e.endMinutes != null && e.endMinutes! > e.startMinutes)
                  Positioned(
                    left: x(e.startMinutes) + _marker / 2,
                    width: x(e.endMinutes!) - x(e.startMinutes),
                    top: _marker / 2 - 3,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: _colors(scheme, e.meal).$1,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                Positioned(
                  left: x(e.startMinutes),
                  top: 0,
                  child: CircleAvatar(
                    radius: _marker / 2,
                    backgroundColor: _colors(scheme, e.meal).$1,
                    child: Icon(mealIcon(e.meal), size: 14, color: _colors(scheme, e.meal).$2),
                  ),
                ),
              ],
            ]);
          }),
        ),
      ),
    );
  }
}

class _DayNoteTile extends ConsumerWidget {
  const _DayNoteTile({required this.day, required this.note});

  final String day;
  final DayNote? note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final n = note;
    final parts = [
      if (n?.diet ?? false) l.noteDiet,
      if (n?.sick ?? false) l.noteSick,
      if (n != null && n.note.isNotEmpty) n.note,
    ];
    return Card(
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: const Icon(Icons.sticky_note_2_outlined),
        title: Text(parts.isEmpty ? l.dayNoteAdd : parts.join(' · '), maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: parts.isEmpty ? Text(l.dayNoteHint) : null,
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          useSafeArea: true,
          builder: (_) => _DayNoteSheet(day: day, note: n),
        ),
      ),
    );
  }
}

class _DayNoteSheet extends ConsumerStatefulWidget {
  const _DayNoteSheet({required this.day, required this.note});

  final String day;
  final DayNote? note;

  @override
  ConsumerState<_DayNoteSheet> createState() => _DayNoteSheetState();
}

class _DayNoteSheetState extends ConsumerState<_DayNoteSheet> {
  late bool _diet = widget.note?.diet ?? false;
  late bool _sick = widget.note?.sick ?? false;
  late final _text = TextEditingController(text: widget.note?.note ?? '');

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.dayNote, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            FilterChip(label: Text(l.noteDiet), selected: _diet, onSelected: (v) => setState(() => _diet = v)),
            FilterChip(label: Text(l.noteSick), selected: _sick, onSelected: (v) => setState(() => _sick = v)),
          ]),
          const SizedBox(height: 12),
          TextField(controller: _text, minLines: 2, maxLines: 5, decoration: InputDecoration(hintText: l.dayNoteHint)),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              await ref.read(databaseProvider).saveDayNote(widget.day, diet: _diet, sick: _sick, note: _text.text.trim());
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(l.save),
          ),
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry, required this.onDismissed});

  final MealEntry entry;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Widget badge(IconData icon, String text, {bool alert = false}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: alert ? scheme.errorContainer : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: alert ? scheme.onErrorContainer : scheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Flexible(
              child: Text(text,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: alert ? scheme.onErrorContainer : scheme.onSurfaceVariant)),
            ),
          ]),
        );

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(20)),
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      onDismissed: (_) => onDismissed(),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openEntryEditor(context, EntryDraft.fromEntry(entry)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: scheme.primaryContainer,
                  child: Icon(mealIcon(entry.meal), color: scheme.onPrimaryContainer, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(mealLabel(l, entry.meal), style: theme.textTheme.titleSmall),
                        const Spacer(),
                        Text(timeRange(entry.startMinutes, entry.endMinutes),
                            style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
                      ]),
                      const SizedBox(height: 4),
                      Text(itemsSummary(l, entry.items), style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      Wrap(spacing: 6, runSpacing: 6, children: [
                        if (entry.hunger != null) badge(Icons.wb_twilight_rounded, '${l.hunger} ${entry.hunger} %'),
                        if (entry.satiety != null) badge(Icons.nights_stay_outlined, '${l.satiety} ${entry.satiety} %'),
                        if (entry.running) badge(Icons.timelapse_rounded, l.inProgress),
                        if (entry.withWhom.isNotEmpty) badge(Icons.people_outline, entry.withWhom),
                        if (entry.binge) badge(Icons.warning_amber_rounded, l.binge, alert: true),
                        if (entry.measures.isNotEmpty) badge(Icons.flag_outlined, entry.measures, alert: true),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
