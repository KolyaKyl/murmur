import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murmur/app/providers.dart';
import 'package:murmur/features/breathing/data/breathing_repository.dart';
import 'package:murmur/features/breathing/models/practice.dart';
import 'package:murmur/core/models/catalog_category.dart';

final breathingRepositoryProvider = Provider((ref) => BreathingRepository());

final practicesProvider = FutureProvider<List<BreathingPractice>>(
    (ref) => ref.read(breathingRepositoryProvider).fetchPractices());

final breathingCategoriesProvider = FutureProvider<List<CatalogCategory>>(
    (ref) => ref.read(breathingRepositoryProvider).fetchCategories());

final breathingStatsProvider = FutureProvider<BreathingStats>(
    (ref) => ref.read(breathingRepositoryProvider).fetchStats());

/// Выбранная категория. null — все практики.
final practiceFilterProvider = StateProvider<String?>((ref) => null);

final filteredPracticesProvider = Provider<List<BreathingPractice>>((ref) {
  final all = ref.watch(practicesProvider).valueOrNull ?? const [];
  final filter = ref.watch(practiceFilterProvider);
  if (filter == null) return all;
  return all.where((p) => p.categories.contains(filter)).toList();
});

/// Настройка, которая переживает перезапуск. Спрашивать одно и то же
/// перед каждой практикой — раздражает.
class _PrefFlag extends StateNotifier<bool> {
  _PrefFlag(this._ref, this._key, bool fallback)
      : super(_ref.read(sharedPrefsProvider).getBool(_key) ?? fallback);

  final Ref _ref;
  final String _key;

  set value(bool v) {
    state = v;
    _ref.read(sharedPrefsProvider).setBool(_key, v);
  }
}

/// Вибрация на фазах.
final breathVibrationProvider = StateNotifierProvider<_PrefFlag, bool>(
    (ref) => _PrefFlag(ref, 'breathVibration', true));

/// Оставлять ли звук играть под практикой.
final breathKeepSoundProvider = StateNotifierProvider<_PrefFlag, bool>(
    (ref) => _PrefFlag(ref, 'breathKeepSound', true));
