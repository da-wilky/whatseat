import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers.dart';
import 'common.dart';
import 'entry_editor.dart';

class TemplatesScreen extends ConsumerWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final db = ref.watch(databaseProvider);
    final templates = ref.watch(templatesProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text(l.templates)),
      body: templates.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(l.templatesEmpty, textAlign: TextAlign.center),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: templates.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final t = templates[i];
                return Card(
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    leading: IconButton(
                      tooltip: l.pin,
                      icon: Icon(t.pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined),
                      onPressed: () => db.updateTemplate(t.id, pinned: !t.pinned),
                    ),
                    title: Text(t.name),
                    subtitle: Text(
                      [if (t.meal != null) mealLabel(l, t.meal!), itemsSummary(l, t.items)].join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: PopupMenuButton<VoidCallback>(
                      onSelected: (action) => action(),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: () async {
                            final name = await showTextDialog(context, title: l.rename, initial: t.name);
                            if (name != null && name.isNotEmpty) await db.updateTemplate(t.id, name: name);
                          },
                          child: Text(l.rename),
                        ),
                        PopupMenuItem(
                          value: () {
                            db.updateTemplate(t.id, deleted: true);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(l.templateDeleted),
                              action: SnackBarAction(
                                label: l.undo,
                                onPressed: () => db.updateTemplate(t.id, deleted: false),
                              ),
                            ));
                          },
                          child: Text(l.delete),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
