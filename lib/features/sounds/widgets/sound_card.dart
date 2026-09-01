import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murmur/core/theme/app_theme.dart';
import 'package:murmur/features/sounds/data/sounds_providers.dart';
import 'package:murmur/features/sounds/models/sound.dart';
import 'package:murmur/features/sounds/player/player_controller.dart';
import 'package:murmur/features/sounds/widgets/sound_cover.dart';

/// Квадратная карточка библиотеки: картинка во всю плитку, поверх неё
/// название и категория, сердечко и корона по углам.
class SoundCard extends ConsumerWidget {
  const SoundCard({
    super.key,
    required this.sound,
    required this.active,
    required this.onTap,
    this.showHeart = true,
    this.dimmed = false,
    this.badge,
  });

  final Sound sound;
  final bool active;
  final VoidCallback onTap;
  final bool showHeart;
  final bool dimmed;
  final String? badge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final favorite = ref.watch(favoritesProvider).contains(sound.id);
    final loading =
        ref.watch(playerProvider.select((s) => s.loadingSoundId)) == sound.id;

    return Opacity(
      opacity: dimmed ? 0.45 : 1,
      child: GestureDetector(
        onTap: dimmed ? null : onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: active ? scheme.primary : scheme.outlineVariant,
              width: active ? 2 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg - 1),
            child: Stack(
              fit: StackFit.expand,
              children: [
                SoundCover(sound: sound, radius: 0),
                // Затемнение снизу, иначе название тонет в светлой картинке.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.center,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                    ),
                  ),
                ),
                Positioned(
                  left: 11,
                  right: 11,
                  bottom: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        sound.title,
                        style:
                            textTheme.bodyLarge?.copyWith(color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        sound.subtitle,
                        style: textTheme.labelMedium
                            ?.copyWith(color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (sound.premium)
                  const Positioned(
                    top: 9,
                    left: 9,
                    child: Icon(Icons.workspace_premium,
                        size: 18, color: Color(0xFFFFD24A)),
                  ),
                if (showHeart)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 34, minHeight: 34),
                      icon: Icon(
                        favorite ? Icons.favorite : Icons.favorite_border,
                        size: 19,
                        color: favorite
                            ? const Color(0xFFFF4D6D)
                            : Colors.white.withValues(alpha: 0.85),
                      ),
                      onPressed: () =>
                          ref.read(favoritesProvider.notifier).toggle(sound.id),
                    ),
                  ),
                // Пока дорожка качается — карточка это показывает.
                // Иначе тап выглядит как «ничего не произошло», человек
                // жмёт ещё раз и сбивает загрузку.
                if (loading)
                  const DecoratedBox(
                    decoration: BoxDecoration(color: Colors.black45),
                    child: Center(
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: Colors.white),
                      ),
                    ),
                  ),
                if (badge != null)
                  Positioned(
                    top: 9,
                    right: 9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(badge!,
                          style: textTheme.labelSmall
                              ?.copyWith(color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
