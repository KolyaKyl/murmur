import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murmur/app/widgets/glass_nav_bar.dart';
import 'package:murmur/core/theme/app_theme.dart';
import 'package:murmur/features/sounds/player/player_controller.dart';
import 'package:murmur/features/sounds/screens/player_screen.dart';
import 'package:murmur/features/sounds/widgets/sound_cover.dart';

/// Верхняя строка нижней плашки. Отдельной карточкой не рисуется —
/// это часть того же стекла, что и табы.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key, required this.collapsed});

  static const double height = 54;
  static const double collapsedHeight = 38;

  final bool collapsed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mix = ref.watch(playerProvider);
    final controller = ref.read(playerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;
    final left = mix.sleepLeft;
    final cover = collapsed ? 26.0 : 36.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () =>
          Navigator.of(context, rootNavigator: true).push(PlayerScreen.route()),
      child: SizedBox(
        height: collapsed ? collapsedHeight : height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md - 4),
          child: Row(
            children: [
              SizedBox(
                width: cover,
                height: cover,
                child: MixCover(
                  sounds: mix.layers.map((l) => l.sound).toList(),
                  radius: AppRadius.sm,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      mix.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyLarge?.copyWith(fontSize: 13),
                    ),
                    // Вторая строка уходит вместе со сжатием — там же,
                    // где прячутся подписи табов.
                    ClipRect(
                      child: AnimatedAlign(
                        duration: GlassNavBar.animation,
                        curve: Curves.easeOut,
                        alignment: Alignment.topLeft,
                        heightFactor: collapsed ? 0 : 1,
                        child: Text(
                          left == null
                              ? mix.layers.map((l) => l.sound.subtitle).first
                              : 'sleep in ${left.inMinutes} min',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelMedium?.copyWith(fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (mix.loading)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                )
              else
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(mix.playing ? Icons.pause : Icons.play_arrow,
                      size: collapsed ? 20 : 24),
                  onPressed: controller.togglePlay,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
