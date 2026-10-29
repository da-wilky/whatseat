import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/database.dart';
import 'providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final key = await loadOrCreateDbKey();
  final prefs = await SharedPreferencesWithCache.create(cacheOptions: const SharedPreferencesWithCacheOptions());
  runApp(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(AppDatabase(key)),
      prefsProvider.overrideWithValue(prefs),
    ],
    child: const WhatsEatApp(),
  ));
}
