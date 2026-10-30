import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models.dart';
import '../l10n/app_localizations.dart';

String mealLabel(AppLocalizations l, MealType meal) => switch (meal) {
      MealType.breakfast => l.mealBreakfast,
      MealType.lunch => l.mealLunch,
      MealType.dinner => l.mealDinner,
      MealType.snack => l.mealSnack,
      MealType.drink => l.drink,
    };

IconData mealIcon(MealType meal) => switch (meal) {
      MealType.breakfast => Icons.free_breakfast_outlined,
      MealType.lunch => Icons.lunch_dining_outlined,
      MealType.dinner => Icons.dinner_dining_outlined,
      MealType.snack => Icons.cookie_outlined,
      MealType.drink => Icons.local_drink_outlined,
    };

/// (background, foreground) of a meal's marker.
(Color, Color) mealColors(ColorScheme s, MealType meal) => switch (meal) {
      MealType.breakfast => (s.tertiaryContainer, s.onTertiaryContainer),
      MealType.lunch => (s.primary, s.onPrimary),
      MealType.dinner => (s.secondary, s.onSecondary),
      MealType.snack => (s.secondaryContainer, s.onSecondaryContainer),
      MealType.drink => (s.tertiary, s.onTertiary),
    };

List<String> foodUnits(AppLocalizations l) => l.foodUnits.split('|');

List<String> drinkUnits(AppLocalizations l) => l.drinkUnits.split('|');

String formatAmount(AppLocalizations l, FoodItem item) {
  final q = item.quantity;
  final qText = q == null ? '' : NumberFormat('#.##', l.localeName).format(q);
  var unit = item.unit;
  if (q != null && q != 1) {
    for (final pair in l.unitDefs.split('|').map((p) => p.split('/'))) {
      if (pair.first == unit) unit = pair.last;
    }
  }
  return [qText, unit].where((s) => s.isNotEmpty).join(' ');
}

String itemsSummary(AppLocalizations l, List<FoodItem> items) => items.map((i) {
      final amount = formatAmount(l, i);
      return amount.isEmpty ? i.food : '$amount ${i.food}';
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
