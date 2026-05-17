import 'package:event_ticket_maker/custom_paint/flower_paint.dart';
import 'package:flutter/material.dart';

class RotatingPookalam extends StatefulWidget {
  final double size;
  const RotatingPookalam({super.key, required this.size});

  @override
  State<RotatingPookalam> createState() => RotatingPookalamState();
}

class RotatingPookalamState extends State<RotatingPookalam>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        size: Size(widget.size, widget.size),
        painter: FloralPainter(_ctrl.value),
      ),
    );
  }
}
