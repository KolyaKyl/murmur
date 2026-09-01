import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murmur/core/theme/app_theme.dart';
import 'package:murmur/features/sounds/models/sound.dart';
import 'package:murmur/features/sounds/player/player_controller.dart';

/// Обложка звука. Пока ссылка тянется из Storage, показываем ровный фон,
/// а не пустоту и не спиннер — карточка не должна дёргаться.
class SoundCover extends ConsumerWidget {
  const SoundCover({
    super.key,
    required this.sound,
    this.radius = AppRadius.md,
    this.fit = BoxFit.cover,
  });

  final Sound sound;
  final double radius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(color: scheme.surfaceContainer);

    if (sound.coverPath.isEmpty) {
      return ClipRRect(
          borderRadius: BorderRadius.circular(radius), child: placeholder);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: FutureBuilder<String>(
        future: ref.read(soundsRepositoryProvider).resolveUrl(sound.coverPath),
        builder: (context, snap) {
          final url = snap.data;
          if (url == null) return placeholder;
          return CachedNetworkImage(
            imageUrl: url,
            fit: fit,
            placeholder: (_, __) => placeholder,
            errorWidget: (_, __, ___) => placeholder,
          );
        },
      ),
    );
  }
}

/// Обложка микса: одна дорожка — её картинка, несколько — мозаика.
/// Своей картинки у микса нет, поэтому показываем состав.
class MixCover extends StatelessWidget {
  const MixCover({
    super.key,
    required this.sounds,
    this.radius = AppRadius.md,
  });

  final List<Sound> sounds;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (sounds.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: ColoredBox(
          color: scheme.surfaceContainer,
          child: const Center(
            child: Image(
                image: AssetImage('assets/logo/logo_round.png'), width: 28),
          ),
        ),
      );
    }
    if (sounds.length == 1) {
      return SoundCover(sound: sounds.first, radius: radius);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Row(
        children: [
          Expanded(flex: 2, child: SoundCover(sound: sounds[0], radius: 0)),
          const SizedBox(width: 1.5),
          Expanded(
            child: Column(
              children: [
                Expanded(child: SoundCover(sound: sounds[1], radius: 0)),
                if (sounds.length > 2) ...[
                  const SizedBox(height: 1.5),
                  Expanded(child: SoundCover(sound: sounds[2], radius: 0)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
