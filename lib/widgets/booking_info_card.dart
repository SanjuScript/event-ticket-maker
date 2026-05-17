import 'dart:ui';

import 'package:event_ticket_maker/provider/select_image.dart';
import 'package:event_ticket_maker/theme/app_colors.dart';
import 'package:event_ticket_maker/widgets/buttons/buy_button.dart';
import 'package:event_ticket_maker/widgets/developer_info.dart';
import 'package:event_ticket_maker/widgets/premium_image_picker.dart';
import 'package:event_ticket_maker/widgets/text_fields.dart';
import 'package:event_ticket_maker/widgets/ticket_divider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BookingFormCard extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final VoidCallback onPay;

  const BookingFormCard({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: .15),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      kOnamSaffron.withValues(alpha: .25),
                      kOnamGold.withValues(alpha: .15),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ADMISSION TICKET',
                            style: TextStyle(
                              color: kOnamGold,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Book Your Seat',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: kOnamSaffron,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '₹705',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const TicketDivider(),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Details',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 14),
                    GlassField(
                      controller: nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 12),
                    GlassField(
                      controller: phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      prefixText: '+91 ',
                    ),

                    const SizedBox(height: 20),

                    Consumer<ImageUploadProvider>(
                      builder: (context, imgProvider, _) {
                        final imageSelected = kIsWeb
                            ? imgProvider.webImage != null
                            : imgProvider.selectedImageFile != null;
                        return PremiumImagePicker(
                          imageSelected: imageSelected,
                          userProvider: imgProvider,
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    AnimatedBuyButton(onPressed: onPay),

                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 13,
                          color: Colors.white38,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Secured by Razorpay  •  UPI only',
                          style: TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    const DeveloperInfo(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
