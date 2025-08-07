import 'package:flutter/material.dart';

class StringHelper {
  static String? validateFields(String name, String phone, RegExp phoneRegex) {
    if (name.isEmpty || phone.isEmpty) return "Please fill all fields";
    if (name.length < 3) return "Please enter a valid full name";
    if (!phoneRegex.hasMatch(phone)) {
      return "Enter a valid 10-digit phone number";
    }
    return null;
  }

  static void showError(String message, BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
