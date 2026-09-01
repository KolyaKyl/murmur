import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murmur/core/theme/app_theme.dart';
import 'package:murmur/core/widgets/animated_gradient.dart';
import 'package:murmur/features/sounds/data/sounds_providers.dart';
import 'package:murmur/features/sounds/models/sound.dart';
import 'package:murmur/features/sounds/player/player_controller.dart';
import 'package:murmur/features/sounds/screens/add_to_mix_sheet.dart';
import 'package:murmur/features/sounds/widgets/sound_cover.dart';
import 'package:murmur/l10n/app_localizations.dart';

/// Полноэкранный плеер. Открывается на корневом навигаторе, поэтому
/// перекрывает нижний бар.
class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  static Route<void> route() => MaterialPageRoute(
        builder: (_) => const PlayerScreen(),
        fullscreenDialog: true,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final mix = ref.watch(playerProvider);
    final controller = ref.read(playerProvider.notifier);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Градиент замирает на паузе — экран должен показывать состояние.
          AnimatedGradient(animate: mix.playing),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.40),
                  Colors.black.withValues(alpha: 0.80),
                  Colors.black.withValues(alpha: 0.93),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _Header(),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: 168,
                  height: 168,
                  child: MixCover(
                    sounds: mix.layers.map((l) => l.sound).toList(),
                    radius: AppRadius.xl,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  mix.isEmpty ? l10n.addASound : mix.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (mix.layers.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      l10n.layersCount(mix.layers.length),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.68)),
                    ),
                  ),
                const Spacer(),
                // Дорожки над кнопками: сначала из чего собран звук,
                // потом чем им управлять.
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg - 4),
                  child: Column(
                    children: [
                      for (final layer in mix.layers) _LayerRow(layer: layer),
                      const SizedBox(height: AppSpacing.sm),
                      _AddSoundRow(full: mix.isFull, count: mix.layers.length),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _Controls(mix: mix, controller: controller),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Text(
            AppL10n.of(context).nowPlaying.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _LayerRow extends ConsumerWidget {
  const _LayerRow({required this.layer});

  final MixLayer layer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(playerProvider.notifier);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.fromLTRB(11, 9, 6, 9),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          SizedBox(
              width: 38,
              height: 38,
              child: SoundCover(sound: layer.sound, radius: AppRadius.sm)),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        layer.sound.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '${(layer.volume * 100).round()}%',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    overlayShape: SliderComponentShape.noOverlay,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 7),
                  ),
                  child: Slider(
                    value: layer.volume,
                    onChanged: (v) => controller.setVolume(layer.sound.id, v),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close,
                size: 18, color: Colors.white.withValues(alpha: 0.5)),
            onPressed: () => controller.removeLayer(layer.sound.id),
          ),
        ],
      ),
    );
  }
}

class _AddSoundRow extends ConsumerWidget {
  const _AddSoundRow({required this.full, required this.count});

  final bool full;
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Opacity(
      opacity: full ? 0.5 : 1,
      child: GestureDetector(
        onTap: full ? null : () => AddToMixSheet.show(context),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.24),
                style: BorderStyle.solid),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, size: 17, color: Colors.white70),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${AppL10n.of(context).addASound} · $count of ${PlayerController.maxLayers}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Controls extends ConsumerWidget {
  const _Controls({required this.mix, required this.controller});

  final MixState mix;
  final PlayerController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final left = mix.sleepLeft;
    final favorite = mix.isSingle &&
        ref.watch(favoritesProvider).contains(mix.layers.first.sound.id);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SideButton(
          icon: Icons.timer_outlined,
          label: left == null ? l10n.sleepTimerOff : '${left.inMinutes} min',
          onTap: () => _pickSleepTimer(context, controller),
        ),
        const SizedBox(width: AppSpacing.xl),
        GestureDetector(
          onTap: mix.isEmpty ? null : controller.togglePlay,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: mix.isEmpty ? 0.35 : 0.95),
            ),
            child: Icon(mix.playing ? Icons.pause : Icons.play_arrow,
                size: 32, color: Colors.black87),
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        // Одна кнопка, два смысла: одна дорожка — в избранное,
        // несколько — сохранить микс.
        _SideButton(
          icon: mix.isSingle
              ? (favorite ? Icons.favorite : Icons.favorite_border)
              : Icons.bookmark_outline,
          label: mix.isSingle ? l10n.favorites : l10n.save,
          color: favorite ? const Color(0xFFFF4D6D) : null,
          onTap: mix.isEmpty
              ? null
              : () {
                  if (mix.isSingle) {
                    ref
                        .read(favoritesProvider.notifier)
                        .toggle(mix.layers.first.sound.id);
                  } else {
                    _saveMixDialog(context, ref, mix);
                  }
                },
        ),
      ],
    );
  }
}

class _SideButton extends StatelessWidget {
  const _SideButton(
      {required this.icon, required this.label, this.onTap, this.color});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint =
        color ?? Colors.white.withValues(alpha: onTap == null ? 0.3 : 0.75);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 74,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 23, color: tint),
            const SizedBox(height: 4),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: tint)),
          ],
        ),
      ),
    );
  }
}

void _pickSleepTimer(BuildContext context, PlayerController controller) {
  const options = [15, 30, 45, 60, 90];
  showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(AppL10n.of(ctx).sleepTimer),
            trailing: TextButton(
              onPressed: () {
                controller.setSleepTimer(null);
                Navigator.pop(ctx);
              },
              child: Text(AppL10n.of(ctx).cancel),
            ),
          ),
          for (final m in options)
            ListTile(
              title: Text('$m min'),
              onTap: () {
                controller.setSleepTimer(Duration(minutes: m));
                Navigator.pop(ctx);
              },
            ),
        ],
      ),
    ),
  );
}

Future<void> _saveMixDialog(
    BuildContext context, WidgetRef ref, MixState mix) async {
  final controller = TextEditingController(text: mix.title);
  final l10n = AppL10n.of(context);
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.saveMix),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.saveMixHint, style: Theme.of(ctx).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
          TextField(controller: controller, autofocus: true),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: () async {
            final name = controller.text.trim();
            if (name.isEmpty) return;
            await ref.read(soundsRepositoryProvider).saveMix(
                  SavedMix(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    soundIds: mix.layers.map((l) => l.sound.id).toList(),
                    volumes: {for (final l in mix.layers) l.sound.id: l.volume},
                    createdAt: DateTime.now(),
                  ),
                );
            ref.invalidate(mixesProvider);
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: Text(l10n.save),
        ),
      ],
    ),
  );
}
