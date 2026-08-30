import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murmur/app/app.dart';
import 'package:murmur/app/providers.dart';
import 'package:murmur/core/firebase/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

  // Тему читаем до первого кадра — иначе приложение успевает мигнуть
  // светлой темой и только потом перекраситься.
  final prefs = await SharedPreferences.getInstance();
  final isDark =
      prefs.getBool(ThemeController.prefsKey) ?? ThemeController.defaultIsDark;

  runApp(
    ProviderScope(
      overrides: [
        themeProvider.overrideWith((ref) => ThemeController(prefs, isDark)),
      ],
      child: const MurmurApp(),
    ),
  );
}
