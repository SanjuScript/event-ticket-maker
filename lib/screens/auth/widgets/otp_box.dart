import 'package:event_ticket_maker/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtpBox extends StatelessWidget {
  final TextEditingController ctrl;
  final FocusNode focus;
  final bool filled, focused;
  const OtpBox({
    super.key,
    required this.ctrl,
    required this.focus,
    required this.filled,
    required this.focused,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 48,
      height: 56,
      decoration: BoxDecoration(
        color: focused
            ? kNeonCyan.withOpacity(0.08)
            : filled
            ? Colors.white.withOpacity(0.08)
            : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: focused
              ? kNeonCyan
              : filled
              ? kNeonMagenta.withOpacity(0.7)
              : Colors.white.withOpacity(0.12),
          width: focused ? 1.5 : 1,
        ),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: kNeonCyan.withOpacity(0.25),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: ctrl,
        focusNode: focus,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        style: TextStyle(
          color: focused ? kNeonCyan : Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
        ),
      ),
    );
  }
}
