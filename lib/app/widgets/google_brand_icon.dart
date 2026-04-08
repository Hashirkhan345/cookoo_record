import 'dart:math' as math;

import 'package:flutter/material.dart';

class GoogleBrandIcon extends StatelessWidget {
  const GoogleBrandIcon({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _GoogleBrandPainter()),
    );
  }
}

class _GoogleBrandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = size.width * 0.18;
    final Rect arcRect = Offset.zero & size;
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      arcRect.deflate(strokeWidth / 2),
      _deg(-35),
      _deg(112),
      false,
      paint,
    );

    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      arcRect.deflate(strokeWidth / 2),
      _deg(77),
      _deg(88),
      false,
      paint,
    );

    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      arcRect.deflate(strokeWidth / 2),
      _deg(165),
      _deg(92),
      false,
      paint,
    );

    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      arcRect.deflate(strokeWidth / 2),
      _deg(257),
      _deg(82),
      false,
      paint,
    );

    final Paint barPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF4285F4);

    final double centerY = size.height / 2;
    final double startX = size.width * 0.54;
    final double endX = size.width * 0.88;
    canvas.drawLine(Offset(startX, centerY), Offset(endX, centerY), barPaint);
  }

  double _deg(double degrees) => degrees * math.pi / 180;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
