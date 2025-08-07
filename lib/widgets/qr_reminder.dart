import 'package:flutter/material.dart';

Widget qrReminder() {
  return const Padding(
    padding: EdgeInsets.only(top: 24.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 6),
        Text(
          'Note: After payment, a unique QR code will be generated.\nYou must show it at the event gate for entry.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.white70),
        ),
      ],
    ),
  );
}
