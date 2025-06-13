import 'package:flutter/material.dart';

Color colorStatusInviteFriend(int status) {
  switch (status) {
    case 0:
      return Colors.orange; // Pending
    case 1:
      return Colors.green.shade600; // Sent;
    case -1:
      return Colors.red.shade800; //
    default:
      return Colors.grey.shade700;
  }
}

String formatStatusInviteFriend(int status) {
  switch (status) {
    case 0:
      return 'Pending';
    case 1:
      return 'Approved';
    case -1:
      return 'Rejected';
    default:
      return 'Unknown status';
  }
}
