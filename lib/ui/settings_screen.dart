import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/models.dart';
import '../l10n/app_localizations.dart';
import '../lock/app_lock.dart';
import '../providers.dart';
import 'entry_editor.dart';
import 'export_screen.dart';
import 'templates_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _biometricsAvailable = false;

  @override
  void initState() {
    super.initState();
    biometricsAvailable().then((v) {
      if (mounted) setState(() => _biometricsAvailable = v);
    });
  }

  SettingsNotifier get _settings => ref.read(settingsProvider.notifier);

  void _snack(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<T?> _choose<T>(String title, Map<T, String> options, T current) => showDialog<T>(
        context: context,
        builder: (context) => SimpleDialog(
          title: Text(title),
          children: [
            RadioGroup<T>(
              groupValue: current,
              onChanged: (v) => Navigator.pop(context, v),
              child: Column(children: [
                for (final MapEntry(:key, :value) in options.entries) RadioListTile<T>(value: key, title: Text(value)),
              ]),
            ),
          ],
        ),
      );

  Future<void> _toggleLock(bool enable) async {
    if (!enable) {
      if (!await confirmPin(context)) return;
      await _settings.disableLock();
      await clearPin();
      return;
    }
    final length = await Navigator.push<int>(context, MaterialPageRoute(builder: (_) => const PinSetupScreen()));
    if (length != null) await _settings.enableLock(length);
  }

  Future<void> _toggleBiometric(bool enable) async {
    final l = AppLocalizations.of(context);
    if (enable && !await authenticateBiometric(l.biometricConfirm)) return;
    await _settings.setBiometric(enable);
  }

  Future<void> _exportBackup() async {
    final l = AppLocalizations.of(context);
    final json = await ref.read(databaseProvider).exportBackup();
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, 'whatseat-backup-${dayKey(DateTime.now())}.json'));
    await file.writeAsString(jsonEncode(json));
    await withoutRelock(() => SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: l.backupCreate)));
  }

  Future<void> _importBackup() async {
    final l = AppLocalizations.of(context);
    final picked = await withoutRelock(
        () => FilePicker.pickFile(type: FileType.custom, allowedExtensions: const ['json']));
    if (picked == null) return;
    try {
      final json = jsonDecode(utf8.decode(await picked.readAsBytes())) as Map<String, dynamic>;
      final count = await ref.read(databaseProvider).importBackup(json);
      _snack(l.backupImported(count));
    } on Object catch (e) {
      _snack(l.backupInvalid('$e'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    void push(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

    Widget header(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
          child: Text(text, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
        );

    final languages = {'': l.languageSystem, 'de': 'Deutsch', 'en': 'English'};
    final timeouts = {0: l.lockImmediately, 60: l.lockAfterMinutes(1), 300: l.lockAfterMinutes(5)};

    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        children: [
          header(l.general),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: Text(l.patientName),
            subtitle: Text(settings.patientName.isEmpty ? l.patientNameHint : settings.patientName),
            onTap: () async {
              final name = await showTextDialog(context, title: l.patientName, initial: settings.patientName);
              if (name != null) await _settings.setPatientName(name);
            },
          ),
          ListTile(
            leading: const Icon(Icons.translate_rounded),
            title: Text(l.language),
            subtitle: Text(languages[settings.localeCode] ?? l.languageSystem),
            onTap: () async {
              final code = await _choose(l.language, languages, settings.localeCode);
              if (code != null) await _settings.setLocale(code);
            },
          ),
          header(l.security),
          SwitchListTile(
            secondary: const Icon(Icons.lock_outline_rounded),
            title: Text(l.appLock),
            subtitle: Text(l.appLockHint),
            value: settings.lockEnabled,
            onChanged: _toggleLock,
          ),
          if (settings.lockEnabled) ...[
            if (_biometricsAvailable)
              SwitchListTile(
                secondary: const Icon(Icons.fingerprint_rounded),
                title: Text(l.biometric),
                value: settings.biometricEnabled,
                onChanged: _toggleBiometric,
              ),
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: Text(l.lockTimeout),
              subtitle: Text(timeouts[settings.lockTimeoutSeconds] ?? ''),
              onTap: () async {
                final seconds = await _choose(l.lockTimeout, timeouts, settings.lockTimeoutSeconds);
                if (seconds != null) await _settings.setLockTimeout(seconds);
              },
            ),
            ListTile(
              leading: const Icon(Icons.pin_outlined),
              title: Text(l.pinChange),
              onTap: () async {
                if (!await confirmPin(context) || !context.mounted) return;
                final length =
                    await Navigator.push<int>(context, MaterialPageRoute(builder: (_) => const PinSetupScreen()));
                if (length != null) await _settings.enableLock(length);
              },
            ),
          ],
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: Text(l.encryptionInfo),
            dense: true,
          ),
          header(l.data),
          ListTile(
            leading: const Icon(Icons.ios_share_rounded),
            title: Text(l.export),
            onTap: () => push(ExportScreen(initialDay: DateTime.now())),
          ),
          ListTile(
            leading: const Icon(Icons.bookmarks_outlined),
            title: Text(l.templates),
            onTap: () => push(const TemplatesScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: Text(l.backupCreate),
            subtitle: Text(l.backupWarning),
            onTap: _exportBackup,
          ),
          ListTile(
            leading: const Icon(Icons.settings_backup_restore_rounded),
            title: Text(l.backupRestore),
            subtitle: Text(l.backupRestoreHint),
            onTap: _importBackup,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
