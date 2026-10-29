import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/models.dart';
import '../l10n/app_localizations.dart';
import '../providers.dart';
import 'common.dart';
import 'entry_editor.dart';

Future<void> showQuickAddSheet(BuildContext context, DateTime day) async {
  final draft = await showModalBottomSheet<EntryDraft>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => _QuickAddSheet(day: day),
  );
  if (draft != null && context.mounted) await openEntryEditor(context, draft);
}

final _recentMealsProvider =
    FutureProvider.autoDispose<List<MealEntry>>((ref) => ref.watch(databaseProvider).recentMeals());

class _QuickAddSheet extends ConsumerWidget {
  const _QuickAddSheet({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final templates = ref.watch(templatesProvider).value ?? const [];
    final recent = ref.watch(_recentMealsProvider).value ?? const [];

    Widget header(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
          child: Text(text, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
        );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            onPressed: () => Navigator.pop(context, EntryDraft.fresh(day)),
            icon: const Icon(Icons.edit_note_rounded),
            label: Text(l.newEntry),
          ),
          if (templates.isNotEmpty) ...[
            header(l.templates),
            for (final t in templates)
              _ReuseTile(
                icon: t.pinned ? Icons.push_pin_rounded : Icons.bookmark_outline_rounded,
                title: t.name,
                subtitle: itemsSummary(l, t.items),
                onTap: () => Navigator.pop(context, EntryDraft.fromTemplate(t, day)),
              ),
          ],
          if (recent.isNotEmpty) ...[
            header(l.eatAgain),
            for (final e in recent)
              _ReuseTile(
                icon: mealIcon(e.meal),
                title: itemsSummary(l, e.items),
                subtitle: '${mealLabel(l, e.meal)} · ${relativeDayLabel(context, parseDayKey(e.day))}',
                onTap: () => Navigator.pop(context, EntryDraft.repeat(e, day)),
              ),
          ],
          if (templates.isEmpty && recent.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text(l.reuseHint, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            ),
        ],
      ),
    );
  }
}

class _ReuseTile extends StatelessWidget {
  const _ReuseTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Card(
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          leading: Icon(icon),
          title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: const Icon(Icons.north_west_rounded, size: 18),
          onTap: onTap,
        ),
      ),
    );
  }
}
