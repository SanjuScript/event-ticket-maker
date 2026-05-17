import 'package:event_ticket_maker/theme/app_colors.dart';
import 'package:flutter/material.dart';

class TestimonialTag extends StatelessWidget {
  const TestimonialTag({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kOnamGold.withValues(alpha: .12),
            kOnamSaffron.withValues(alpha: .08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kOnamGold.withValues(alpha: .3), width: 1),
      ),
      child: Row(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Limited seats available!',
                  style: TextStyle(
                    color: kOnamGold,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Secure your spot before tickets run out.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
