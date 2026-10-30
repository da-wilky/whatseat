import 'package:flutter/material.dart';

import '../data/backup_crypto.dart';
import '../l10n/app_localizations.dart';

const _minPasswordLength = 8;

/// Returns the password, '' once the user confirmed exporting without one, or null when cancelled.
Future<String?> askExportPassword(BuildContext context) async {
  while (true) {
    if (!context.mounted) return null;
    final password = await showDialog<String>(
      context: context,
      builder: (_) => const _PasswordDialog(forExport: true),
    );
    if (password == null || password.isNotEmpty) return password;
    if (!context.mounted) return null;
    if (await _confirmUnencrypted(context)) return '';
  }
}

Future<bool> _confirmUnencrypted(BuildContext context) async {
  final l = AppLocalizations.of(context);
  final scheme = Theme.of(context).colorScheme;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, color: scheme.error),
      title: Text(l.backupUnencryptedTitle),
      content: Text(l.backupUnencryptedRisk),
      actions: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: scheme.error),
          onPressed: () => Navigator.pop(context, true),
          child: Text(l.backupUnencryptedConfirm),
        ),
        FilledButton(onPressed: () => Navigator.pop(context, false), child: Text(l.backupSetPassword)),
      ],
    ),
  );
  return ok ?? false;
}

/// Plain backups pass through; encrypted ones ask for the password until it fits. Null when cancelled.
Future<Map<String, dynamic>?> openBackup(BuildContext context, Map<String, dynamic> json) async {
  if (!isEncryptedBackup(json)) return json;
  var wrong = false;
  while (true) {
    if (!context.mounted) return null;
    final password = await showDialog<String>(
      context: context,
      builder: (_) => _PasswordDialog(forExport: false, wrong: wrong),
    );
    if (password == null || !context.mounted) return null;
    try {
      return await withBusyDialog(context, () => decryptBackup(json, password));
    } on WrongBackupPasswordException {
      wrong = true;
    }
  }
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
  const _PasswordDialog({required this.forExport, this.wrong = false});

  final bool forExport;
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

  void _submit() {
    final l = AppLocalizations.of(context);
    final password = _password.text;
    if (widget.forExport) {
      setState(() {
        _passwordError = password.length < _minPasswordLength ? l.passwordTooShort(_minPasswordLength) : null;
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
    return AlertDialog(
      scrollable: true,
      title: Text(widget.forExport ? l.backupEncryptTitle : l.backupLockedTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.forExport ? l.backupEncryptHint : l.backupLockedHint),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            autofocus: true,
            obscureText: _obscure,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: widget.forExport ? TextInputAction.next : TextInputAction.done,
            onSubmitted: widget.forExport ? null : (_) => _submit(),
            onChanged: _clearErrors,
            decoration: decoration(l.password, widget.wrong ? l.backupWrongPassword : _passwordError).copyWith(
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          if (widget.forExport) ...[
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
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: () => Navigator.pop(context, ''), child: Text(l.backupWithoutPassword)),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(onPressed: _submit, child: Text(widget.forExport ? l.backupEncrypt : l.ok)),
      ],
    );
  }
}
