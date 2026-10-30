import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../data/models.dart';
import '../export/protocol_export.dart';
import '../l10n/app_localizations.dart';
import '../providers.dart';
import 'common.dart';
import 'entry_editor.dart';

/// The export's protocol rows, browsable: same data, filtered and grouped by day.
class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  int? _lastDays = 7;
  late DateTimeRange _range = _lastDaysRange(7);
  late Future<List<ProtocolDay>> _days = _load();
  final _meals = <MealType>{};
  bool _incidentsOnly = false;
  bool _searching = false;
  String _query = '';
  final _dayKeys = <DateTime, GlobalKey>{};

  static DateTimeRange _lastDaysRange(int days) {
    final today = dateOnly(DateTime.now());
    return DateTimeRange(start: DateTime(today.year, today.month, today.day - days + 1), end: today);
  }

  Future<List<ProtocolDay>> _load() => loadProtocol(ref.read(databaseProvider), _range.start, _range.end);

  void _setRange(DateTimeRange range, int? lastDays) => setState(() {
        _range = range;
        _lastDays = lastDays;
        _days = _load();
      });

  Future<void> _edit(MealEntry entry) async {
    await openEntryEditor(context, EntryDraft.fromEntry(entry));
    if (mounted) setState(() => _days = _load());
  }

  bool get _filtering => _meals.isNotEmpty || _incidentsOnly || _query.isNotEmpty;

  bool _matches(MealEntry e) {
    if (_meals.isNotEmpty && !_meals.contains(e.meal)) return false;
    if (_incidentsOnly && !e.binge && e.measures.isEmpty) return false;
    final q = _query.toLowerCase();
    return [e.withWhom, e.situationBefore, e.appetiteFor, e.situationAfter, e.measures, for (final i in e.items) i.food]
        .any((s) => s.toLowerCase().contains(q));
  }

  List<ProtocolDay> _filter(List<ProtocolDay> days) => [
        for (final d in days)
          if (d.entries.where(_matches).toList() case final entries when entries.isNotEmpty || !_filtering)
            ProtocolDay(d.day, entries, d.note),
      ];

  void _jumpTo(DateTime day) {
    final target = _dayKeys[day]?.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final material = MaterialLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                autofocus: true,
                decoration: InputDecoration(hintText: l.statsSearch, prefixIcon: const Icon(Icons.search_rounded)),
                onChanged: (v) => setState(() => _query = v.trim()),
              )
            : Text(l.statistics),
        actions: [
          IconButton(
            tooltip: _searching ? material.closeButtonTooltip : material.searchFieldLabel,
            icon: Icon(_searching ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () => setState(() {
              _searching = !_searching;
              _query = '';
            }),
          ),
        ],
      ),
      body: FutureBuilder(
        future: _days,
        builder: (context, snapshot) {
          final days = _filter(snapshot.data ?? const []);
          return CustomScrollView(slivers: [
            SliverToBoxAdapter(child: _controls(l)),
            if (!snapshot.hasData)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (days.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.insights_outlined, size: 56, color: scheme.outlineVariant),
                  const SizedBox(height: 12),
                  Text(l.statsEmpty, style: Theme.of(context).textTheme.titleMedium),
                ]),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                sliver: SliverToBoxAdapter(child: _RangeOverview(days: days, onTapDay: _jumpTo)),
              ),
              for (final day in days) _daySection(l, day),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ]);
        },
      ),
    );
  }

  Widget _controls(AppLocalizations l) {
    final format = DateFormat.MMMd(l.localeName);
    Widget row(List<Widget> chips) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            for (final chip in chips) Padding(padding: const EdgeInsets.only(right: 8), child: chip),
          ]),
        );

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: Column(children: [
        row([
          for (final n in const [7, 14, 30])
            ChoiceChip(
              label: Text(l.lastDays(n)),
              selected: _lastDays == n,
              onSelected: (_) => _setRange(_lastDaysRange(n), n),
            ),
          ChoiceChip(
            avatar: const Icon(Icons.edit_calendar_outlined, size: 18),
            label: Text(_lastDays == null ? '${format.format(_range.start)} – ${format.format(_range.end)}' : l.customRange),
            selected: _lastDays == null,
            onSelected: (_) async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: dateOnly(DateTime.now()),
                initialDateRange: _range,
              );
              if (picked != null) _setRange(picked, null);
            },
          ),
        ]),
        const SizedBox(height: 4),
        row([
          for (final meal in MealType.values)
            FilterChip(
              avatar: Icon(mealIcon(meal), size: 18),
              label: Text(mealLabel(l, meal)),
              selected: _meals.contains(meal),
              onSelected: (on) => setState(() => on ? _meals.add(meal) : _meals.remove(meal)),
            ),
          FilterChip(
            avatar: const Icon(Icons.warning_amber_rounded, size: 18),
            label: Text(l.statsIncidents),
            selected: _incidentsOnly,
            onSelected: (on) => setState(() => _incidentsOnly = on),
          ),
        ]),
      ]),
    );
  }

  Widget _daySection(AppLocalizations l, ProtocolDay day) {
    final theme = Theme.of(context);
    final note = day.note;
    final noteParts = [
      if (note?.diet ?? false) l.noteDiet,
      if (note?.sick ?? false) l.noteSick,
      if (note != null && note.note.isNotEmpty) note.note,
    ];

    return SliverMainAxisGroup(slivers: [
      PinnedHeaderSliver(
        child: Container(
          key: _dayKeys.putIfAbsent(day.day, GlobalKey.new),
          color: theme.colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          child: Text(relativeDayLabel(context, day.day), style: theme.textTheme.titleMedium),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList.list(children: [
          if (noteParts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.sticky_note_2_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(noteParts.join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ),
              ]),
            ),
          for (final e in day.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ProtocolCard(key: ValueKey(e.id), entry: e, onEdit: () => _edit(e)),
            ),
        ]),
      ),
    ]);
  }
}

/// One row per day on a shared clock axis, so regularity across days is visible at a glance.
class _RangeOverview extends StatelessWidget {
  const _RangeOverview({required this.days, required this.onTapDay});

  final List<ProtocolDay> days;
  final ValueChanged<DateTime> onTapDay;

  static const _dot = 14.0;
  static const _label = 64.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant);
    final dayFormat = DateFormat.MEd(l.localeName);
    var from = 5 * 60;
    var to = 23 * 60;
    for (final e in days.expand((d) => d.entries)) {
      from = min(from, e.startMinutes ~/ 60 * 60);
      to = min(max(to, (max(e.startMinutes, e.endMinutes ?? 0) ~/ 60 + 1) * 60), 24 * 60);
    }
    final hours = [for (final h in const [6, 12, 18]) if (h * 60 > from && h * 60 < to) h];

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: LayoutBuilder(builder: (context, box) {
          double x(int minutes) => _label + (minutes - from) / (to - from) * (box.maxWidth - _label - _dot);

          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final day in days)
              InkWell(
                onTap: () => onTapDay(day.day),
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 26,
                  child: Stack(children: [
                    Positioned(
                      left: 4,
                      top: 0,
                      bottom: 0,
                      child: Align(alignment: Alignment.centerLeft, child: Text(dayFormat.format(day.day), style: labelStyle)),
                    ),
                    Positioned(
                      left: _label + _dot / 2,
                      right: _dot / 2,
                      top: 12.5,
                      child: Container(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.6)),
                    ),
                    for (final h in hours)
                      Positioned(
                        left: x(h * 60) + _dot / 2,
                        top: 0,
                        bottom: 0,
                        child: Container(width: 1, color: scheme.outlineVariant.withValues(alpha: 0.4)),
                      ),
                    for (final e in day.entries) ...[
                      if (e.endMinutes != null && e.endMinutes! > e.startMinutes)
                        Positioned(
                          left: x(e.startMinutes) + _dot / 2,
                          width: x(e.endMinutes!) - x(e.startMinutes),
                          top: 10,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: mealColors(scheme, e.meal).$1,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      Positioned(
                        left: x(e.startMinutes),
                        top: 6,
                        child: Container(
                          width: _dot,
                          height: _dot,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: mealColors(scheme, e.meal).$1,
                            border: e.binge || e.measures.isNotEmpty ? Border.all(color: scheme.error, width: 2) : null,
                          ),
                        ),
                      ),
                    ],
                  ]),
                ),
              ),
            SizedBox(
              height: 18,
              child: Stack(children: [
                for (final h in hours)
                  Positioned(
                    left: x(h * 60) + _dot / 2 - 20,
                    width: 40,
                    top: 4,
                    child: Text('$h:00', textAlign: TextAlign.center, style: labelStyle),
                  ),
              ]),
            ),
            const SizedBox(height: 10),
            Wrap(spacing: 14, runSpacing: 6, alignment: WrapAlignment.center, children: [
              for (final meal in MealType.values)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: mealColors(scheme, meal).$1),
                  ),
                  const SizedBox(width: 5),
                  Text(mealLabel(l, meal), style: labelStyle),
                ]),
            ]),
          ]);
        }),
      ),
    );
  }
}

class _ProtocolCard extends StatefulWidget {
  const _ProtocolCard({super.key, required this.entry, required this.onEdit});

  final MealEntry entry;
  final VoidCallback onEdit;

  @override
  State<_ProtocolCard> createState() => _ProtocolCardState();
}

class _ProtocolCardState extends State<_ProtocolCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final e = widget.entry;
    final (background, foreground) = mealColors(scheme, e.meal);
    final body = theme.textTheme.bodyMedium;

    Widget heading(String text) => Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 2),
          child: Text(text, style: theme.textTheme.labelLarge?.copyWith(color: scheme.primary)),
        );
    Widget field(String label, String value) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 2),
            Text(value, style: body),
          ]),
        );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                CircleAvatar(radius: 16, backgroundColor: background, child: Icon(mealIcon(e.meal), size: 16, color: foreground)),
                const SizedBox(width: 10),
                Text(mealLabel(l, e.meal), style: theme.textTheme.titleSmall),
                if (e.binge || e.measures.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.warning_amber_rounded, size: 16, color: scheme.error),
                ],
                const Spacer(),
                Text(timeRange(e.startMinutes, e.endMinutes),
                    style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.expand_more_rounded, size: 20, color: scheme.onSurfaceVariant),
                ),
              ]),
              if (!_expanded) ...[
                const SizedBox(height: 8),
                Text(itemsSummary(l, e.items), maxLines: 2, overflow: TextOverflow.ellipsis, style: body),
              ] else ...[
                if (e.withWhom.isNotEmpty || e.situationBefore.isNotEmpty || e.appetiteFor.isNotEmpty) ...[
                  heading(l.sectionBefore),
                  if (e.withWhom.isNotEmpty) field(l.withWhom, e.withWhom),
                  if (e.situationBefore.isNotEmpty) field(l.situationBefore, e.situationBefore),
                  if (e.appetiteFor.isNotEmpty) field(l.appetiteFor, e.appetiteFor),
                ],
                heading(l.sectionFood),
                const SizedBox(height: 6),
                Table(
                  columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
                  children: [
                    for (final item in e.items)
                      TableRow(children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 12, bottom: 4),
                          child: Text(formatAmount(l, item),
                              textAlign: TextAlign.right, style: body?.copyWith(color: scheme.onSurfaceVariant)),
                        ),
                        Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(item.food, style: body)),
                      ]),
                  ],
                ),
              ],
              if (e.hunger != null || e.satiety != null) ...[
                const SizedBox(height: 12),
                _HungerSatietyBar(hunger: e.hunger, satiety: e.satiety),
              ],
              if (_expanded) ...[
                if (e.situationAfter.isNotEmpty) ...[
                  heading(l.sectionAfter),
                  field(l.situationAfter, e.situationAfter),
                ],
                heading(l.sectionBehaviour),
                field(l.binge, e.binge ? l.yes : l.no),
                if (e.measures.isNotEmpty) field(l.measures, e.measures),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: widget.onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(l.editEntry),
                  ),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

/// Hunger and satiety on one 0–100 % track instead of an "80 % → 100 %" arrow.
class _HungerSatietyBar extends StatelessWidget {
  const _HungerSatietyBar({required this.hunger, required this.satiety});

  final int? hunger;
  final int? satiety;

  static const _thumb = 12.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant);
    final h = hunger;
    final s = satiety;
    final hungerColor = scheme.tertiary;
    final satietyColor = scheme.primary;

    Widget legend(Color color, String text) => Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
          const SizedBox(width: 4),
          Text(text, style: labelStyle),
        ]);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(
        height: _thumb,
        child: LayoutBuilder(builder: (context, box) {
          double x(int v) => v / 100 * (box.maxWidth - _thumb);
          Widget thumb(int v, Color color) => Positioned(
                left: x(v),
                top: 0,
                child: Container(
                  width: _thumb,
                  height: _thumb,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: Border.all(color: scheme.surfaceContainerLow, width: 2),
                  ),
                ),
              );

          return Stack(children: [
            Positioned(
              left: _thumb / 2,
              right: _thumb / 2,
              top: _thumb / 2 - 2,
              child: Container(
                height: 4,
                decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            if (h != null && s != null)
              Positioned(
                left: x(min(h, s)) + _thumb / 2,
                width: (x(h) - x(s)).abs(),
                top: _thumb / 2 - 2,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: h <= s ? [hungerColor, satietyColor] : [satietyColor, hungerColor]),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            if (h != null) thumb(h, hungerColor),
            if (s != null) thumb(s, satietyColor),
          ]);
        }),
      ),
      const SizedBox(height: 6),
      Wrap(spacing: 12, children: [
        if (h != null) legend(hungerColor, '${l.hunger} $h %'),
        if (s != null) legend(satietyColor, '${l.satiety} $s %'),
      ]),
    ]);
  }
}
