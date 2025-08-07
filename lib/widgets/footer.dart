import 'package:flutter/material.dart';

Widget showFooterWidget() {
  return Positioned(
    bottom: 20,
    left: 0,
    right: 0,
    child: Center(
      child: Text(
        '© Onam Committee 2025 • All rights reserved',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
}
