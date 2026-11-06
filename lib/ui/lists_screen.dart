import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/models.dart';
import '../l10n/app_localizations.dart';
import '../providers.dart';
import 'entry_editor.dart';

final _usageProvider = FutureProvider.autoDispose
    .family<Map<String, int>, ListKind>((ref, kind) => ref.watch(databaseProvider).listUsage(kind));

bool _isUnit(ListKind kind) => kind == ListKind.foodUnit || kind == ListKind.drinkUnit;

/// Name and plural (empty for anything but units); null when cancelled.
Future<(String, String)?> _askValue(BuildContext context, ListKind kind, List<ListValue> values,
    {ListValue? current}) async {
  final l = AppLocalizations.of(context);
  final taken = {
    for (final v in values)
      if (v.id != current?.id) v.name.toLowerCase(),
  };
  final title = current == null ? l.listAdd : l.rename;
  if (_isUnit(kind)) {
    return showUnitDialog(context, title: title, name: current?.name ?? '', plural: current?.plural ?? '', taken: taken);
  }
  final name = await showTextDialog(
    context,
    title: title,
    initial: current?.name ?? '',
    validate: (v) async => taken.contains(cleanTag(v).toLowerCase()) ? l.listValueExists : null,
  );
  final clean = cleanTag(name ?? '');
  return clean.isEmpty ? null : (clean, '');
}

class ListsScreen extends ConsumerWidget {
  const ListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final tabs = {
      ListKind.foodUnit: l.listFoodUnits,
      ListKind.drinkUnit: l.listDrinkUnits,
      ListKind.measure: l.listMeasures,
      ListKind.withWhom: l.withWhom,
      ListKind.sport: l.listSports,
    };

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.lists),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [for (final title in tabs.values) Tab(text: title)],
          ),
        ),
        body: TabBarView(children: [for (final kind in tabs.keys) _ListTab(kind: kind)]),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton.extended(
            onPressed: () async {
              final kind = tabs.keys.elementAt(DefaultTabController.of(context).index);
              final value = await _askValue(context, kind, ref.read(listsProvider).value?[kind] ?? const []);
              if (value != null) await ref.read(databaseProvider).addListValue(kind, value.$1, plural: value.$2);
            },
            icon: const Icon(Icons.add_rounded),
            label: Text(l.listAdd),
          ),
        ),
      ),
    );
  }
}

class _ListTab extends ConsumerWidget {
  const _ListTab({required this.kind});

  final ListKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final db = ref.watch(databaseProvider);
    final values = ref.watch(listsProvider).value?[kind] ?? const [];
    final usage = ref.watch(_usageProvider(kind)).value ?? const {};

    if (values.isEmpty) {
      return Center(
        child: Padding(padding: const EdgeInsets.all(32), child: Text(l.listEmpty, textAlign: TextAlign.center)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: values.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final v = values[i];
        return Card(
          child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(v.plural.isEmpty ? v.name : '${v.name} / ${v.plural}'),
            subtitle: Text(l.listUsage(usage[v.name.toLowerCase()] ?? 0)),
            onTap: () async {
              final value = await _askValue(context, kind, values, current: v);
              if (value != null) await db.updateListValue(v.id, name: value.$1, plural: value.$2);
            },
            trailing: IconButton(
              tooltip: l.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                db.updateListValue(v.id, deleted: true);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(l.listValueDeleted(v.name)),
                  action: SnackBarAction(label: l.undo, onPressed: () => db.updateListValue(v.id, deleted: false)),
                ));
              },
            ),
          ),
        );
      },
    );
  }
}
