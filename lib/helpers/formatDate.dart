import 'package:intl/intl.dart';

String formatDate(String? date) {
  if (date == null || date.isEmpty) return 'N/A';
  try {
    final parsedDate = DateTime.parse(date);
    return DateFormat('MM/dd/yyyy').format(parsedDate);
  } catch (e) {
    // print('Error parsing date: $e');
    return date;
  }
}
