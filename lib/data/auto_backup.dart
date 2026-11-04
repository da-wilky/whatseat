import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers.dart';
import 'backup_crypto.dart';
import 'backup_destinations.dart';
import 'models.dart';

const _configKey = 'auto_backup';
const _keepBackups = 7;
const _debounce = Duration(minutes: 2);
/// Automatic backups carry their series; manual exports have none.
final _backupName = RegExp(r'^whatseat-backup-(\d{4}-\d{2}-\d{2})(?:-([0-9a-f]{8}))?\.json$');

class AutoBackupConfig {
  const AutoBackupConfig({required this.destination, required this.key});

  final BackupDestination destination;
  final BackupKey key;

  Map<String, dynamic> toJson() => {'destination': destination.toJson(), 'key': key.toJson()};

  factory AutoBackupConfig.fromJson(Map<String, dynamic> json) => AutoBackupConfig(
        destination: BackupDestination.fromJson(json['destination'] as Map<String, dynamic>),
        key: BackupKey.fromJson(json['key'] as Map<String, dynamic>),
      );
}

/// Lives in secure storage: it holds the backup key and the destination's credentials.
Future<AutoBackupConfig?> loadAutoBackupConfig() async {
  final raw = await secureStorage.read(key: _configKey);
  return raw == null ? null : AutoBackupConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

Future<void> saveAutoBackupConfig(AutoBackupConfig? config) => config == null
    ? secureStorage.delete(key: _configKey)
    : secureStorage.write(key: _configKey, value: jsonEncode(config.toJson()));

/// Turns automatic backup off on this device. Files at the destination stay.
Future<void> forgetAutoBackup(SharedPreferencesWithCache prefs, AutoBackupConfig? config) async {
  await saveAutoBackupConfig(null);
  for (final key in ['backupLastSuccess', 'backupLastError', 'backupDirty', 'serverKeepAlive', 'serverInactiveDays']) {
    await prefs.remove(key);
  }
  if (config?.destination case final FolderDestination folder) {
    try {
      await folder.release();
    } on BackupDestinationException {
      // Best effort: an unreleased grant only counts against the app's limit.
    }
  }
}

/// Backup file names, newest first.
Future<List<String>> listBackups(BackupDestination destination) async =>
    (await destination.list()).where(_backupName.hasMatch).toList()..sort((a, b) => b.compareTo(a));

DateTime backupDay(String name) => parseDayKey(_backupName.firstMatch(name)!.group(1)!);

String? backupSeries(String name) => _backupName.firstMatch(name)!.group(2);

Future<Map<String, dynamic>> readBackupFile(BackupDestination destination, String name) async =>
    jsonDecode(utf8.decode(await destination.read(name))) as Map<String, dynamic>;

class AutoBackupStatus {
  const AutoBackupStatus({
    this.config,
    this.lastSuccess,
    this.lastError,
    this.running = false,
    this.keepAlive = true,
    this.inactiveDays,
  });

  final AutoBackupConfig? config;
  final DateTime? lastSuccess;
  final String? lastError;
  final bool running;

  /// Own server only: report activity on every app start, not just with backups.
  final bool keepAlive;

  /// Own server only, as last reported by it: days without activity until the account is deleted, 0 for never.
  final int? inactiveDays;
}

/// Data only changes while the app is open, so a backup shortly after changes and on leaving the app
/// covers everything without a background scheduler. One that didn't get through is retried on the next start.
class AutoBackupNotifier extends AsyncNotifier<AutoBackupStatus> {
  AutoBackupConfig? _config;
  Future<void>? _running;
  Timer? _timer;

  @override
  Future<AutoBackupStatus> build() async {
    final updates = ref.watch(databaseProvider).tableUpdates().listen((_) => _changed());
    final lifecycle = AppLifecycleListener(onPause: () {
      if (_dirty) backupNow();
    });
    ref.onDispose(() {
      updates.cancel();
      lifecycle.dispose();
      _timer?.cancel();
    });
    _config = await loadAutoBackupConfig();
    // After build has completed, so its result doesn't overwrite the running state.
    if (_config != null && _dirty) Timer.run(backupNow);
    if (_keepAlive) Timer.run(_pingServer);
    return _status();
  }

  bool get _dirty => ref.read(prefsProvider).getBool('backupDirty') ?? false;
  bool get _keepAlive => ref.read(prefsProvider).getBool('serverKeepAlive') ?? true;

  AutoBackupStatus _status() {
    final prefs = ref.read(prefsProvider);
    final last = prefs.getInt('backupLastSuccess');
    return AutoBackupStatus(
      config: _config,
      lastSuccess: last == null ? null : DateTime.fromMillisecondsSinceEpoch(last),
      lastError: prefs.getString('backupLastError'),
      running: _running != null,
      keepAlive: _keepAlive,
      inactiveDays: prefs.getInt('serverInactiveDays'),
    );
  }

  /// Also refreshes how long the server keeps inactive accounts, which its admin may change.
  Future<void> _pingServer() async {
    final destination = _config?.destination;
    if (destination is! ServerDestination) return;
    try {
      final info = await destination.ping();
      await ref.read(prefsProvider).setInt('serverInactiveDays', info.inactiveDays);
    } on BackupDestinationException {
      // Best effort: the next start or backup counts as activity too.
      return;
    }
    if (ref.mounted) state = AsyncData(_status());
  }

  Future<void> setKeepAlive(bool enabled) async {
    await ref.read(prefsProvider).setBool('serverKeepAlive', enabled);
    state = AsyncData(_status());
    if (enabled) await _pingServer();
  }

  void _changed() {
    if (_config == null) return;
    ref.read(prefsProvider).setBool('backupDirty', true);
    _timer?.cancel();
    _timer = Timer(_debounce, backupNow);
  }

  Future<void> enable(AutoBackupConfig config) async {
    await saveAutoBackupConfig(config);
    _config = config;
    await backupNow();
    await _pingServer();
  }

  /// With [deleteBackups], removes this setup's backups at the destination first (on the own server, the whole
  /// account). If that fails, nothing changes and the error is thrown.
  Future<void> disable({required bool deleteBackups}) async {
    final config = _config;
    if (config == null) return;
    _timer?.cancel();
    // Cleared first, so no new backup starts; one already running finishes before anything is deleted.
    _config = null;
    await _running;
    if (deleteBackups) {
      try {
        final destination = config.destination;
        if (destination is ServerDestination) {
          await destination.deleteAccount();
        } else {
          for (final name in await listBackups(destination)) {
            if (backupSeries(name) == config.key.series) await destination.delete(name);
          }
        }
      } on BackupDestinationException {
        _config = config;
        state = AsyncData(_status());
        rethrow;
      }
    }
    await forgetAutoBackup(ref.read(prefsProvider), config);
    state = AsyncData(_status());
  }

  // Future() defers _run, so _running is already set when it reports the running state.
  Future<void> backupNow() => _running ??= Future(_run).whenComplete(() {
        _running = null;
        if (ref.mounted) state = AsyncData(_status());
      });

  Future<void> _run() async {
    final config = _config;
    if (config == null) return;
    _timer?.cancel();
    state = AsyncData(_status());
    final prefs = ref.read(prefsProvider);
    // Cleared first: a change made while the upload runs marks it dirty again.
    await prefs.setBool('backupDirty', false);
    try {
      final encrypted = await encryptBackupWithKey(await ref.read(databaseProvider).exportBackup(), config.key);
      await config.destination.write(
          'whatseat-backup-${dayKey(DateTime.now())}-${config.key.series}.json', utf8.encode(jsonEncode(encrypted)));
      await prefs.setInt('backupLastSuccess', DateTime.now().millisecondsSinceEpoch);
      await prefs.remove('backupLastError');
    } on Exception catch (e) {
      await prefs.setBool('backupDirty', true);
      await prefs.setString('backupLastError', '$e');
      return;
    }
    try {
      final own = (await listBackups(config.destination)).where((name) => backupSeries(name) == config.key.series);
      for (final old in own.skip(_keepBackups)) {
        await config.destination.delete(old);
      }
    } on BackupDestinationException {
      // Best effort: the next backup prunes again.
    }
  }
}

final autoBackupProvider = AsyncNotifierProvider<AutoBackupNotifier, AutoBackupStatus>(AutoBackupNotifier.new);
