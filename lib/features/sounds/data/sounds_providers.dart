import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murmur/features/sounds/models/sound.dart';
import 'package:murmur/features/sounds/player/player_controller.dart';
import 'package:murmur/core/models/catalog_category.dart';

final soundsProvider = FutureProvider<List<Sound>>(
    (ref) => ref.read(soundsRepositoryProvider).fetchSounds());

final categoriesProvider = FutureProvider<List<CatalogCategory>>(
    (ref) => ref.read(soundsRepositoryProvider).fetchCategories());

final mixesProvider = FutureProvider<List<SavedMix>>(
    (ref) => ref.read(soundsRepositoryProvider).fetchMixes());

final recentIdsProvider = FutureProvider<List<String>>(
    (ref) => ref.read(soundsRepositoryProvider).fetchRecentIds());

/// Избранное держим в памяти: сердечко должно откликаться мгновенно,
/// а не ждать ответа сети.
class FavoritesController extends StateNotifier<Set<String>> {
  FavoritesController(this._ref) : super({}) {
    load();
  }

  final Ref _ref;

  Future<void> load() async {
    state = await _ref.read(soundsRepositoryProvider).fetchFavoriteIds();
  }

  Future<void> toggle(String soundId) async {
    final next = {...state};
    final adding = !next.contains(soundId);
    adding ? next.add(soundId) : next.remove(soundId);
    state = next;
    await _ref.read(soundsRepositoryProvider).setFavorite(soundId, adding);
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesController, Set<String>>(
        (ref) => FavoritesController(ref));

/// Что выбрано на экране библиотеки.
final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

/// Библиотека после поиска и фильтра. Категория — массив у звука,
/// поэтому одна дорожка попадает сразу под несколько чипов.
final filteredSoundsProvider = Provider<List<Sound>>((ref) {
  final all = ref.watch(soundsProvider).valueOrNull ?? const <Sound>[];
  final q = ref.watch(searchQueryProvider).trim().toLowerCase();
  final cat = ref.watch(selectedCategoryProvider);
  return all.where((s) {
    final byCat = cat == null || s.categories.contains(cat);
    final byQuery = q.isEmpty ||
        s.title.toLowerCase().contains(q) ||
        s.subtitle.toLowerCase().contains(q);
    return byCat && byQuery;
  }).toList();
});
