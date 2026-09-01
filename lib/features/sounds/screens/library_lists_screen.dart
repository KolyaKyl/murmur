import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murmur/core/theme/app_theme.dart';
import 'package:murmur/features/sounds/data/sounds_providers.dart';
import 'package:murmur/features/sounds/models/sound.dart';
import 'package:murmur/features/sounds/player/player_controller.dart';
import 'package:murmur/features/sounds/screens/sounds_screen.dart';
import 'package:murmur/features/sounds/widgets/sound_cover.dart';
import 'package:murmur/l10n/app_localizations.dart';

enum SoundListKind { recent, favorites }

/// Недавние и избранное — один экран, разный источник списка.
class SoundListScreen extends ConsumerWidget {
  const SoundListScreen({super.key, required this.kind});

  final SoundListKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final all = ref.watch(soundsProvider).valueOrNull ?? const <Sound>[];
    final byId = {for (final s in all) s.id: s};

    final title =
        kind == SoundListKind.recent ? l10n.recentlyPlayed : l10n.favorites;

    final ids = kind == SoundListKind.recent
        ? (ref.watch(recentIdsProvider).valueOrNull ?? const <String>[])
        : ref.watch(favoritesProvider).toList();

    final sounds = [
      for (final id in ids)
        if (byId[id] != null) byId[id]!
    ];

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: sounds.isEmpty
          ? Center(
              child: Text(kind == SoundListKind.recent
                  ? l10n.noRecentYet
                  : l10n.noFavoritesYet))
          : SoundGrid(
              sounds: sounds,
              onTap: (s) => ref.read(playerProvider.notifier).playOnly(s),
            ),
    );
  }
}

/// Сохранённые миксы: состав и громкости запускаются одним тапом.
class MixesScreen extends ConsumerWidget {
  const MixesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final mixes = ref.watch(mixesProvider);
    final all = ref.watch(soundsProvider).valueOrNull ?? const <Sound>[];
    final byId = {for (final s in all) s.id: s};

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myMixes)),
      body: mixes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.couldNotLoadData)),
        data: (list) => list.isEmpty
            ? Center(child: Text(l10n.noMixesYet))
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: list.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) {
                  final mix = list[i];
                  final sounds = [
                    for (final id in mix.soundIds)
                      if (byId[id] != null) byId[id]!
                  ];
                  return Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                            width: 62,
                            height: 62,
                            child: MixCover(sounds: sounds)),
                        const SizedBox(width: AppSpacing.md - 3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(mix.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyLarge),
                              const SizedBox(height: 2),
                              Text(
                                sounds.map((s) => s.title).join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.play_arrow),
                          onPressed: sounds.isEmpty
                              ? null
                              : () => ref
                                  .read(playerProvider.notifier)
                                  .playMix(sounds, mix.volumes, name: mix.name),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline,
                              color: Theme.of(context).colorScheme.error),
                          onPressed: () async {
                            await ref
                                .read(soundsRepositoryProvider)
                                .deleteMix(mix.id);
                            ref.invalidate(mixesProvider);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
