import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:nusantara_gps/core/app/constant.dart';
import 'package:nusantara_gps/presentation/screens/3_maps/maps_view_model.dart';
import 'package:nusantara_gps/presentation/screens/3_maps/widgets/vehicle_info_bottom_sheet.dart';
import 'package:provider/provider.dart';

class OsmMapWidget extends StatelessWidget {
  const OsmMapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MapsViewModel>();
    const center = LatLng(-7.936738, 112.617612);
    return FlutterMap(
      mapController: viewModel.mapController,
      options: const MapOptions(initialCenter: center, initialZoom: 12),
      children: [
        TileLayer(
          urlTemplate:
              'https://api.maptiler.com/maps/dataviz/{z}/{x}/{y}.png?key=PZUgmEGkFNqDopcTmOms',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.example.nusantara_gps',
        ),
        Consumer<MapsViewModel>(
          builder: (context, viewModel, child) {
            return MarkerLayer(
              markers:
                  viewModel.devices.values.take(50).map((d) {
                    final position = viewModel.filteredPositions[d.id];
                    final status = position?.status ?? VehicleStatus.down;
                    return Marker(
                      point: LatLng(
                        position?.latitude ?? 0,
                        position?.longitude ?? 0,
                      ),
                      width: 200,
                      height: 105,
                      child: GestureDetector(
                        onTap: () async {
                          await viewModel.getAddress(d.id);
                          if (!context.mounted) return;
                          showVehicleSheet(
                            context,
                            d,
                            // position,
                            // viewModel.selectedDeviceAddress,
                          );
                        },
                        child: Column(
                          children: [
                            Transform.rotate(
                              angle: (position?.course ?? 0) * math.pi / 180,
                              child: Image.asset(
                                status.iconAsset,
                                width: 80,
                                height: 80,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                d.name,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList()..add(
                    Marker(
                      point: LatLng(
                        viewModel.currentLatLng?.latitude ?? 0,
                        viewModel.currentLatLng?.longitude ?? 0,
                      ),
                      child: const Icon(
                        Icons.circle,
                        color: Colors.blueAccent,
                        size: 20,
                      ),
                    ),
                  ),
            );
          },
        ),
      ],
    );
  }
}
