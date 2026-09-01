import 'package:flutter/material.dart';

/// Медленно переливающийся градиент из акцентов темы.
/// Один и тот же во всём приложении: шапка главного экрана, мини-плеер,
/// полноэкранный плеер, карточка индекса настроения.
///
/// [opacity] приглушает его там, где поверх лежит текст.
/// [animate] можно выключить — например, когда плеер на паузе.
class AnimatedGradient extends StatefulWidget {
  const AnimatedGradient({
    super.key,
    this.child,
    this.opacity = 1,
    this.animate = true,
    this.borderRadius,
    this.duration = const Duration(seconds: 2),
  });

  final Widget? child;
  final double opacity;
  final bool animate;
  final BorderRadius? borderRadius;

  /// Длительность одного прохода. Анимация идёт туда-обратно,
  /// то есть полный цикл вдвое длиннее.
  final Duration duration;

  @override
  State<AnimatedGradient> createState() => _AnimatedGradientState();
}

class _AnimatedGradientState extends State<AnimatedGradient>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(AnimatedGradient old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Container(
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              colors: [
                Color.lerp(scheme.primary, scheme.secondary, t)!
                    .withValues(alpha: widget.opacity),
                Color.lerp(scheme.secondary, scheme.onPrimaryFixed, t)!
                    .withValues(alpha: widget.opacity),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
