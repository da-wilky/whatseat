import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/database.dart';

const secureStorage = FlutterSecureStorage();

Future<String> loadOrCreateDbKey() async {
  const name = 'db_key';
  final existing = await secureStorage.read(key: name);
  if (existing != null) return existing;
  final random = Random.secure();
  final key = List.generate(32, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  await secureStorage.write(key: name, value: key);
  return key;
}

/// Irreversible: deletes the (unreadable) database and its key.
Future<void> resetDatabase() async {
  // Same location drift_flutter uses for `driftDatabase(name: 'whatseat')`.
  final dir = await getApplicationDocumentsDirectory();
  for (final suffix in ['', '-wal', '-shm', '-journal']) {
    final file = File(p.join(dir.path, 'whatseat.sqlite$suffix'));
    if (await file.exists()) await file.delete();
  }
  await secureStorage.delete(key: 'db_key');
}

final databaseProvider =Provider<AppDatabase>((ref) => throw UnimplementedError());
final prefsProvider = Provider<SharedPreferencesWithCache>((ref) => throw UnimplementedError());

class AppSettings {
  const AppSettings({
    required this.localeCode,
    required this.patientName,
    required this.lockEnabled,
    required this.biometricEnabled,
    required this.lockTimeoutSeconds,
    required this.pinLength,
    required this.customUnits,
  });

  /// Empty means: follow the system language.
  final String localeCode;
  final String patientName;
  final bool lockEnabled;
  final bool biometricEnabled;
  final int lockTimeoutSeconds;
  final int pinLength;
  final List<String> customUnits;

  Locale? get locale => localeCode.isEmpty ? null : Locale(localeCode);
}

class SettingsNotifier extends Notifier<AppSettings> {
  SharedPreferencesWithCache get _prefs => ref.read(prefsProvider);

  @override
  AppSettings build() {
    final p = ref.watch(prefsProvider);
    return AppSettings(
      localeCode: p.getString('locale') ?? '',
      patientName: p.getString('patientName') ?? '',
      lockEnabled: p.getBool('lockEnabled') ?? false,
      biometricEnabled: p.getBool('biometricEnabled') ?? false,
      lockTimeoutSeconds: p.getInt('lockTimeout') ?? 60,
      pinLength: p.getInt('pinLength') ?? 4,
      customUnits: p.getStringList('customUnits') ?? const [],
    );
  }

  Future<void> setLocale(String code) async {
    await _prefs.setString('locale', code);
    ref.invalidateSelf();
  }

  Future<void> setPatientName(String name) async {
    await _prefs.setString('patientName', name.trim());
    ref.invalidateSelf();
  }

  Future<void> enableLock(int pinLength) async {
    await _prefs.setInt('pinLength', pinLength);
    await _prefs.setBool('lockEnabled', true);
    ref.invalidateSelf();
  }

  Future<void> disableLock() async {
    await _prefs.setBool('lockEnabled', false);
    await _prefs.setBool('biometricEnabled', false);
    ref.invalidateSelf();
  }

  Future<void> setBiometric(bool enabled) async {
    await _prefs.setBool('biometricEnabled', enabled);
    ref.invalidateSelf();
  }

  Future<void> addUnit(String unit) async {
    if (state.customUnits.contains(unit)) return;
    await _prefs.setStringList('customUnits', [...state.customUnits, unit]);
    ref.invalidateSelf();
  }

  Future<void> setLockTimeout(int seconds) async {
    await _prefs.setInt('lockTimeout', seconds);
    ref.invalidateSelf();
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

final dayEntriesProvider =
    StreamProvider.autoDispose.family<List<MealEntry>, String>((ref, day) => ref.watch(databaseProvider).watchDay(day));

final dayNoteProvider =
    StreamProvider.autoDispose.family<DayNote?, String>((ref, day) => ref.watch(databaseProvider).watchDayNote(day));

final daysWithEntriesProvider = StreamProvider.autoDispose.family<Set<String>, (String, String)>(
    (ref, range) => ref.watch(databaseProvider).watchDaysWithEntries(range.$1, range.$2));

final templatesProvider =
    StreamProvider.autoDispose<List<MealTemplate>>((ref) => ref.watch(databaseProvider).watchTemplates());
