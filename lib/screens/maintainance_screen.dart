import 'package:flutter/material.dart';
import 'package:event_ticket_maker/theme/site_theme.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  static const _bg = Color(0xFF0A0A0A);
  static const _muted = Color(0xFF888888);
  static const _white = Color(0xFFF5F5F0);

  @override
  Widget build(BuildContext context) {
    final accent = context.siteAccent;

    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                border: Border.all(color: accent.withOpacity(0.3)),
              ),
              child: Icon(Icons.construction_outlined, color: accent, size: 28),
            ),
            const SizedBox(height: 24),
            const Text(
              'UNDER MAINTENANCE',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: _white,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "We're making things better. Check back soon.",
              style: TextStyle(color: _muted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
