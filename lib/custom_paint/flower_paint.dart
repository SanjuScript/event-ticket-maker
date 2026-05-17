import 'dart:math' as math;

import 'package:event_ticket_maker/theme/app_colors.dart';
import 'package:flutter/material.dart';

class FloralPainter extends CustomPainter {
  final double progress;
  FloralPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final petals = 8;
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = math.min(size.width, size.height) * 0.38;

    for (int i = 0; i < petals; i++) {
      final angle = (i / petals) * 2 * math.pi + progress * 2 * math.pi;
      final px = centerX + radius * 0.55 * math.cos(angle);
      final py = centerY + radius * 0.55 * math.sin(angle);

      paint.color = i.isEven
          ? kOnamSaffron.withValues(alpha: .85)
          : kOnamGold.withValues(alpha: .85);

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(px, py),
          width: radius * 0.55,
          height: radius * 0.32,
        ),
        paint,
      );
    }

    // Center circle
    paint.color = kOnamGold;
    canvas.drawCircle(Offset(centerX, centerY), radius * 0.18, paint);
    paint.color = kOnamSaffron;
    canvas.drawCircle(Offset(centerX, centerY), radius * 0.10, paint);
  }

  @override
  bool shouldRepaint(FloralPainter old) => old.progress != progress;
}
