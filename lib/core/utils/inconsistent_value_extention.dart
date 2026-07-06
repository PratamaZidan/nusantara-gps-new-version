double normalizeToDouble(dynamic value) {
  if (value == null) return 0.0;
  double parsed;

  if (value is int) {
    parsed = value.toDouble();
  } else if (value is double) {
    parsed = value;
  } else if (value is String) {
    parsed = double.tryParse(value) ?? 0.0;
  } else {
    throw ArgumentError('Invalid numeric value: $value');
  }

  return double.parse(parsed.toStringAsFixed(2));
}

int normalizeToInt(dynamic value) {
  if (value == null) return 0;
  return value is int ? value : int.parse(value.toString());
}

extension NumParser on num? {
  double toDoubleSafe([double fallback = 0.0]) =>
      this == null ? fallback : this!.toDouble();
}

extension KnotsExtension on num {
  double knotsToKmPerHour() {
    return this * 1.852;
  }
}

double stringToDouble(String? value) => double.tryParse(value ?? '') ?? 0.0;
