import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murmur/app/widgets/glass_nav_bar.dart';
import 'package:murmur/core/theme/app_theme.dart';
import 'package:murmur/features/sounds/data/sounds_providers.dart';
import 'package:murmur/features/sounds/models/sound.dart';
import 'package:murmur/features/sounds/player/player_controller.dart';
import 'package:murmur/features/sounds/widgets/sound_card.dart';
import 'package:murmur/l10n/app_localizations.dart';

/// Библиотека. Тап по карточке заменяет то, что играет, — микс собирается
/// только из полного плеера.
class SoundsScreen extends ConsumerWidget {
  const SoundsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final sounds = ref.watch(soundsProvider);
    final filtered = ref.watch(filteredSoundsProvider);
    final mix = ref.watch(playerProvider);

    return Scaffold(
      body: RefreshIndicator(
        edgeOffset: kToolbarHeight + 20,
        onRefresh: () async {
          ref.invalidate(soundsProvider);
          ref.invalidate(categoriesProvider);
          await ref.read(favoritesProvider.notifier).load();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: Theme.of(context).colorScheme.surface,
              scrolledUnderElevation: 0,
              elevation: 0,
              title: Text(l10n.navSounds),
            ),
            const SliverToBoxAdapter(child: _SearchField()),
            const SliverToBoxAdapter(child: _CategoryChips()),
            sounds.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: _ErrorBox(
                  message: l10n.couldNotLoadData,
                  onRetry: () => ref.invalidate(soundsProvider),
                ),
              ),
              data: (_) => filtered.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text(l10n.noSoundsFound)),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: AppSpacing.md - 4,
                          mainAxisSpacing: AppSpacing.md - 4,
                          childAspectRatio: 1.14,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          childCount: filtered.length,
                          (context, i) {
                            final sound = filtered[i];
                            return SoundCard(
                              sound: sound,
                              active: mix.contains(sound.id),
                              onTap: () => ref
                                  .read(playerProvider.notifier)
                                  .playOnly(sound),
                            );
                          },
                        ),
                      ),
                    ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                  height: GlassNavBar.contentInset(context,
                      withPlayer: !ref.watch(playerProvider).isEmpty)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends ConsumerStatefulWidget {
  const _SearchField();

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  // Контроллер нужен только ради крестика: очистить поле снаружи
  // без него нельзя.
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
      child: TextField(
        controller: _controller,
        onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _controller.clear();
                    ref.read(searchQueryProvider.notifier).state = '';
                    FocusScope.of(context).unfocus();
                  },
                ),
          hintText: AppL10n.of(context).searchSounds,
        ),
      ),
    );
  }
}

class _CategoryChips extends ConsumerWidget {
  const _CategoryChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final selected = ref.watch(selectedCategoryProvider);

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          _Chip(
            label: AppL10n.of(context).allCategories,
            selected: selected == null,
            onTap: () =>
                ref.read(selectedCategoryProvider.notifier).state = null,
          ),
          for (final c in categories)
            _Chip(
              label: c.title,
              selected: selected == c.id,
              onTap: () => ref.read(selectedCategoryProvider.notifier).state =
                  selected == c.id ? null : c.id,
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: selected
                ? scheme.onSurface.withValues(alpha: 0.13)
                : Colors.transparent,
            border: Border.all(
                color: selected ? Colors.transparent : scheme.outlineVariant),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off,
                size: 44,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
                onPressed: onRetry, child: Text(AppL10n.of(context).tryAgain)),
          ],
        ),
      ),
    );
  }
}

/// Сетка для шторки добавления и списков избранного — та же карточка,
/// но тап отдаётся наружу.
class SoundGrid extends ConsumerWidget {
  const SoundGrid({
    super.key,
    required this.sounds,
    required this.onTap,
    this.dimIds = const {},
    this.badgeFor,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  final List<Sound> sounds;
  final void Function(Sound) onTap;
  final Set<String> dimIds;
  final String? Function(Sound)? badgeFor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mix = ref.watch(playerProvider);
    return GridView.builder(
      padding: padding,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md - 4,
        mainAxisSpacing: AppSpacing.md - 4,
        childAspectRatio: 1.14,
      ),
      itemCount: sounds.length,
      itemBuilder: (context, i) {
        final s = sounds[i];
        return SoundCard(
          sound: s,
          active: mix.contains(s.id),
          dimmed: dimIds.contains(s.id),
          badge: badgeFor?.call(s),
          onTap: () => onTap(s),
        );
      },
    );
  }
}
