import 'package:event_ticket_maker/theme/app_colors.dart';
import 'package:flutter/material.dart';

class HighlightsGrid extends StatelessWidget {
  static const _items = [
    (Icons.music_note_rounded, 'Cultural\nPerformances', kOnamSaffron),
    (Icons.restaurant_rounded, 'Sadya\nFeast', kOnamGreen),
    (Icons.emoji_events_rounded, 'Exciting\nPrizes', kOnamGold),
    (Icons.photo_camera_rounded, 'Photo\nBooth', Colors.lightBlue),
  ];

  const HighlightsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.95,
      children: _items
          .map(
            (item) => Container(
              decoration: BoxDecoration(
                color: item.$3.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: item.$3.withValues(alpha: .25),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.$1, color: item.$3, size: 26),
                  const SizedBox(height: 6),
                  Text(
                    item.$2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .8),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
