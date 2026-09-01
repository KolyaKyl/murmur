import 'package:flutter/material.dart';

/// Корона для премиум-контента. Рисуем сами: в наборе Material короны нет,
/// а `workspace_premium` — это медаль, она читается как награда, а не как
/// «платный».
class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key, this.size = 18, this.color});

  static const Color gold = Color(0xFFFFD24A);

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _CrownPainter(color ?? gold)),
    );
  }
}

class _CrownPainter extends CustomPainter {
  _CrownPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..color = color;

    // Три зубца, ножки на общей подставке.
    final path = Path()
      ..moveTo(w * 0.08, h * 0.30)
      ..lineTo(w * 0.30, h * 0.52)
      ..lineTo(w * 0.50, h * 0.18)
      ..lineTo(w * 0.70, h * 0.52)
      ..lineTo(w * 0.92, h * 0.30)
      ..lineTo(w * 0.80, h * 0.76)
      ..lineTo(w * 0.20, h * 0.76)
      ..close();
    canvas.drawPath(path, paint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.20, h * 0.80, w * 0.60, h * 0.13),
        Radius.circular(h * 0.06),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CrownPainter old) => old.color != color;
}
