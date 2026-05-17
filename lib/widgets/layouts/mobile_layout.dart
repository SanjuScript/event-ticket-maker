import 'package:event_ticket_maker/widgets/booking_info_card.dart';
import 'package:event_ticket_maker/widgets/event_info_panel.dart';
import 'package:flutter/material.dart';

class MobileLayout extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final VoidCallback onPay;

  const MobileLayout({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        children: [
          EventInfoPanel(),
          const SizedBox(height: 24),
          BookingFormCard(
            nameController: nameController,
            phoneController: phoneController,
            onPay: onPay,
          ),
        ],
      ),
    );
  }
}
