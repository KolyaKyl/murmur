import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murmur/core/theme/app_theme.dart';
import 'package:murmur/features/breathing/data/breathing_providers.dart';
import 'package:murmur/features/breathing/models/practice.dart';
import 'package:murmur/features/breathing/screens/session_done_screen.dart';
import 'package:murmur/features/breathing/widgets/practice_ring.dart';
import 'package:murmur/features/sounds/player/player_controller.dart';
import 'package:murmur/l10n/app_localizations.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:murmur/core/format.dart';

/// Сама практика. Открывается на корневом навигаторе, поэтому нижняя
/// плашка не мешает: на этом экране нечего нажимать, кроме паузы.
class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({
    super.key,
    required this.practice,
    required this.cycles,
  });

  static Route<void> route({
    required BreathingPractice practice,
    required int cycles,
  }) =>
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) =>
            SessionScreen(practice: practice, cycles: cycles),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      );

  final BreathingPractice practice;
  final int cycles;

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen>
    with SingleTickerProviderStateMixin {
  /// Три секунды перед первым вдохом. Человек нажал «Начать» и ещё
  /// держит телефон — без этой паузы первый цикл уходит впустую.
  static const _leadIn = Duration(seconds: 3);
  static const _ringMin = 0.60;
  static const _ringMax = 1.0;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(seconds: widget.practice.cycleSeconds * widget.cycles),
  );

  bool _leadInDone = false;
  bool _finished = false;
  int _lastTickKey = -1;
  double _lastPulseMs = -1000;

  /// Держим ссылку отдельно: в dispose доставать её через ref поздно,
  /// а вернуть громкость надо обязательно — иначе микс останется тихим.
  late final PlayerController _player = ref.read(playerProvider.notifier);

  /// Вдох и выдох различаются частотой: сила одинаковая, иначе выдох
  /// теряется. Часто — вдох, редко — выдох.
  static const double _inhalePulseMs = 170;
  static const double _exhalePulseMs = 300;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _controller.addListener(_onTick);
    _controller.addStatusListener(_onStatus);
    // Оставили звук — уводим под дыхание. Выключили — тишина.
    // Возвращаем в dispose в любом случае.
    _player.setDuckLevel(
        ref.read(breathKeepSoundProvider) ? PlayerController.duckQuiet : 0);
    Future<void>.delayed(_leadIn, () {
      if (!mounted) return;
      setState(() => _leadInDone = true);
      _controller.forward();
      _haptic(BreathPhase.inhale);
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _controller.dispose();
    // Громкость возвращаем всегда, даже если ушли посреди практики.
    _player.setDuckLevel(1);
    super.dispose();
  }

  // ---------- время и фазы ----------

  int get _totalSeconds => widget.practice.cycleSeconds * widget.cycles;
  double get _elapsed => _controller.value * _totalSeconds;
  int get _currentCycle =>
      (_elapsed / widget.practice.cycleSeconds)
          .floor()
          .clamp(0, widget.cycles - 1) +
      1;

  /// Фаза и доля пройденного внутри неё.
  ({BreathPhase phase, double t, int secondsLeft}) get _phaseNow {
    final phases = widget.practice.phases;
    var pos = _elapsed % widget.practice.cycleSeconds;
    for (final p in phases) {
      if (pos < p.seconds) {
        return (
          phase: p.phase,
          t: pos / p.seconds,
          secondsLeft: (p.seconds - pos).ceil(),
        );
      }
      pos -= p.seconds;
    }
    final last = phases.last;
    return (phase: last.phase, t: 1, secondsLeft: 0);
  }

  double get _ringScale {
    if (!_leadInDone) return _ringMin;
    final now = _phaseNow;
    final eased = Curves.easeInOut.transform(now.t);
    return switch (now.phase) {
      BreathPhase.inhale => _ringMin + (_ringMax - _ringMin) * eased,
      BreathPhase.holdIn => _ringMax,
      BreathPhase.exhale => _ringMax - (_ringMax - _ringMin) * eased,
      BreathPhase.holdOut => _ringMin,
    };
  }

  // ---------- отклик ----------

  void _onTick() {
    final now = _phaseNow;
    final vibration = ref.read(breathVibrationProvider);
    final elapsedMs = _elapsed * 1000;

    // Ключ меняется на каждой секунде каждой фазы.
    final key = now.phase.index * 1000 + now.secondsLeft;
    final phaseChanged =
        _lastTickKey >= 0 && _lastTickKey ~/ 1000 != now.phase.index;
    final secondChanged = key != _lastTickKey;
    _lastTickKey = key;

    if (vibration) {
      final moving =
          now.phase == BreathPhase.inhale || now.phase == BreathPhase.exhale;
      if (phaseChanged) {
        _haptic(now.phase);
        _lastPulseMs = elapsedMs;
      } else if (moving) {
        // Вдох частый, выдох редкий — сила одна и та же.
        final interval =
            now.phase == BreathPhase.inhale ? _inhalePulseMs : _exhalePulseMs;
        if (elapsedMs - _lastPulseMs >= interval) {
          _lastPulseMs = elapsedMs;
          HapticFeedback.mediumImpact();
        }
      } else if (secondChanged) {
        // На задержке кольцо стоит, поэтому щелчок заметный.
        HapticFeedback.heavyImpact();
      }
    }
    setState(() {});
  }

  void _haptic(BreathPhase phase) {
    switch (phase) {
      case BreathPhase.inhale:
        HapticFeedback.mediumImpact();
      case BreathPhase.exhale:
        HapticFeedback.mediumImpact();
      case BreathPhase.holdIn:
      case BreathPhase.holdOut:
        HapticFeedback.heavyImpact();
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_finished) {
      _finished = true;
      HapticFeedback.mediumImpact();
      Navigator.of(context).pushReplacement(
        SessionDoneScreen.route(
          practice: widget.practice,
          cycles: widget.cycles,
          seconds: _totalSeconds,
        ),
      );
    }
  }

  /// Сколько кругов человек дошёл до конца. Незавершённый круг не в счёт:
  /// практика считается сделанной с первого полного цикла.
  int get _completedCycles => (_elapsed / widget.practice.cycleSeconds).floor();

  /// Выход из практики. Полный круг есть — записываем и показываем итог,
  /// нет — просто уходим, чтобы не засорять статистику.
  void _leave() {
    if (_finished) return;
    _finished = true;
    _controller.stop();
    final cycles = _completedCycles;
    if (cycles < 1) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      SessionDoneScreen.route(
        practice: widget.practice,
        cycles: cycles,
        seconds: cycles * widget.practice.cycleSeconds,
      ),
    );
  }

  void _togglePause() {
    setState(() {
      _controller.isAnimating ? _controller.stop() : _controller.forward();
    });
  }

  String _phaseLabel(BreathPhase phase) {
    final l10n = AppL10n.of(context);
    return switch (phase) {
      BreathPhase.inhale => l10n.phaseInhale,
      BreathPhase.holdIn => l10n.phaseHold,
      BreathPhase.exhale => l10n.phaseExhale,
      BreathPhase.holdOut => l10n.phaseWait,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final mix = ref.watch(playerProvider);

    final now = _phaseNow;
    final glowColor = _leadInDone
        ? PhaseColors.of(context, now.phase)
        : scheme.onSurfaceVariant;
    final left = (_totalSeconds - _elapsed).ceil().clamp(0, _totalSeconds);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                _Header(title: widget.practice.title, onClose: _leave),
                const Spacer(),
                // Свет под кругом: он ниже центра, поэтому подсвечивает
                // снизу вверх, а стекло рассеивает его.
                _BreathingRing(
                  scale: _ringScale,
                  glowColor: glowColor,
                  label: _leadInDone ? _phaseLabel(now.phase) : l10n.getReady,
                ),
                const Spacer(),
                Text(
                  l10n.sessionProgress(
                      formatClock(left), _currentCycle, widget.cycles),
                  style: textTheme.labelMedium,
                ),
                const SizedBox(height: AppSpacing.md - 4),
                Container(
                  width: 220,
                  height: 3,
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: _controller.value.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: scheme.onSurface.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl + 8),
                _Controls(
                  paused: !_controller.isAnimating && _leadInDone,
                  onTogglePause: _togglePause,
                  onFinish: _leave,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (!mix.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(
                        bottom: AppSpacing.lg,
                        left: AppSpacing.lg,
                        right: AppSpacing.lg),
                    child: _SoundRow(title: mix.title),
                  )
                else
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
  const _Header({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down),
              onPressed: onClose,
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}

/// Стеклянный круг и свет под ним. Тени нет намеренно: она читалась
/// как «предмет лежит на столе», а круг должен восприниматься как источник.
class _BreathingRing extends StatelessWidget {
  const _BreathingRing({
    required this.scale,
    required this.glowColor,
    required this.label,
  });

  static const double _size = 252;

  final double scale;
  final Color glowColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final t = ((scale - 0.60) / 0.40).clamp(0.0, 1.0);

    // Растут оба, но круг быстрее: на выдохе вокруг него широкий ореол,
    // на пике вдоха остаётся тонкая светящаяся кромка.
    final circleD = _size * scale;
    final k = 1.28 - 0.235 * t;
    final glowD = circleD * k;

    // Под стеклом свет ровный: плотная заливка идёт ровно до края круга,
    // и только снаружи начинает гаснуть. Иначе сквозь прозрачное стекло
    // видны кольца — светлее к центру, темнее к краю.
    final coreStop = 1 / k;

    return SizedBox(
      height: 360,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Цвет фазы не подменяется рывком, а перетекает.
          TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: glowColor),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            builder: (context, color, _) {
              final c = color ?? glowColor;
              return Container(
                width: glowD,
                height: glowD,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    // Яркость постоянная: мерцание в такт дыханию
                    // на максимуме выглядело перекалом.
                    colors: [
                      c.withValues(alpha: 0.70),
                      c.withValues(alpha: 0.70),
                      c.withValues(alpha: 0),
                    ],
                    stops: [0, coreStop, 1],
                  ),
                ),
              );
            },
          ),
          Transform.scale(
            scale: scale,
            child: Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Прозрачное: свет должен читаться сквозь стекло,
                // а не упираться в него. Одинаково в обеих темах.
                color: scheme.surfaceContainer.withValues(alpha: 0.40),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: isDark ? 0.24 : 0.14),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontSize: 21),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Строка про звук с выключателем: раньше здесь было только сообщение,
/// и заглушить микс посреди практики было нечем.
class _SoundRow extends ConsumerWidget {
  const _SoundRow({required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final on = ref.watch(breathKeepSoundProvider);
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final next = !on;
        ref.read(breathKeepSoundProvider.notifier).value = next;
        // Включили — тихий фон под дыханием, выключили — тишина.
        // Полную громкость возвращает только выход из практики.
        ref
            .read(playerProvider.notifier)
            .setDuckLevel(next ? PlayerController.duckQuiet : 0);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            on ? Icons.volume_up_outlined : Icons.volume_off_outlined,
            size: 18,
            color: scheme.onSurface.withValues(alpha: on ? 0.62 : 0.34),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              on ? l10n.soundKeepsPlaying(title) : l10n.keepSoundPlaying,
              style: Theme.of(context).textTheme.labelSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.paused,
    required this.onTogglePause,
    required this.onFinish,
  });

  final bool paused;
  final VoidCallback onTogglePause;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Consumer(
      builder: (context, ref, _) {
        final vibration = ref.watch(breathVibrationProvider);
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SideButton(
              icon: vibration ? Icons.vibration : Icons.smartphone,
              label: l10n.vibration,
              dimmed: !vibration,
              onTap: () =>
                  ref.read(breathVibrationProvider.notifier).value = !vibration,
            ),
            const SizedBox(width: AppSpacing.xl),
            GestureDetector(
              onTap: onTogglePause,
              child: Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.onSurface.withValues(alpha: 0.92),
                ),
                child: Icon(paused ? Icons.play_arrow : Icons.pause,
                    size: 30, color: scheme.surface),
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
            _SideButton(
              icon: Icons.stop_outlined,
              label: l10n.finishPractice,
              onTap: onFinish,
            ),
          ],
        );
      },
    );
  }
}

class _SideButton extends StatelessWidget {
  const _SideButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.dimmed = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context)
        .colorScheme
        .onSurface
        .withValues(alpha: dimmed ? 0.34 : 0.78);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 23, color: color),
            const SizedBox(height: 4),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
