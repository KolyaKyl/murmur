import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murmur/core/theme/app_theme.dart';
import 'package:murmur/features/breathing/data/breathing_providers.dart';
import 'package:murmur/features/breathing/models/practice.dart';
import 'package:murmur/features/breathing/screens/session_screen.dart';
import 'package:murmur/l10n/app_localizations.dart';
import 'package:murmur/core/format.dart';

/// Итог практики. Сюда же пишется сессия и пересчитывается серия дней.
class SessionDoneScreen extends ConsumerStatefulWidget {
  const SessionDoneScreen({
    super.key,
    required this.practice,
    required this.cycles,
    required this.seconds,
  });

  static Route<void> route({
    required BreathingPractice practice,
    required int cycles,
    required int seconds,
  }) =>
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => SessionDoneScreen(
            practice: practice, cycles: cycles, seconds: seconds),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      );

  final BreathingPractice practice;
  final int cycles;
  final int seconds;

  @override
  ConsumerState<SessionDoneScreen> createState() => _SessionDoneScreenState();
}

class _SessionDoneScreenState extends ConsumerState<SessionDoneScreen> {
  BreathingStats? _stats;

  @override
  void initState() {
    super.initState();
    _record();
  }

  Future<void> _record() async {
    final stats = await ref.read(breathingRepositoryProvider).recordSession(
          practiceId: widget.practice.id,
          cycles: widget.cycles,
          seconds: widget.seconds,
        );
    ref.invalidate(breathingStatsProvider);
    if (mounted) setState(() => _stats = stats);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final stats = _stats;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 132,
                height: 132,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: scheme.onSurface.withValues(alpha: 0.35),
                      width: 2),
                ),
                // Логотип заполняет круг целиком: раньше он висел внутри
                // с полями и выглядел меньше отведённого места.
                child: ClipOval(
                  child: Image.asset('assets/logo/logo.png', fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.wellDone, style: textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${formatClock(widget.seconds)} · ${l10n.cyclesCount(widget.cycles)}',
                style: textTheme.labelMedium,
              ),
              const Spacer(),
              if (stats != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _Stat(
                        value: '${stats.currentStreak}',
                        label: l10n.statStreakLabel(stats.currentStreak)),
                    _Stat(
                        value: '${stats.totalSessions}',
                        label: l10n.statSessionsLabel(stats.totalSessions)),
                    _Stat(
                        value: formatClock(stats.totalSeconds),
                        label: l10n.totalTimeLabel),
                  ],
                ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.done),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    SessionScreen.route(
                        practice: widget.practice, cycles: widget.cycles),
                  ),
                  child: Text(l10n.oneMoreRound),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
