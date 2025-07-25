import 'package:flutter/material.dart';

InputDecoration inputDecoration(
  String? label, [
  Icon? prefixIcon,
  Widget? suffixIcon,
]) => InputDecoration(
  labelText: label,
  prefixIcon: prefixIcon,
  suffixIcon: suffixIcon,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: Colors.grey[300]!),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: Colors.grey[300]!),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: Colors.blue),
  ),
  filled: true,
  fillColor: Colors.grey[50],
);
