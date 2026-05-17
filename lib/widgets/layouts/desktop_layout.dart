import 'package:event_ticket_maker/widgets/booking_info_card.dart';
import 'package:event_ticket_maker/widgets/event_info_panel.dart';
import 'package:flutter/material.dart';

class DesktopLayout extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final VoidCallback onPay;

  const DesktopLayout({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: EventInfoPanel()),
              const SizedBox(width: 32),
              Expanded(
                flex: 4,
                child: BookingFormCard(
                  nameController: nameController,
                  phoneController: phoneController,
                  onPay: onPay,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
