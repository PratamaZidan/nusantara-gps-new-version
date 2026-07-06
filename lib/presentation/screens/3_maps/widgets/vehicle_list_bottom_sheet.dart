import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nusantara_gps/core/app/app_color_theme.dart';
import 'package:nusantara_gps/core/app/app_text_theme.dart';
import 'package:nusantara_gps/core/app/constant.dart';
import 'package:nusantara_gps/presentation/screens/3_maps/maps_view_model.dart';
import 'package:nusantara_gps/presentation/widgets/default_padding.dart';
import 'package:nusantara_gps/presentation/widgets/vehicle_status_widget.dart';

void showListVehicleSheet(BuildContext context, MapsViewModel viewModel) {
  final devices = viewModel.devices.values.toList();
  devices.sort((a, b) {
    final aDown = !viewModel.positions.containsKey(a.id);
    final bDown = !viewModel.positions.containsKey(b.id);

    if (aDown == bDown) return 0;
    return aDown ? 1 : -1;
  });
  showModalBottomSheet(
    backgroundColor: Colors.white,
    isScrollControlled: true,
    context: context,
    builder: (ctx) {
      final height = MediaQuery.of(ctx).size.height;
      return SizedBox(
        height: height * 0.4,
        child: Column(
          children: [
            DefaultPadding(
              paddingHorizontal: 16,
              child: Row(
                children: [
                  Spacer(),
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(Icons.close, color: AppColorTheme.gray400),
                  ),
                ],
              ),
            ),
            Text(
              'Daftar Perangkat',
              style: AppTextTheme.titleMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                thickness: 6,
                radius: const Radius.circular(8),
                child: ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    final position = viewModel.positions[device.id];
                    final status = position?.status ?? VehicleStatus.down;
                    return ListTile(
                      title: Text(device.name),
                      subtitle: Text(device.uniqueId),
                      leading: Image.asset(status.iconAsset, width: 56),
                      trailing: VehicleStatusWidget(status: status),
                      onTap: () {
                        if (position == null) {
                          return;
                        }
                        viewModel.recenterCamera(
                          position.latitude,
                          position.longitude,
                        );
                        context.pop();
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
