import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/auto_backup.dart';
import '../data/backup_crypto.dart';
import '../data/models.dart';
import '../l10n/app_localizations.dart';

const _minPasswordLength = 8;

enum _Mode { export, autoBackup, unlock }

/// Null when cancelled.
Future<String?> askExportPassword(BuildContext context) => showDialog<String>(
      context: context,
      builder: (_) => const _PasswordDialog(mode: _Mode.export),
    );

/// Null when cancelled.
Future<String?> askAutoBackupPassword(BuildContext context) => showDialog<String>(
      context: context,
      builder: (_) => const _PasswordDialog(mode: _Mode.autoBackup),
    );

/// Asks for the password until it fits, then has the user confirm when the backup was made. Null when cancelled.
Future<Map<String, dynamic>?> openBackup(BuildContext context, Map<String, dynamic> json, {required String fileName}) async =>
    (await openBackupWithKey(context, json, fileName: fileName))?.backup;

/// Null when cancelled.
Future<String?> askRecoveryCode(BuildContext context) => showDialog<String>(
      context: context,
      builder: (_) => const _PasswordDialog(mode: _Mode.unlock, recoveryCode: true),
    );

/// Like [openBackup], also returning the key.
/// A known [secret], such as the code just used to log in, is tried before asking.
/// Unencrypted files are refused: whoever stored or sent them could have made up their content.
Future<({Map<String, dynamic> backup, BackupKey key})?> openBackupWithKey(BuildContext context, Map<String, dynamic> json,
    {required String fileName, String? secret}) async {
  if (!isEncryptedBackup(json)) throw const FormatException('Not an encrypted WhatsEat backup');
  final recoveryCode = usesRecoveryCode(json);
  var wrong = false;
  var known = secret;
  while (true) {
    if (!context.mounted) return null;
    final password = known ??
        await showDialog<String>(
          context: context,
          builder: (_) => _PasswordDialog(mode: _Mode.unlock, recoveryCode: recoveryCode, wrong: wrong),
        );
    known = null;
    if (password == null || !context.mounted) return null;
    final ({Map<String, dynamic> backup, BackupKey key}) opened;
    try {
      opened = await withBusyDialog(context, () async {
        final key = await backupKeyFor(json, password);
        return (backup: await decryptBackupWithKey(json, key), key: key);
      });
    } on WrongBackupPasswordException {
      wrong = true;
      continue;
    }
    if (opened.backup['format'] != backupFormat) throw const FormatException('Not a WhatsEat backup');
    final created = backupCreated(opened.backup);
    if (!context.mounted || !await _confirmBackupTime(context, created, fileName)) return null;
    return opened;
  }
}

/// The time inside the encrypted backup is the one to trust; the file name can be changed by whoever stores it.
Future<bool> _confirmBackupTime(BuildContext context, DateTime created, String fileName) async {
  final l = AppLocalizations.of(context);
  final scheme = Theme.of(context).colorScheme;
  final local = created.toLocal();
  final named = isBackupName(fileName) ? backupDay(fileName) : null;
  final mismatch = named != null && dayKey(named) != dayKey(local);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      scrollable: true,
      icon: mismatch ? Icon(Icons.warning_amber_rounded, color: scheme.error) : null,
      title: Text(l.backupRestoreConfirm),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.backupCreatedAt(DateFormat.yMMMMEEEEd(l.localeName).add_Hm().format(local))),
          if (mismatch) ...[
            const SizedBox(height: 12),
            Text(l.backupDateMismatch(DateFormat.yMMMMEEEEd(l.localeName).format(named)),
                style: TextStyle(color: scheme.error)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.backupRestore)),
      ],
    ),
  );
  return ok ?? false;
}

/// Blocks input while [task] runs, e.g. the second or two of key derivation.
Future<T> withBusyDialog<T>(BuildContext context, Future<T> Function() task) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(canPop: false, child: Center(child: CircularProgressIndicator())),
  );
  try {
    return await task();
  } finally {
    navigator.pop();
  }
}

/// Owns its controllers so they are disposed only after the closing animation.
class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({required this.mode, this.recoveryCode = false, this.wrong = false});

  final _Mode mode;
  final bool recoveryCode;
  final bool wrong;

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _password = TextEditingController();
  final _repeat = TextEditingController();
  bool _obscure = true;
  String? _passwordError;
  String? _repeatError;

  @override
  void dispose() {
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  void _clearErrors(String _) {
    if (_passwordError != null || _repeatError != null) {
      setState(() => _passwordError = _repeatError = null);
    }
  }

  bool get _choosing => widget.mode != _Mode.unlock;

  void _submit() {
    final l = AppLocalizations.of(context);
    final password = _password.text;
    if (_choosing) {
      setState(() {
        _passwordError = switch (widget.mode) {
          _Mode.export when password.length < _minPasswordLength => l.passwordTooShort(_minPasswordLength),
          _Mode.autoBackup when !isStrongBackupPassword(password) => l.passwordTooWeak,
          _ => null,
        };
        _repeatError = _passwordError == null && _repeat.text != password ? l.passwordMismatch : null;
      });
      if (_passwordError != null || _repeatError != null) return;
    } else if (password.isEmpty) {
      return;
    }
    Navigator.pop(context, password);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    InputDecoration decoration(String label, String? error) => InputDecoration(labelText: label, errorText: error);

    // Scrollable as a whole: with the keyboard up, the fields and their errors must stay reachable.
    final (title, hint) = switch (widget.mode) {
      _Mode.export => (l.backupEncryptTitle, l.backupEncryptHint),
      _Mode.autoBackup => (l.autoBackupPasswordTitle, l.autoBackupPasswordHint(minAutoBackupPasswordLength)),
      _Mode.unlock when widget.recoveryCode => (l.recoveryCode, l.backupCodeLockedHint),
      _Mode.unlock => (l.backupLockedTitle, l.backupLockedHint),
    };
    final wrong = widget.recoveryCode ? l.backupWrongCode : l.backupWrongPassword;
    return AlertDialog(
      scrollable: true,
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(hint),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            autofocus: true,
            obscureText: _obscure && !widget.recoveryCode,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: widget.recoveryCode ? TextCapitalization.characters : TextCapitalization.none,
            textInputAction: _choosing ? TextInputAction.next : TextInputAction.done,
            onSubmitted: _choosing ? null : (_) => _submit(),
            onChanged: _clearErrors,
            decoration: decoration(widget.recoveryCode ? l.recoveryCode : l.password,
                    widget.wrong ? wrong : _passwordError)
                .copyWith(
              suffixIcon: widget.recoveryCode
                  ? null
                  : IconButton(
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
            ),
          ),
          if (_choosing) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _repeat,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              onSubmitted: (_) => _submit(),
              onChanged: _clearErrors,
              decoration: decoration(l.passwordRepeat, _repeatError),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(onPressed: _submit, child: Text(_choosing ? l.backupEncrypt : l.ok)),
      ],
    );
  }
}
