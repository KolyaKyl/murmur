import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murmur/core/theme/app_theme.dart';
import 'package:murmur/features/breathing/data/breathing_providers.dart';
import 'package:murmur/features/breathing/models/practice.dart';
import 'package:murmur/features/breathing/screens/session_screen.dart';
import 'package:murmur/features/breathing/widgets/practice_ring.dart';
import 'package:murmur/features/sounds/player/player_controller.dart';
import 'package:murmur/l10n/app_localizations.dart';
import 'package:murmur/core/format.dart';

/// Что спрашиваем перед стартом: длительность, вибрация, звук.
/// Длительность в минутах — она значит одно и то же в любой практике,
/// а число циклов у практик разное. Реальное время показываем строкой,
/// чтобы округление не выглядело обманом.
class PracticeSetupSheet extends ConsumerStatefulWidget {
  const PracticeSetupSheet({super.key, required this.practice});

  static const durations = [2, 5, 10, 15];

  final BreathingPractice practice;

  static Future<void> show(BuildContext context, BreathingPractice practice) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        // surfaceDim полупрозрачный — сквозь него просвечивал экран.
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        builder: (_) => PracticeSetupSheet(practice: practice),
      );

  @override
  ConsumerState<PracticeSetupSheet> createState() => _PracticeSetupSheetState();
}

class _PracticeSetupSheetState extends ConsumerState<PracticeSetupSheet> {
  int _minutes = 5;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    final practice = widget.practice;
    final mix = ref.watch(playerProvider);

    final cycles = practice.cyclesFor(Duration(minutes: _minutes));
    final real = practice.durationFor(cycles);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                PracticeRing(practice: practice, size: 62, stroke: 5),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(practice.title, style: textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(practice.rhythm,
                          style: textTheme.bodyMedium
                              ?.copyWith(letterSpacing: 0.6)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(practice.description, style: textTheme.labelMedium),
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.howLong, style: textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.sm + 2),
            Row(
              children: [
                for (final m in PracticeSetupSheet.durations)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: _DurationChip(
                      label: '$m min',
                      selected: m == _minutes,
                      onTap: () => setState(() => _minutes = m),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${l10n.cyclesCount(cycles)} · ${formatClock(real.inSeconds)} — ${l10n.endsOnExhale}',
              style: textTheme.labelSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            _Toggle(
              icon: Icons.vibration,
              title: l10n.vibration,
              subtitle: l10n.vibrationHint,
              value: ref.watch(breathVibrationProvider),
              onChanged: (v) =>
                  ref.read(breathVibrationProvider.notifier).value = v,
            ),
            if (!mix.isEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              _Toggle(
                icon: Icons.volume_up_outlined,
                title: l10n.keepSoundPlaying,
                subtitle: l10n.keepSoundHint,
                value: ref.watch(breathKeepSoundProvider),
                onChanged: (v) =>
                    ref.read(breathKeepSoundProvider.notifier).value = v,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context, rootNavigator: true).push(
                    SessionScreen.route(practice: practice, cycles: cycles),
                  );
                },
                child: Text(l10n.startPractice),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected
              ? scheme.onSurface.withValues(alpha: 0.13)
              : Colors.transparent,
          border: Border.all(
              color: selected ? Colors.transparent : scheme.outlineVariant),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md - 4, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyMedium),
                Text(subtitle, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
