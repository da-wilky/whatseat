import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'l10n/app_localizations.dart';

/// Shown instead of the app when the encrypted database can't be opened, e.g. because its key is gone.
class RecoveryApp extends StatelessWidget {
  const RecoveryApp({
    super.key,
    required this.localeCode,
    required this.error,
    required this.onRetry,
    required this.onReset,
  });

  final String localeCode;
  final Object error;
  final VoidCallback onRetry;

  /// Deletes the database; with a backup, it is imported into the new one.
  final Future<void> Function(Map<String, dynamic>? backup) onReset;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      locale: localeCode.isEmpty ? null : Locale(localeCode),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: _RecoveryScreen(error: error, onRetry: onRetry, onReset: onReset),
    );
  }
}

class _RecoveryScreen extends StatefulWidget {
  const _RecoveryScreen({required this.error, required this.onRetry, required this.onReset});

  final Object error;
  final VoidCallback onRetry;
  final Future<void> Function(Map<String, dynamic>? backup) onReset;

  @override
  State<_RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<_RecoveryScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // The backup is read and checked before anything is deleted, so a wrong file costs nothing.
  Future<void> _restore() async {
    final l = AppLocalizations.of(context);
    final picked = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: const ['json']);
    if (picked == null) return;
    final Map<String, dynamic> backup;
    try {
      backup = jsonDecode(utf8.decode(await picked.readAsBytes())) as Map<String, dynamic>;
      if (backup['format'] != 'whatseat-backup') throw const FormatException('Not a WhatsEat backup');
    } on Object catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.backupInvalid('$e'))));
      return;
    }
    await _run(() => widget.onReset(backup));
  }

  Future<void> _startFresh() async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.recoveryStartFresh),
        content: Text(l.recoveryStartFreshConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.recoveryStartFresh)),
        ],
      ),
    );
    if (ok == true) await _run(() => widget.onReset(null));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 32),
            Icon(Icons.lock_reset_rounded, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(l.recoveryTitle, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(l.recoveryBody, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 12),
            Text('${widget.error}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
            const SizedBox(height: 32),
            if (_busy)
              const Center(child: CircularProgressIndicator())
            else ...[
              OutlinedButton.icon(
                onPressed: () => _run(() async => widget.onRetry()),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l.recoveryRetry),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _restore,
                icon: const Icon(Icons.settings_backup_restore_rounded),
                label: Text(l.backupRestore),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: _startFresh, child: Text(l.recoveryStartFresh)),
            ],
          ],
        ),
      ),
    );
  }
}
