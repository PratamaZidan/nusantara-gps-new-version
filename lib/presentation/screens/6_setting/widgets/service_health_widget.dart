import 'package:flutter/material.dart';
import 'package:nusantara_gps/core/service/service_health_store.dart';
import 'package:nusantara_gps/core/app/app_color_theme.dart';
import 'package:nusantara_gps/core/app/app_text_theme.dart';
import 'package:nusantara_gps/core/service/alert_polling_service.dart';

class ServiceHealthWidget extends StatefulWidget {
  const ServiceHealthWidget({super.key});

  @override
  State<ServiceHealthWidget> createState() => _ServiceHealthWidgetState();
}

class _ServiceHealthWidgetState extends State<ServiceHealthWidget> {
  ServiceHealthSnapshot? _snapshot;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _onRefreshTap() async {
    if (_loading) return;
  setState(() => _loading = true);

  // Jika service mati, restart dulu sebelum refresh
  final snap = await ServiceHealthStore.instance.getSnapshot();
    if (snap != null && !snap.isHealthy) {
      try {
        await AlertPollingService.instance.stopService();
        await Future.delayed(const Duration(seconds: 2));
        await AlertPollingService.instance.initAndStart();
        await Future.delayed(const Duration(seconds: 3));
      } catch (_) {}
    }

    await _load();
  }

  Future<void> _load() async {
    final snap = await ServiceHealthStore.instance.getSnapshot();
    if (mounted) setState(() { _snapshot = snap; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Status Monitoring', style: AppTextTheme.labelLarge),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: _onRefreshTap,
              tooltip: 'Refresh',
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_snapshot == null)
          const Text('Tidak ada data')
        else
          _buildCard(_snapshot!),
      ],
    );
  }

  Widget _buildCard(ServiceHealthSnapshot snap) {
    final healthy = snap.isHealthy;
    return Container(
      decoration: BoxDecoration(
        color: healthy
            ? Colors.green.shade50
            : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: healthy ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                healthy ? Icons.check_circle_outline : Icons.warning_amber_outlined,
                color: healthy ? AppColorTheme.primary : Colors.red.shade700,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                healthy ? 'Service Berjalan Normal' : 'Service Mungkin Mati',
                style: AppTextTheme.labelMedium.copyWith(
                  color: healthy ? AppColorTheme.primary : Colors.red.shade700,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          _row(Icons.timer_outlined, 'Uptime', snap.serviceUptime),
          _row(Icons.notifications_outlined,'Cek Alert Terakhir', _fmt(snap.lastAlertCheck)),
          _row(Icons.my_location_outlined, 'Cek Geofence Terakhir', _fmt(snap.lastGeofenceCheck)),
          _row(Icons.repeat_outlined, 'Total Cek Alert', '${snap.alertCheckCount}×'),
          _row(Icons.repeat_outlined, 'Total Cek Geofence', '${snap.geofenceCheckCount}×'),
          if (snap.lastError != null) ...[
            const Divider(height: 16),
            _row(Icons.error_outline, 'Error Terakhir', snap.lastError!, isError: true),
          ],
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: isError ? Colors.red : Colors.grey.shade600),
          const SizedBox(width: 6),
          Text('$label: ', style: AppTextTheme.bodySmall.copyWith(color: Colors.grey.shade600)),
          Expanded(
            child: Text(
              value,
              style: AppTextTheme.bodySmall.copyWith(
                color: isError ? Colors.red.shade700 : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(String? iso) {
    if (iso == null) return 'Belum pernah';
    final dt  = DateTime.tryParse(iso);
    if (dt == null) return '-';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24)   return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }
}