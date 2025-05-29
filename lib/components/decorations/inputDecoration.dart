import 'package:flutter/material.dart';

InputDecoration inputDecoration(String label) => InputDecoration(
  labelText: label,
  filled: true,
  fillColor: Colors.white,
  enabledBorder: const OutlineInputBorder(
    // width: 0.0 produces a thin "hairline" border
    borderSide: BorderSide(color: Colors.grey, width: 0.0),
  ),
  border: OutlineInputBorder(),
);
