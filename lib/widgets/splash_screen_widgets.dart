import 'package:event_ticket_maker/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';

class LiveBadge extends StatefulWidget {
  const LiveBadge({super.key});
  @override
  State<LiveBadge> createState() => LiveBadgeState();
}

class LiveBadgeState extends State<LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kNeonCyan.withOpacity(0.45), width: 1),
        boxShadow: [
          BoxShadow(color: kNeonCyan.withOpacity(0.2), blurRadius: 14),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kNeonMagenta,
                boxShadow: [
                  BoxShadow(
                    color: kNeonMagenta.withOpacity(0.4 + _ctrl.value * 0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'LIVE CONCERT',
            style: TextStyle(
              color: kNeonCyan,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.5,
            ),
          ),
        ],
      ),
    );
  }
}

class NeonCTAButton extends StatefulWidget {
  const NeonCTAButton({super.key});
  @override
  State<NeonCTAButton> createState() => NeonCTAButtonState();
}

class NeonCTAButtonState extends State<NeonCTAButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _hover = false;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          // Navigator.pushReplacement(
          //   context,
          //   PageRouteBuilder(
          //     pageBuilder: (_, a, __) => const LoginScreen(),
          //     transitionsBuilder: (_, a, __, child) =>
          //         FadeTransition(opacity: a, child: child),
          //     transitionDuration: const Duration(milliseconds: 500),
          //   ),
          // );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        },
        onTapCancel: () => _ctrl.reverse(),
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 1.0,
            end: 0.96,
          ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _hover
                    ? [kNeonMagenta, kPurple, kNeonCyan]
                    : [kNeonMagenta, kPurple],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: kNeonMagenta.withOpacity(_hover ? 0.65 : 0.40),
                  blurRadius: _hover ? 36 : 18,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: kPurple.withOpacity(0.30),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.confirmation_num_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Grab Your Tickets',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  transform: Matrix4.translationValues(_hover ? 5 : 0, 0, 0),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StatChip extends StatelessWidget {
  final String value, label;
  final Color color;
  const StatChip({
    required this.value,
    required this.label,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
          shadows: [Shadow(color: color.withOpacity(0.6), blurRadius: 12)],
        ),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.45),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

class FeaturePill extends StatelessWidget {
  final String emoji, label;
  const FeaturePill({required this.emoji, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withOpacity(0.10), width: 1),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 15)),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.75),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

class InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const InfoChip({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 15),
      ),

      const SizedBox(width: 8), // perfect spacing

      Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.82),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}
