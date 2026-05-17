import 'package:flutter/material.dart';

class ResponsiveChecker {
  static bool isDesktop(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width >= 768;
}
