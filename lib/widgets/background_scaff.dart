import 'package:event_ticket_maker/custom_paint/grid_paint.dart';
import 'package:event_ticket_maker/theme/app_colors.dart';
import 'package:flutter/material.dart';

class Background extends StatelessWidget {
  const Background({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A2015), Color(0xFF0D2818), Color(0xFF1B3A1F)],
            ),
          ),
        ),
        Positioned(
          top: -120,
          right: -80,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  kOnamSaffron.withValues(alpha: 0.18),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Bottom glow
        Positioned(
          bottom: -100,
          left: -60,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [kOnamGold.withValues(alpha: 0.12), Colors.transparent],
              ),
            ),
          ),
        ),
        // Subtle grid texture
        Opacity(
          opacity: 0.04,
          child: CustomPaint(
            size: Size(
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height,
            ),
            painter: GridPainter(),
          ),
        ),
      ],
    );
  }
}
