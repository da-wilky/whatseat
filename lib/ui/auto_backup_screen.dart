import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/auto_backup.dart';
import '../data/backup_crypto.dart';
import '../data/backup_destinations.dart';
import '../l10n/app_localizations.dart';
import '../lock/app_lock.dart';
import '../providers.dart';
import 'backup_dialogs.dart';
import 'entry_editor.dart' show showTextDialog;

const _clipboardChannel = MethodChannel('whatseat/clipboard');

void _snack(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

typedef ChosenDestination = ({BackupDestination destination, String? code});

/// Asks for a destination and checks it can be reached. Null when cancelled or unreachable.
/// The own server logs in with the recovery code, so it comes first there and is returned with it:
/// generated when setting up, typed in when [restoring].
Future<ChosenDestination?> chooseBackupDestination(BuildContext context, {required bool restoring}) async {
  final l = AppLocalizations.of(context);
  final type = await showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(l.backupLocation),
      children: [
        ListTile(
          leading: const Icon(Icons.dns_outlined),
          title: Text(l.backupLocationServer),
          subtitle: Text(l.backupLocationServerHint),
          onTap: () => Navigator.pop(context, 'server'),
        ),
        ListTile(
          leading: const Icon(Icons.cloud_outlined),
          title: Text(l.backupLocationWebDav),
          subtitle: Text(l.backupLocationWebDavHint),
          onTap: () => Navigator.pop(context, 'webdav'),
        ),
        ListTile(
          leading: const Icon(Icons.folder_outlined),
          title: Text(l.backupLocationFolder),
          subtitle: Text(l.backupLocationFolderHint),
          onTap: () => Navigator.pop(context, 'folder'),
        ),
      ],
    ),
  );
  if (type == null || !context.mounted) return null;
  if (type == 'server') return _chooseServer(context, restoring: restoring);
  final BackupDestination? destination;
  try {
    destination = type == 'webdav'
        ? await showDialog<WebDavDestination>(context: context, builder: (_) => const _WebDavDialog())
        : await withoutRelock(FolderDestination.pick);
  } on BackupDestinationException catch (e) {
    if (context.mounted) _snack(context, l.backupLocationFailed('$e'));
    return null;
  }
  if (destination == null || !context.mounted) return null;
  try {
    await withBusyDialog(context, destination.connect);
  } on BackupDestinationException catch (e) {
    if (context.mounted) _snack(context, l.backupLocationFailed('$e'));
    return null;
  }
  return (destination: destination, code: null);
}

Future<ChosenDestination?> _chooseServer(BuildContext context, {required bool restoring}) async {
  final l = AppLocalizations.of(context);
  final input = await showTextDialog(context, title: l.backupLocationServer, initial: 'https://', label: l.serverUrl);
  if (input == null || !context.mounted) return null;
  var (:url, :invite) = parseServerAddress(input);
  try {
    httpsBaseUrl(url);
  } on FormatException {
    _snack(context, l.webDavUrlInvalid);
    return null;
  }
  final ServerInfo info;
  try {
    info = await withBusyDialog(context, () => ServerDestination.info(url));
  } on Object catch (e) {
    if (context.mounted) _snack(context, l.backupLocationFailed('$e'));
    return null;
  }
  if (!context.mounted) return null;

  final String? code;
  if (restoring) {
    code = await askRecoveryCode(context);
  } else {
    if (info.inviteOnly) {
      Future<String?> check(String candidate) async {
        if (candidate.isEmpty) return l.serverInviteInvalid;
        try {
          return await ServerDestination.checkInvite(url, candidate) ? null : l.serverInviteInvalid;
        } on BackupDestinationException catch (e) {
          return l.backupLocationFailed('$e');
        }
      }

      final fromLink = invite;
      final linkError = fromLink == null ? null : await withBusyDialog(context, () => check(fromLink));
      if (!context.mounted) return null;
      if (fromLink == null || linkError != null) {
        invite = await showTextDialog(context,
            title: l.serverInvite,
            label: l.serverInviteLabel,
            initial: fromLink ?? '',
            error: linkError,
            validate: check);
        if (invite == null || !context.mounted) return null;
      }
    }
    if (info.inactiveDays > 0) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l.serverInactivityTitle),
          content: Text(l.serverInactivityWarning(info.inactiveDays)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.understood)),
          ],
        ),
      );
      if (accepted != true || !context.mounted) return null;
    }
    final generated = generateRecoveryCode();
    final confirmed = await showDialog<bool>(
        context: context, builder: (_) => _RecoveryCodeDialog(code: formatRecoveryCode(generated)));
    code = confirmed == true ? generated : null;
  }
  if (code == null || !context.mounted) return null;
  final secret = code;
  final usedInvite = invite;
  try {
    final destination = await withBusyDialog(context, () async {
      final login = await serverCredentials(secret);
      final destination = ServerDestination(url: url, account: login.account, token: login.token);
      await (restoring ? destination.connect() : destination.register(invite: usedInvite));
      return destination;
    });
    return (destination: destination, code: secret);
  } on BackupDestinationException catch (e) {
    if (context.mounted) _snack(context, l.backupLocationFailed('$e'));
    return null;
  }
}

typedef RemoteRestore = ({Map<String, dynamic> backup, BackupDestination destination, BackupKey key});

/// Lets the user pick and unlock a backup at a destination. Null when cancelled or failed.
Future<RemoteRestore?> restoreFromBackupLocation(BuildContext context, {BackupDestination? destination}) async {
  final l = AppLocalizations.of(context);
  String? code;
  if (destination == null) {
    final chosen = await chooseBackupDestination(context, restoring: true);
    if (chosen == null) return null;
    (:destination, :code) = chosen;
  }
  if (!context.mounted) return null;
  final location = destination;
  try {
    final names = await withBusyDialog(context, () => listBackups(location));
    if (!context.mounted) return null;
    if (names.isEmpty) {
      _snack(context, l.backupNoneFound);
      return null;
    }
    final format = DateFormat.yMMMMEEEEd(l.localeName);
    // Several setups at one location are told apart by their series.
    final mixed = names.map(backupSeries).toSet().length > 1;
    String label(String name) =>
        mixed ? '${format.format(backupDay(name))} · ${backupSeries(name) ?? '–'}' : format.format(backupDay(name));
    final name = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l.backupChoose),
        children: [
          for (final name in names)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, name),
              child: Text(label(name)),
            ),
        ],
      ),
    );
    if (name == null || !context.mounted) return null;
    final json = await withBusyDialog(context, () => readBackupFile(location, name));
    if (!context.mounted) return null;
    final opened = await openBackupWithKey(context, json, fileName: name, secret: code);
    if (opened == null) return null;
    return (backup: opened.backup, destination: location, key: opened.key);
  } on Object catch (e) {
    if (context.mounted) _snack(context, l.backupInvalid('$e'));
    return null;
  }
}

class AutoBackupScreen extends ConsumerWidget {
  const AutoBackupScreen({super.key});

  Future<void> _setUp(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final chosen = await chooseBackupDestination(context, restoring: false);
    if (chosen == null || !context.mounted) return;
    final destination = chosen.destination;
    // The server account belongs to a freshly generated code, so it holds no backups yet.
    final serverCode = chosen.code;
    if (serverCode != null) return _enable(context, ref, destination, serverCode, recoveryCode: true);

    // A new, empty device would otherwise replace today's backup from the old one.
    final List<String> existing;
    try {
      existing = await withBusyDialog(context, () => listBackups(destination));
    } on BackupDestinationException catch (e) {
      if (context.mounted) _snack(context, l.backupLocationFailed('$e'));
      return;
    }
    if (existing.isNotEmpty && context.mounted) {
      final restore = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l.backupLocationHasBackups),
          content: Text(l.backupLocationHasBackupsHint),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.backupContinueSetup)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.backupRestore)),
          ],
        ),
      );
      if (restore == null || !context.mounted) return;
      if (restore) return _restore(context, ref, destination: destination);
    }
    if (!context.mounted) return;

    final useCode = await showDialog<bool>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l.backupSecretTitle),
        children: [
          ListTile(
            leading: const Icon(Icons.key_rounded),
            title: Text(l.backupSecretCode),
            subtitle: Text(l.backupSecretCodeHint),
            onTap: () => Navigator.pop(context, true),
          ),
          ListTile(
            leading: const Icon(Icons.password_rounded),
            title: Text(l.backupSecretPassword),
            subtitle: Text(l.backupSecretPasswordHint),
            onTap: () => Navigator.pop(context, false),
          ),
        ],
      ),
    );
    if (useCode == null || !context.mounted) return;
    final String? secret;
    if (useCode) {
      final code = generateRecoveryCode();
      final confirmed =
          await showDialog<bool>(context: context, builder: (_) => _RecoveryCodeDialog(code: formatRecoveryCode(code)));
      secret = confirmed == true ? code : null;
    } else {
      secret = await askAutoBackupPassword(context);
    }
    if (secret == null || !context.mounted) return;
    await _enable(context, ref, destination, secret, recoveryCode: useCode);
  }

  Future<void> _enable(BuildContext context, WidgetRef ref, BackupDestination destination, String secret,
      {required bool recoveryCode}) async {
    final key = await withBusyDialog(context, () => deriveBackupKey(secret, recoveryCode: recoveryCode));
    await ref.read(autoBackupProvider.notifier).enable(AutoBackupConfig(destination: destination, key: key));
    if (context.mounted) _reportResult(context, ref);
  }

  void _reportResult(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final error = ref.read(autoBackupProvider).value?.lastError;
    _snack(context, error == null ? l.backupDone : l.backupFailed(error));
  }

  Future<void> _restore(BuildContext context, WidgetRef ref, {BackupDestination? destination}) async {
    final l = AppLocalizations.of(context);
    final restored = await restoreFromBackupLocation(context, destination: destination);
    if (restored == null || !context.mounted) return;
    final int count;
    try {
      count = await ref.read(databaseProvider).importBackup(restored.backup);
    } on Object catch (e) {
      if (context.mounted) _snack(context, l.backupInvalid('$e'));
      return;
    }
    // Restoring with the code proves it is known, so backups can carry on at the same place.
    final notifier = ref.read(autoBackupProvider.notifier);
    if (ref.read(autoBackupProvider).value?.config == null) {
      await notifier.enable(AutoBackupConfig(destination: restored.destination, key: restored.key));
    }
    if (context.mounted) _snack(context, l.backupImported(count));
  }

  Future<void> _setKeepAlive(BuildContext context, WidgetRef ref, bool enabled, int? inactiveDays) async {
    final l = AppLocalizations.of(context);
    if (!enabled) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l.keepAliveOffTitle),
          content: Text((inactiveDays ?? 0) > 0 ? l.keepAliveOffWarning(inactiveDays!) : l.keepAliveOffHint),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.keepAliveOffConfirm)),
          ],
        ),
      );
      if (ok != true) return;
    }
    await ref.read(autoBackupProvider.notifier).setKeepAlive(enabled);
  }

  Future<void> _disable(BuildContext context, WidgetRef ref, BackupDestination destination) async {
    final l = AppLocalizations.of(context);
    var deleteBackups = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          scrollable: true,
          title: Text(l.autoBackupDisable),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.autoBackupDisableHint),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: deleteBackups,
                onChanged: (v) => setState(() => deleteBackups = v!),
                title: Text(destination is ServerDestination ? l.autoBackupDeleteAccount : l.autoBackupDeleteFiles),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.autoBackupDisable)),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await withBusyDialog(context, () => ref.read(autoBackupProvider.notifier).disable(deleteBackups: deleteBackups));
    } on BackupDestinationException catch (e) {
      if (context.mounted) _snack(context, l.autoBackupDeleteFailed('$e'));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final status = ref.watch(autoBackupProvider).value;
    final config = status?.config;
    final format = DateFormat.yMMMd(l.localeName).add_Hm();

    return Scaffold(
      appBar: AppBar(title: Text(l.autoBackup)),
      body: status == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(l.autoBackupIntro, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 16),
                if (config == null)
                  FilledButton.icon(
                    onPressed: () => _setUp(context, ref),
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: Text(l.autoBackupSetUp),
                  )
                else ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(switch (config.destination) {
                      ServerDestination() => Icons.dns_outlined,
                      WebDavDestination() => Icons.cloud_outlined,
                      FolderDestination() => Icons.folder_outlined,
                    }),
                    title: Text(config.destination.label),
                    subtitle: Text(config.key.recoveryCode ? l.backupSecretCode : l.backupSecretPassword),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: status.running
                        ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(status.lastError == null ? Icons.check_circle_outline : Icons.error_outline,
                            color: status.lastError == null ? null : theme.colorScheme.error),
                    title: Text(status.lastSuccess == null
                        ? l.autoBackupNever
                        : l.autoBackupLast(format.format(status.lastSuccess!))),
                    subtitle: status.lastError == null
                        ? null
                        : Text(l.backupFailed(status.lastError!), style: TextStyle(color: theme.colorScheme.error)),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: status.running
                        ? null
                        : () async {
                            await ref.read(autoBackupProvider.notifier).backupNow();
                            if (context.mounted) _reportResult(context, ref);
                          },
                    icon: const Icon(Icons.backup_outlined),
                    label: Text(l.autoBackupNow),
                  ),
                  if (config.destination is ServerDestination) ...[
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l.keepAlive),
                      subtitle: Text(l.keepAliveHint),
                      value: status.keepAlive,
                      onChanged: (enabled) => _setKeepAlive(context, ref, enabled, status.inactiveDays),
                    ),
                    if ((status.inactiveDays ?? 0) > 0)
                      Text(l.serverInactivityNote(status.inactiveDays!),
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                  ],
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _restore(context, ref, destination: config?.destination),
                  icon: const Icon(Icons.settings_backup_restore_rounded),
                  label: Text(l.backupRestoreFromLocation),
                ),
                if (config != null) ...[
                  const SizedBox(height: 12),
                  TextButton(onPressed: () => _disable(context, ref, config.destination), child: Text(l.autoBackupDisable)),
                ],
              ],
            ),
    );
  }
}

/// The code is shown once; continuing requires copying or saving it, then confirming it was kept.
class _RecoveryCodeDialog extends StatefulWidget {
  const _RecoveryCodeDialog({required this.code});

  final String code;

  @override
  State<_RecoveryCodeDialog> createState() => _RecoveryCodeDialogState();
}

class _RecoveryCodeDialogState extends State<_RecoveryCodeDialog> {
  bool _copied = false;
  bool _exported = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    setSecretShown(true);
  }

  @override
  void dispose() {
    setSecretShown(false);
    super.dispose();
  }

  Future<void> _copy() async {
    // Marked sensitive, so keyboards keep it out of their clipboard history and Android hides the preview.
    if (Platform.isAndroid || Platform.isIOS) {
      await _clipboardChannel.invokeMethod('copySensitive', widget.code);
    } else {
      await Clipboard.setData(ClipboardData(text: widget.code));
    }
    if (mounted) {
      setState(() {
        _copied = true;
        _exported = true;
      });
    }
  }

  Future<void> _download() async {
    final Uri? uri;
    try {
      uri = await withoutRelock(() => FilePicker.saveFile(
            fileName: 'whatseat-recovery-code.txt',
            bytes: utf8.encode('${widget.code}\n'),
            mimeType: 'text/plain',
          ));
    } on Exception catch (e) {
      if (mounted) _snack(context, AppLocalizations.of(context).recoveryCodeSaveFailed('$e'));
      return;
    }
    if (uri != null && mounted) setState(() => _exported = true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AlertDialog(
      scrollable: true,
      title: Text(l.recoveryCode),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.recoveryCodeHint),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              widget.code,
              // Copying the selection goes through the sensitive copy; sharing it to other apps is left out.
              contextMenuBuilder: (context, state) => AdaptiveTextSelectionToolbar.buttonItems(
                anchors: state.contextMenuAnchors,
                buttonItems: [
                  for (final item in state.contextMenuButtonItems)
                    if (item.type == ContextMenuButtonType.copy)
                      item.copyWith(onPressed: () {
                        state.hideToolbar();
                        _copy();
                      })
                    else if (item.type == ContextMenuButtonType.selectAll)
                      item,
                ],
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(fontFamily: 'monospace', letterSpacing: 1.5),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: _copy,
                icon: Icon(_copied ? Icons.check : Icons.copy),
                label: Text(_copied ? l.recoveryCodeCopied : l.recoveryCodeCopy),
              ),
              TextButton.icon(
                  onPressed: _download, icon: const Icon(Icons.download), label: Text(l.recoveryCodeDownload)),
            ],
          ),
          if (_copied)
            Text(l.recoveryCodeClipboardCleared, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _saved,
            onChanged: _exported ? (v) => setState(() => _saved = v!) : null,
            title: Text(l.recoveryCodeSaved),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
        FilledButton(onPressed: _saved ? () => Navigator.pop(context, true) : null, child: Text(l.ok)),
      ],
    );
  }
}

/// Owns its controllers so they are disposed only after the closing animation.
class _WebDavDialog extends StatefulWidget {
  const _WebDavDialog();

  @override
  State<_WebDavDialog> createState() => _WebDavDialogState();
}

class _WebDavDialogState extends State<_WebDavDialog> {
  final _url = TextEditingController(text: 'https://');
  final _user = TextEditingController();
  final _password = TextEditingController();
  String? _urlError;

  @override
  void dispose() {
    _url.dispose();
    _user.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    final l = AppLocalizations.of(context);
    try {
      Navigator.pop(
          context, WebDavDestination(url: _url.text.trim(), user: _user.text.trim(), password: _password.text));
    } on FormatException {
      setState(() => _urlError = l.webDavUrlInvalid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      scrollable: true,
      title: Text(l.backupLocationWebDav),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.webDavHint),
          const SizedBox(height: 16),
          TextField(
            controller: _url,
            autofocus: true,
            keyboardType: TextInputType.url,
            autocorrect: false,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() => _urlError = null),
            decoration: InputDecoration(labelText: l.webDavUrl, errorText: _urlError, errorMaxLines: 3),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _user,
            autocorrect: false,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: l.webDavUser),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(labelText: l.webDavPassword),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(onPressed: _submit, child: Text(l.ok)),
      ],
    );
  }
}
