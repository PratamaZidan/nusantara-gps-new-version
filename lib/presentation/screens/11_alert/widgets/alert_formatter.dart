import 'package:intl/intl.dart';

class AlertFormatter {
  AlertFormatter._();

  static String timestamp(String value) {
  try {
    final clean = value.contains('.') ? value.split('.').first : value;
    final dt = DateTime.parse(clean).toLocal();
    return DateFormat('dd MMM yyyy, HH:mm:ss', 'id_ID').format(dt);
  } catch (_) {
    return value;
  }
}
}