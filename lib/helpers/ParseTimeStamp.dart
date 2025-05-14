import 'package:cloud_firestore/cloud_firestore.dart';

String formatTimestamp(dynamic timestamp) {
  try {
    DateTime date;
    if (timestamp is String) {
      date = DateTime.parse(timestamp);
    } else if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else {
      return 'Invalid date';
    }

    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  } catch (e) {
    return 'Invalid date';
  }
}
