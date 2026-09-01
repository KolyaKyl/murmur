import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murmur/core/theme/app_theme.dart';
import 'package:murmur/features/sounds/data/sounds_providers.dart';
import 'package:murmur/features/sounds/player/player_controller.dart';
import 'package:murmur/features/sounds/screens/sounds_screen.dart';
import 'package:murmur/l10n/app_localizations.dart';

/// Та же библиотека, но шторкой и с другим смыслом тапа: здесь дорожка
/// добавляется к миксу, а не заменяет его. Отсюда и отдельный заголовок —
/// человек должен видеть, в каком режиме он находится.
class AddToMixSheet extends ConsumerWidget {
  const AddToMixSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        backgroundColor: Theme.of(context).colorScheme.surfaceDim,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        builder: (_) => const AddToMixSheet(),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final mix = ref.watch(playerProvider);
    final sounds = ref.watch(filteredSoundsProvider);
    final inMix = mix.layers.map((l) => l.sound.id).toSet();

    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.sm, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.addToMix,
                          style: Theme.of(context).textTheme.titleLarge),
                      Text(
                        '${mix.layers.length} of ${PlayerController.maxLayers}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: SoundGrid(
              sounds: sounds,
              dimIds: inMix,
              badgeFor: (s) => inMix.contains(s.id) ? l10n.inMix : null,
              onTap: (s) async {
                await ref.read(playerProvider.notifier).addLayer(s);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
