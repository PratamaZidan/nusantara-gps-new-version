import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nusantara_gps/core/app/app_color_theme.dart';
import 'package:nusantara_gps/core/app/app_text_theme.dart';
import 'package:nusantara_gps/core/config/result.dart';
import 'package:nusantara_gps/core/service/geofence_event_store.dart';
import 'package:nusantara_gps/data/models/alert_model.dart';
import 'package:nusantara_gps/presentation/screens/11_alert/alert_view_model.dart';
import 'package:nusantara_gps/presentation/screens/11_alert/widgets/alert_formatter.dart';
import 'package:provider/provider.dart';

class AlertScreen extends StatefulWidget {
  const AlertScreen({super.key});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlertViewModel>().loadAlerts();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        context.read<AlertViewModel>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AlertViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Alert Kendaraan',
          style: AppTextTheme.titleMedium,
        ),
        centerTitle: true,
      ),
      body: switch (vm.state) {
        ResultState.loading =>
          const Center(child: CupertinoActivityIndicator()),
        ResultState.error => _ErrorView(
            message: vm.errorMessage ?? 'Terjadi kesalahan',
            onRetry: vm.loadAlerts,
          ),
        _ => _buildNotificationList(vm),
      },
    );
  }

  Widget _buildNotificationList(AlertViewModel vm) {
    final notifications = [
      ...vm.alerts,
      ...vm.geofenceEvents,
    ];

    notifications.sort((a, b) {
      final dateA = DateTime.tryParse(
        a is AlertModel
            ? a.timestamp
            : (a as GeofenceEventModel).timestamp,
      ) ?? DateTime(2000);

      final dateB = DateTime.tryParse(
        b is AlertModel
            ? b.timestamp
            : (b as GeofenceEventModel).timestamp,
      ) ?? DateTime(2000);

      return dateB.compareTo(dateA);
    });

    if (notifications.isEmpty) {
      return const _EmptyView(
        message: 'Belum ada notifikasi',
      );
    }

    return RefreshIndicator(
      onRefresh: vm.refresh,
      color: AppColorTheme.primary,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: notifications.length +
            (vm.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => Divider(
          height: 1,
          indent: 72,
          color: AppColorTheme.gray100,
        ),
        itemBuilder: (_, index) {
          if (index == notifications.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CupertinoActivityIndicator(),
              ),
            );
          }

          final item = notifications[index];

          if (item is AlertModel) {
            return _AlertCard(alert: item);
          }

          if (item is GeofenceEventModel) {
            return _GeofenceEventCard(event: item);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// Alert Card
class _AlertCard extends StatelessWidget {
  final AlertModel alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: _AlertIcon(type: alert.alertType),
      title: Text(
        alert.deviceName,
        style:
            AppTextTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            alert.formattedMessage,
            style: AppTextTheme.bodySmall
                ?.copyWith(color: AppColorTheme.gray600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.access_time_filled_rounded,
                size: 12, color: AppColorTheme.gray400),
            const SizedBox(width: 4),
            Text(
              AlertFormatter.timestamp(alert.timestamp),
              style: AppTextTheme.bodySmall?.copyWith(
                  color: AppColorTheme.gray400, fontSize: 11),
            ),
          ]),
        ],
      ),
    );
  }
}

// Geofence Event Card
class _GeofenceEventCard extends StatelessWidget {
  final GeofenceEventModel event;
  const _GeofenceEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final isEntering = event.isEntering;
    final color =
        isEntering ? Colors.green.shade600 : Colors.orange.shade700;
    final icon =
        isEntering ? Icons.login_rounded : Icons.logout_rounded;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
            color: color.withAlpha(25), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        event.deviceName,
        style:
            AppTextTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            event.formattedMessage,
            style: AppTextTheme.bodySmall
                ?.copyWith(color: AppColorTheme.gray600),
          ),
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.access_time_filled_rounded,
                size: 12, color: AppColorTheme.gray400),
            const SizedBox(width: 4),
            Text(
              AlertFormatter.timestamp(event.timestamp),
              style: AppTextTheme.bodySmall?.copyWith(
                  color: AppColorTheme.gray400, fontSize: 11),
            ),
          ]),
        ],
      ),
    );
  }
}

// Alert Icon
class _AlertIcon extends StatelessWidget {
  final String type;
  const _AlertIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _resolveIconAndColor(type);
    return Container(
      width: 44,
      height: 44,
      decoration:
          BoxDecoration(color: color.withAlpha(25), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 22),
    );
  }

  (IconData, Color) _resolveIconAndColor(String type) {
    switch (type) {
      case 'Benturan':
        return (Icons.warning_amber_rounded, Colors.orange);
      case 'Sambungan Terputus':
        return (Icons.power_off_rounded, Colors.red);
      case 'SOS':
        return (Icons.sos_rounded, Colors.red);
      case 'Kecepatan Berlebih':
        return (Icons.speed_rounded, Colors.deepOrange);
      case 'Geofence':
        return (Icons.fence_rounded, AppColorTheme.primary);
      default:
        return (Icons.notifications_rounded, AppColorTheme.gray500);
    }
  }
}

class _EmptyView extends StatelessWidget {
  final String message;
  const _EmptyView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 64, color: AppColorTheme.gray300),
          const SizedBox(height: 16),
          Text(message,
              style: AppTextTheme.titleMedium
                  ?.copyWith(color: AppColorTheme.gray500)),
          const SizedBox(height: 8),
          Text('Semua kendaraan dalam kondisi normal',
              style: AppTextTheme.bodySmall
                  ?.copyWith(color: AppColorTheme.gray400)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 64, color: AppColorTheme.red500),
            const SizedBox(height: 16),
            Text(message,
                style: AppTextTheme.bodyMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorTheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}