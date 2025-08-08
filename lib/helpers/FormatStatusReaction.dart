import 'package:flutter/material.dart';

Color colorStatusReaction(String status) {
  switch (status) {
    case '0':
      return Colors.orange; // Pending
    case '1':
      return Colors.blue.shade600; // Sent;
    case '10':
      return Colors.green.shade700; //
    case '-10':
      return Colors.red.shade800; //
    default:
      return Colors.grey.shade700;
  }
}

String formatStatusReaction(String status) {
  switch (status) {
    case '0':
      return 'Pending';
    case '1':
      return 'Recorded';
    case '10':
      return 'Finished';
    case '-10':
      return 'Rejected';
    default:
      return 'Unknown status';
  }
}
