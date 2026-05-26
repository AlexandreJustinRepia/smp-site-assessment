import 'package:flutter/material.dart';

typedef InputDecorationBuilder =
    InputDecoration Function(
      String label, {
      IconData? icon,
      Widget? suffix,
      String? hintText,
    });
