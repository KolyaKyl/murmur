import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murmur/core/theme/app_theme.dart';
import 'package:murmur/features/breathing/data/breathing_providers.dart';
import 'package:murmur/l10n/app_localizations.dart';
import 'package:murmur/core/format.dart';

/// Сводка по дыханию. Читает один документ, а не перебирает сессии, —
/// поэтому открывается мгновенно и не растёт в цене со временем.
class BreathingStatsScreen extends ConsumerWidget {
  const BreathingStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final stats = ref.watch(breathingStatsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.breathingStats)),
      body: stats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.couldNotLoadData)),
        data: (s) => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Row(
              children: [
                Expanded(
                    child: _Tile(
                        value: '${s.currentStreak}',
                        label: l10n.statStreakLabel(s.currentStreak))),
                const SizedBox(width: AppSpacing.sm + 2),
                Expanded(
                    child: _Tile(
                        value: '${s.longestStreak}',
                        label: l10n.statBestStreak)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            Row(
              children: [
                Expanded(
                    child: _Tile(
                        value: '${s.totalSessions}',
                        label: l10n.statSessionsLabel(s.totalSessions))),
                const SizedBox(width: AppSpacing.sm + 2),
                Expanded(
                    child: _Tile(
                        value: formatClock(s.totalSeconds),
                        label: l10n.totalTimeLabel)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.lg),
      decoration: appCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}
