import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:murmur/features/breathing/models/practice.dart';

/// Цвета фаз. Едины для кольца-схемы и для света на экране практики,
/// поэтому берутся из палитры темы, а не задаются отдельно.
class PhaseColors {
  const PhaseColors._();

  static Color of(BuildContext context, BreathPhase phase) {
    final scheme = Theme.of(context).colorScheme;
    return switch (phase) {
      BreathPhase.inhale => scheme.primary,
      BreathPhase.holdIn => scheme.onPrimaryFixed,
      BreathPhase.exhale => scheme.secondary,
      BreathPhase.holdOut => scheme.onSurfaceVariant,
    };
  }
}

/// Ритм практики кольцом: длина дуги равна секундам фазы.
/// Видно устройство ритма, не читая цифр — у 4·7·8 дуга выдоха вдвое
/// длиннее дуги вдоха.
class PracticeRing extends StatelessWidget {
  const PracticeRing({
    super.key,
    required this.practice,
    this.size = 54,
    this.stroke = 4,
  });

  final BreathingPractice practice;
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          segments: [
            for (final p in practice.phases)
              (seconds: p.seconds, color: PhaseColors.of(context, p.phase))
          ],
          stroke: stroke,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.segments, required this.stroke});

  final List<({int seconds, Color color})> segments;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<int>(0, (a, s) => a + s.seconds);
    if (total == 0) return;

    final rect = Rect.fromLTWH(
        stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    // Небольшой зазор между дугами, иначе на стыке цвета смешиваются в грязь.
    const gap = 0.12;
    var start = -math.pi / 2;

    for (final s in segments) {
      final sweep = 2 * math.pi * s.seconds / total;
      final paint = Paint()
        ..color = s.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start + gap / 2, sweep - gap, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.segments != segments || old.stroke != stroke;
}
