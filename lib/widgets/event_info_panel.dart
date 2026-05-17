import 'package:event_ticket_maker/helper/responsive_checker.dart';
import 'package:event_ticket_maker/theme/app_colors.dart';
import 'package:event_ticket_maker/widgets/highlight_card.dart';
import 'package:event_ticket_maker/widgets/info_row.dart';
import 'package:event_ticket_maker/widgets/rotating_flowers.dart';
import 'package:event_ticket_maker/widgets/testimonial_tag.dart';
import 'package:flutter/material.dart';

class EventInfoPanel extends StatelessWidget {
  const EventInfoPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveChecker.isDesktop(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            RotatingPookalam(size: isDesktop ? 90 : 70),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: kOnamSaffron.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: kOnamSaffron.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      '✦  LIVE EVENT  ✦',
                      style: TextStyle(
                        color: kOnamGold,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Onam\nCelebration',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isDesktop ? 42 : 34,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Text(
                    '2025',
                    style: TextStyle(
                      color: kOnamGold,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      height: 0.9,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // Event Details Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Event Details',
                style: TextStyle(
                  color: kOnamGold,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 14),
              InfoRow(
                icon: Icons.calendar_today_rounded,
                text: 'Thursday, 28 August 2025',
                iconColor: kOnamGold,
              ),
              InfoRow(
                icon: Icons.location_on_rounded,
                text: 'Krupanidhi College, Bengaluru',
                iconColor: kOnamLightGreen,
              ),
              InfoRow(
                icon: Icons.access_time_rounded,
                text: 'Gates open at 10:00 AM',
                iconColor: kOnamSaffron,
              ),
              InfoRow(
                icon: Icons.people_alt_rounded,
                text: 'Open to all students & families',
                iconColor: Colors.lightBlueAccent,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        HighlightsGrid(),

        if (isDesktop) ...[const SizedBox(height: 24), TestimonialTag()],
      ],
    );
  }
}
