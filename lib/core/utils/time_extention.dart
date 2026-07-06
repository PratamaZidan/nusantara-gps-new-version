String timeAgoId(
  DateTime date, {
  DateTime? reference,
  bool numeric =
      true,
}) {
  final now = reference ?? DateTime.now();
  Duration diff = now.difference(date);
  final isPast = diff.inMilliseconds >= 0;
  final abs = diff.abs();

  final seconds = abs.inSeconds;
  final minutes = abs.inMinutes;
  final hours = abs.inHours;
  final days = abs.inDays;

  // Pembulatan kasar untuk bulan/tahun
  final months = (days / 30).floor();
  final years = (days / 365).floor();

  String past(String s) => "$s yang lalu";
  String future(String s) => "dalam $s";

  String build() {
    // < 45 detik
    if (seconds < 45) {
      final base = numeric
          ? "${seconds == 0 ? 1 : seconds} detik"
          : (isPast ? "baru saja" : "sebentar lagi");
      return isPast
          ? (numeric ? past(base) : base)
          : (numeric ? future(base) : base);
    }

    // < 90 detik ≈ 1 menit
    if (seconds < 90) return isPast ? past("1 menit") : future("1 menit");

    // < 45 menit
    if (minutes < 45) {
      return isPast ? past("$minutes menit") : future("$minutes menit");
    }

    // < 90 menit ≈ 1 jam
    if (minutes < 90) return isPast ? past("1 jam") : future("1 jam");

    // < 24 jam
    if (hours < 24) return isPast ? past("$hours jam") : future("$hours jam");

    // < ~42 jam ≈ 1 hari
    if (hours < 42) return isPast ? past("1 hari") : future("1 hari");

    // < 30 hari
    if (days < 30) return isPast ? past("$days hari") : future("$days hari");

    // ~1 bulan
    if (days < 45) return isPast ? past("1 bulan") : future("1 bulan");

    // < 12 bulan
    if (days < 365) {
      return isPast ? past("$months bulan") : future("$months bulan");
    }

    // ~1 tahun
    if (days < 545) return isPast ? past("1 tahun") : future("1 tahun");

    // >= 2 tahun
    return isPast ? past("$years tahun") : future("$years tahun");
  }

  return build();
}

/// Optional: extension supaya enak dipakai dari DateTime
extension TimeAgoIdExt on DateTime {
  String timeAgo({DateTime? reference, bool numeric = true}) =>
      timeAgoId(this, reference: reference, numeric: numeric);
}

double msToMin(int milliseconds) {
  return milliseconds / 1000 / 60;
}
