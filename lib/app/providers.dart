import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murmur/core/models/app_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appUserProvider = StateProvider<AppUser?>((ref) => null);

/// Индекс настроения за 7 дней. Раньше жил в состоянии WellnessCard и
/// обновлялся через GlobalKey, который прокидывали через всё дерево
/// и даже в FirebaseService.
final moodIndexProvider = StateProvider<int>((ref) => 0);

final analyticsProvider =
    Provider<FirebaseAnalytics>((ref) => FirebaseAnalytics.instance);

/// Тема живёт в SharedPreferences, чтобы на холодном старте приложение
/// сразу открывалось в нужной. Firestore остаётся вторым хранилищем —
/// он синхронизирует выбор между устройствами, но первым не читается.
class ThemeController extends StateNotifier<bool> {
  ThemeController(this._prefs, bool initial) : super(initial);

  static const prefsKey = 'isDarkTheme';
  static const defaultIsDark = true;

  final SharedPreferences _prefs;

  Future<void> setDark(bool isDark) async {
    state = isDark;
    await _prefs.setBool(prefsKey, isDark);
  }
}

/// Переопределяется в main() значением, прочитанным до первого кадра.
final themeProvider = StateNotifierProvider<ThemeController, bool>(
  (ref) => throw UnimplementedError('themeProvider не переопределён в main()'),
);
