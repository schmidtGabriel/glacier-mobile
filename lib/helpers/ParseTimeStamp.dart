import 'package:cloud_firestore/cloud_firestore.dart';

final months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String formatTimestamp(dynamic timestamp, {bool isShortFormat = false}) {
  try {
    DateTime date;
    if (timestamp is String) {
      date = DateTime.parse(timestamp);
    } else if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else {
      return 'Invalid date';
    }

    if (isShortFormat) {
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }

    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  } catch (e) {
    return 'Invalid date';
  }
}
