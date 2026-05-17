import 'package:event_ticket_maker/theme/app_colors.dart';
import 'package:flutter/material.dart';

class GlassField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? prefixText;

  const GlassField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.prefixText,
  });

  @override
  State<GlassField> createState() => GlassFieldState();
}

class GlassFieldState extends State<GlassField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: _focused ? 0.14 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _focused
                ? kOnamGold.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.2),
            width: _focused ? 1.5 : 1,
          ),
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color: kOnamGold.withValues(alpha: 0.15),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: TextField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              widget.icon,
              color: _focused ? kOnamGold : Colors.white54,
              size: 20,
            ),
            prefix: widget.prefixText != null
                ? Text(
                    widget.prefixText!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }
}
