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
      style: const TextStyle(color: Colors.black87, fontSize: 16, fontFamily: "Quicksanju"),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontFamily: "Quicksand",fontWeight: FontWeight.bold),
        prefixIcon: Icon(icon, color: Colors.deepOrangeAccent),
        prefixText: prefixText,
        prefixStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
          fontFamily: "Quicksanju"
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.deepOrangeAccent, width: 1.6),
        ),
      ),
    );
  }
}
