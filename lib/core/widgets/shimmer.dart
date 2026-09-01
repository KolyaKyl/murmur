import 'package:flutter/material.dart';

/// Световая полоса, проходящая по содержимому. Показывает загрузку,
/// не пряча того, что грузится, — в отличие от круглого индикатора,
/// который закрывает картинку и мельтешит.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _controller.repeat();
  }

  @override
  void didUpdateWidget(Shimmer old) {
    super.didUpdateWidget(old);
    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.enabled && _controller.isAnimating) {
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
    if (!widget.enabled) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Полоса выезжает слева за кадром и уходит вправо за кадр,
        // поэтому диапазон шире экрана.
        final t = _controller.value * 2.4 - 0.7;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(t - 0.6, -0.4),
            end: Alignment(t + 0.6, 0.4),
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: 0.38),
              Colors.white.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(bounds),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
