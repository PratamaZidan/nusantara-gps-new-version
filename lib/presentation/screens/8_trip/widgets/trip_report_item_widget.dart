import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nusantara_gps/core/app/app_color_theme.dart';
import 'package:nusantara_gps/core/app/app_text_theme.dart';
import 'package:nusantara_gps/data/models/daily_report_model.dart';

class TripReportItemWidget extends StatelessWidget {
  final DailyReportModel report;
  const TripReportItemWidget({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Parse report.date ("2026-06-10") jadi DateTime
        // lalu kirim sebagai query parameter start/end ke route-history
        final date = DateTime.tryParse(report.date);
        final start = date != null
            ? DateTime(date.year, date.month, date.day, 0, 0, 0)
            : DateTime.now();
        final end = date != null
            ? DateTime(date.year, date.month, date.day, 23, 59, 59)
            : DateTime.now();

        context.pushNamed(
          'route-history',
          pathParameters: {'id': report.deviceId.toString()},
          queryParameters: {
            'start': start.toIso8601String(),
            'end': end.toIso8601String(),
          },
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColorTheme.gray200),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Header Kendaraan
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColorTheme.primary,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      report.device,
                      style: AppTextTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: report.hasTrip
                          ? Colors.white.withAlpha(40)
                          : Colors.red.withAlpha(80),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      report.hasTrip ? 'Ada Perjalanan' : 'Tidak Bergerak',
                      style: AppTextTheme.bodySmall.copyWith(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Body Statistik
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Jarak & Kecepatan
                  Row(
                    children: [
                      _StatItem(
                        icon: Icons.route_rounded,
                        label: 'Jarak',
                        value: '${report.distanceKm.toStringAsFixed(2)} km',
                      ),
                      const SizedBox(width: 12),
                      _StatItem(
                        icon: Icons.speed_rounded,
                        label: 'Kec. Rata-rata',
                        value: '${report.speedAvg.toStringAsFixed(1)} km/h',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Durasi Jalan & Berhenti
                  Row(
                    children: [
                      _StatItem(
                        icon: Icons.play_circle_outline_rounded,
                        label: 'Durasi Jalan',
                        value: report.run,
                        iconColor: AppColorTheme.primary,
                      ),
                      const SizedBox(width: 12),
                      _StatItem(
                        icon: Icons.pause_circle_outline_rounded,
                        label: 'Durasi Berhenti',
                        value: report.stop,
                        iconColor: Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Odometer
                  Row(
                    children: [
                      _StatItem(
                        icon: Icons.av_timer_rounded,
                        label: 'Odometer Awal',
                        value: '${report.firstOdometerKm.toStringAsFixed(2)} km',
                      ),
                      const SizedBox(width: 12),
                      _StatItem(
                        icon: Icons.av_timer_rounded,
                        label: 'Odometer Akhir',
                        value: '${report.lastOdometerKm.toStringAsFixed(2)} km',
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Waktu Mulai & Selesai
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 14, color: AppColorTheme.gray400),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${report.firstTs}  →  ${report.lastTs}',
                          style: AppTextTheme.bodySmall.copyWith(
                            color: AppColorTheme.gray500,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Alamat Terakhir (jika ada)
                  if (report.lastAddr != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 14, color: AppColorTheme.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            report.lastAddr!,
                            style: AppTextTheme.bodySmall.copyWith(
                              color: AppColorTheme.gray500,
                              fontSize: 11,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor ?? AppColorTheme.gray400),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextTheme.bodySmall.copyWith(
                    color: AppColorTheme.gray400,
                    fontSize: 11,
                  ),
                ),
                Text(
                  value,
                  style: AppTextTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColorTheme.gray800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}