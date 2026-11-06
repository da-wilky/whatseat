import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../data/models.dart';
import '../l10n/app_localizations.dart';

String mealLabel(AppLocalizations l, MealType meal) => switch (meal) {
      MealType.breakfast => l.mealBreakfast,
      MealType.lunch => l.mealLunch,
      MealType.dinner => l.mealDinner,
      MealType.snack => l.mealSnack,
      MealType.drink => l.drink,
      MealType.sport => l.sport,
    };

IconData mealIcon(MealType meal) => switch (meal) {
      MealType.breakfast => Icons.free_breakfast_outlined,
      MealType.lunch => Icons.lunch_dining_outlined,
      MealType.dinner => Icons.dinner_dining_outlined,
      MealType.snack => Icons.cookie_outlined,
      MealType.drink => Icons.local_drink_outlined,
      MealType.sport => Icons.directions_run_rounded,
    };

/// A sport entry only counts as sport while it holds nothing but sports.
bool isMeasureEntry(MealType meal, String measures) => meal == MealType.sport && measures.isNotEmpty;

String entryLabel(AppLocalizations l, MealEntry e) => isMeasureEntry(e.meal, e.measures) ? l.measure : mealLabel(l, e.meal);

const measureIcon = Icons.checklist_rounded;

IconData entryIcon(MealEntry e) => isMeasureEntry(e.meal, e.measures) ? measureIcon : mealIcon(e.meal);

/// (background, foreground) of a meal's marker.
(Color, Color) mealColors(ColorScheme s, MealType meal) => switch (meal) {
      MealType.breakfast => (s.tertiaryContainer, s.onTertiaryContainer),
      MealType.lunch => (s.primary, s.onPrimary),
      MealType.dinner => (s.secondary, s.onSecondary),
      MealType.snack => (s.secondaryContainer, s.onSecondaryContainer),
      MealType.drink => (s.tertiary, s.onTertiary),
      MealType.sport => (s.primaryContainer, s.onPrimaryContainer),
    };

/// The lists' starting values in the current language; custom units from before the lists go into both unit lists.
ListDefaults listDefaults(AppLocalizations l, List<String> customUnits) {
  List<(String, String)> units(String names) => [
        for (final name in [...names.split('|'), ...customUnits])
          if (name.isNotEmpty) (name, _builtInPlural(l, name) ?? ''),
      ];
  List<(String, String)> plain(String names) => [for (final name in names.split('|')) (name, '')];
  return {
    ListKind.foodUnit: units(l.foodUnits),
    ListKind.drinkUnit: units(l.drinkUnits),
    ListKind.measure: plain(l.measureDefaults),
    ListKind.withWhom: plain(l.withWhomDefaults),
  };
}

String? _builtInPlural(AppLocalizations l, String unit) =>
    l.unitDefs.split('|').map((p) => p.split('/')).where((p) => p.first == unit).firstOrNull?.last;

/// Items from before units carried their plural fall back to the built-in units.
String unitForm(AppLocalizations l, String unit, String plural, double? quantity) {
  if (quantity == null || quantity == 1) return unit;
  if (plural.isNotEmpty) return plural;
  return _builtInPlural(l, unit) ?? unit;
}

String formatAmount(AppLocalizations l, FoodItem item) {
  final q = item.quantity;
  final qText = q == null ? '' : NumberFormat('#.##', l.localeName).format(q);
  return [qText, unitForm(l, item.unit, item.unitPlural, q)].where((s) => s.isNotEmpty).join(' ');
}

String formatDuration(int minutes) => '${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')} h';

String sportsSummary(List<SportSession> sports) =>
    sports.map((s) => s.minutes == null ? s.sport : '${s.sport} ${formatDuration(s.minutes!)}').join(', ');

/// Sports are measures too; the export and the incident markers treat them alike.
String measuresText(MealEntry e) => [e.measures, sportsSummary(e.sports)].where((s) => s.isNotEmpty).join(', ');

String itemLabel(FoodItem item) =>
    item.parts.isEmpty ? item.food : '${item.food} (${item.parts.map((p) => p.food).join(', ')})';

String itemsSummary(AppLocalizations l, List<FoodItem> items) => items.map((i) {
      final amount = formatAmount(l, i);
      return amount.isEmpty ? itemLabel(i) : '$amount ${itemLabel(i)}';
    }).join(', ');

String timeRange(int start, int? end) => end == null ? formatMinutes(start) : '${formatMinutes(start)}–${formatMinutes(end)}';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Calendar days from [from] to [to]; via UTC because a local day across a DST switch is 23 or 25 hours.
int daysBetween(DateTime from, DateTime to) =>
    DateTime.utc(to.year, to.month, to.day).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

String relativeDayLabel(BuildContext context, DateTime day) {
  final l = AppLocalizations.of(context);
  final diff = daysBetween(day, DateTime.now());
  if (diff == 0) return l.today;
  if (diff == 1) return l.yesterday;
  return DateFormat.MMMEd(Localizations.localeOf(context).toString()).format(day);
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.children, this.icon});

  final String title;
  final IconData? icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              if (icon != null) ...[Icon(icon, size: 18, color: theme.colorScheme.primary), const SizedBox(width: 8)],
              Text(title, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
            ]),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}
