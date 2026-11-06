import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/auto_backup.dart';
import 'data/database.dart';
import 'l10n/app_localizations.dart';
import 'providers.dart';
import 'recovery_screen.dart';
import 'ui/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferencesWithCache.create(cacheOptions: const SharedPreferencesWithCacheOptions());
  await _deleteOldExports();
  await _start(prefs);
}

// Shared exports stay in the cache after the share sheet closes; protocol exports are unencrypted.
// Deleting right after sharing could break the receiving app while it still reads the file.
Future<void> _deleteOldExports() async {
  final exportName = RegExp(r'^(whatseat-backup-.*\.json|essprotokoll_.*\.(csv|pdf))$');
  try {
    await for (final entity in (await getTemporaryDirectory()).list(recursive: true)) {
      if (entity is File && exportName.hasMatch(p.basename(entity.path))) await entity.delete();
    }
  } on FileSystemException {
    // Best effort: the next start tries again.
  }
}

// iOS backs up Documents to iCloud; Android's backup is switched off in the manifest.
Future<void> _excludeFromBackup() async {
  if (!Platform.isIOS) return;
  final paths = [for (final f in await databaseFiles()) if (await f.exists()) f.path];
  try {
    await const MethodChannel('whatseat/storage').invokeMethod('excludeFromBackup', paths);
  } on PlatformException {
    // Best effort: the next start tries again.
  }
}

/// Secure storage may be what failed in the first place, so each step is best effort.
Future<void> _forgetAutoBackup(SharedPreferencesWithCache prefs) async {
  AutoBackupConfig? config;
  try {
    config = await loadAutoBackupConfig();
  } on Exception {
    config = null;
  }
  try {
    await forgetAutoBackup(prefs, config);
  } on PlatformException {
    // Unreadable storage holds no configuration that could run either.
  }
}

Future<void> _start(SharedPreferencesWithCache prefs,
    {Map<String, dynamic>? restore, AutoBackupConfig? autoBackup}) async {
  AppDatabase? db;
  final bool fresh;
  try {
    fresh = !await (await databaseFiles()).first.exists();
    final localeCode = prefs.getString('locale') ?? '';
    final l = lookupAppLocalizations(localeCode.isEmpty
        ? basicLocaleListResolution(WidgetsBinding.instance.platformDispatcher.locales, AppLocalizations.supportedLocales)
        : Locale(localeCode));
    db = AppDatabase(await loadOrCreateDbKey(),
        listDefaults: listDefaults(l, prefs.getStringList('customUnits') ?? const []));
    // Opening is lazy; a wrong or lost key only surfaces on the first query.
    await db.customSelect('SELECT count(*) FROM sqlite_master').get();
    // Moved into the unit lists by the migration above.
    await prefs.remove('customUnits');
  } on Object catch (error) {
    await db?.close();
    runApp(RecoveryApp(
      localeCode: prefs.getString('locale') ?? '',
      error: error,
      onRetry: () => _start(prefs),
      onReset: (backup, {autoBackup}) async {
        await resetDatabase();
        await _start(prefs, restore: backup, autoBackup: autoBackup);
      },
    ));
    return;
  }
  // A configuration left from before (after a reset, or an iOS reinstall: the Keychain outlives the app) would keep
  // backing up the empty diary in the old series, whose full backups get pruned within a week.
  if (fresh) await _forgetAutoBackup(prefs);
  // Undo only lives as long as the snackbar, so anything still marked deleted is gone for good.
  await db.purgeDeleted();
  if (restore != null) {
    try {
      await db.importBackup(restore);
    } on Object {
      await db.close();
      rethrow;
    }
  }
  if (autoBackup != null) {
    try {
      await saveAutoBackupConfig(autoBackup);
    } on PlatformException {
      // The restore itself succeeded; automatic backup can be set up again in the settings.
    }
  }
  await _excludeFromBackup();
  runApp(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      prefsProvider.overrideWithValue(prefs),
    ],
    child: const WhatsEatApp(),
  ));
}
