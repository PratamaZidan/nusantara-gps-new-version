import 'package:intl/intl.dart';

extension PreviousDateIso8601 on DateTime {
  String toPreviousDayIso8601At17UTC() {
    final previousDay = DateTime.utc(year, month, day - 1, 17, 0, 0);
    return previousDay.toIso8601String().replaceFirst('.000Z', 'Z');
  }

  String toTodayIso8601At1659UTC() {
    final today = DateTime.utc(year, month, day, 16, 59, 0);
    return today.toIso8601String().replaceFirst('.000Z', 'Z');
  }

  String toEarlyDay() {
    final today = DateTime(year, month, day, 0, 0, 0);
    final formatter = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");
    return formatter.format(today);
  }

  String toEndDay() {
    final today = DateTime(year, month, day, 23, 59, 59);
    final formatter = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");
    return formatter.format(today);
  }

  String toCustomUtcISO8601() {
    final utc = toUtc();
    final formatter = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");
    return formatter.format(utc);
  }

  String toCustomISO8601() {
    final formatter = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");
    return formatter.format(this);
  }

  String toTraccarStandartFormat() {
    final formatter = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");
    return formatter.format(this);
  }

  String toIndonesianDate() {
    final formatter = DateFormat('dd MMMM yyyy');
    return formatter.format(this);
  }

  String toIndonesianDateTime() {
    final formatter = DateFormat('dd MMMM yyyy, HH:mm');
    return formatter.format(this);
  }

  String toSimpleFormat() {
    final formatter = DateFormat('dd MMM');
    return formatter.format(this);
  }

  String toddMMMyyyyFormat() {
    final formatter = DateFormat('dd MMM yyyy');
    return formatter.format(this);
  }

  String toListlinesFormat() {
    final formatter = DateFormat('dd-MM-yyyy HH:mm:ss');
    return formatter.format(this);
  }

  String toListlinesEarlyDay() {
    final today = DateTime(year, month, day, 0, 0, 0);
    final formatter = DateFormat('dd-MM-yyyy HH:mm:ss');
    return formatter.format(today);
  }

  String toListlinesEndDay() {
    final today = DateTime(year, month, day, 23, 59, 59);
    final formatter = DateFormat('dd-MM-yyyy HH:mm:ss');
    return formatter.format(today);
  }
}
