import 'package:intl/intl.dart';

String formatDate(String? date, {String format = 'MM/dd/yyyy'}) {
  if (date == null || date.isEmpty) return 'N/A';
  try {
    final parsedDate = DateTime.parse(date);
    return DateFormat(format).format(parsedDate);
  } catch (e) {
    // print('Error parsing date: $e');
    return date;
  }
}
