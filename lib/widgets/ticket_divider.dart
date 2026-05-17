import 'package:event_ticket_maker/theme/app_colors.dart';
import 'package:flutter/material.dart';

class TicketDivider extends StatelessWidget {
  const TicketDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _halfCircle(left: true),
        Expanded(
          child: LayoutBuilder(
            builder: (_, constraints) {
              final count = (constraints.maxWidth / 12).floor();
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  count,
                  (_) => Container(
                    width: 6,
                    height: 2,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        _halfCircle(left: false),
      ],
    );
  }

  Widget _halfCircle({required bool left}) {
    return Container(
      width: 16,
      height: 32,
      decoration: BoxDecoration(
        color: kOnamDeepGreen.withValues(alpha: .3),
        borderRadius: BorderRadius.horizontal(
          left: left ? Radius.zero : const Radius.circular(16),
          right: left ? const Radius.circular(16) : Radius.zero,
        ),
      ),
    );
  }
}
