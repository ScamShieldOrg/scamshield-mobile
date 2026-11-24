import 'dart:math' as math;

import 'package:flutter/material.dart';

class GoogleLogoIcon extends StatelessWidget {
  const GoogleLogoIcon({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.19;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Top-left red arc
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -math.pi * 0.85, math.pi * 0.58, false, paint);

    // Left yellow arc
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, math.pi * 0.72, math.pi * 0.44, false, paint);

    // Bottom arc
    paint.color = const Color(0xFF008CC7);
    canvas.drawArc(rect, math.pi * 0.18, math.pi * 0.55, false, paint);

    // Right blue arc
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -math.pi * 0.04, math.pi * 0.25, false, paint);

    // Horizontal center bar of the 'G'
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final barHeight = stroke * 0.96;
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.50,
        (size.height - barHeight) / 2,
        size.width * 0.46,
        barHeight,
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
