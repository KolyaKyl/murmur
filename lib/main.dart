import 'package:audio_service/audio_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:murmur/features/sounds/player/audio_handler.dart';
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
  final ambient = prefs.getBool(AmbientController.prefsKey) ??
      AmbientController.defaultEnabled;
  final localeCode = prefs.getString(LocaleController.prefsKey);
  final locale = localeCode == null ? null : Locale(localeCode);

  // Медиа-сессия поднимается до первого кадра: система должна знать
  // о приложении раньше, чем оно начнёт играть.
  final audioHandler = await AudioService.init(
    builder: MurmurAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'app.fone.murmur.playback',
      androidNotificationChannelName: 'MurMur',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        themeProvider.overrideWith((ref) => ThemeController(prefs, isDark)),
        localeProvider.overrideWith((ref) => LocaleController(prefs, locale)),
        ambientEnabledProvider
            .overrideWith((ref) => AmbientController(prefs, ambient)),
        audioHandlerProvider.overrideWithValue(audioHandler),
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const MurmurApp(),
    ),
  );
}
