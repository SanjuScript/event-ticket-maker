import 'package:flutter/material.dart';

class PremiumTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final String? prefixText;

  const PremiumTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.prefixText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        fontFamily: 'Quicksand',
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.blueGrey,
          fontFamily: "Quicksand",
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, color:  Color(0xFF0052D4)),

        prefixText: prefixText,
        prefixStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
          fontFamily: "Quicksand",
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: Colors.white,  
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.blueGrey.shade200, width: 1.4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 1.8),
        ),
      ),
    );
  }
}
