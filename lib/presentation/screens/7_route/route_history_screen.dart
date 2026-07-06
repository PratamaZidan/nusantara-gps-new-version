import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nusantara_gps/core/app/app_color_theme.dart';
import 'package:nusantara_gps/core/app/app_text_theme.dart';
import 'package:nusantara_gps/core/config/result.dart';
import 'package:nusantara_gps/core/utils/date_time_extention.dart';
import 'package:nusantara_gps/presentation/screens/7_route/route_history_view_model.dart';
import 'package:nusantara_gps/presentation/widgets/default_error_widget.dart';
import 'package:nusantara_gps/presentation/widgets/default_padding.dart';
import 'package:provider/provider.dart';

class RouteHistoryScreen extends StatelessWidget {
  final int vehicleId;
  const RouteHistoryScreen({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        title: Text("Record Perjalanan", style: AppTextTheme.titleMedium),
      ),
      body: SafeArea(
        child: Consumer<RouteHistoryViewModel>(
          builder: (context, viewModel, child) {
            switch (viewModel.loadTripPoints) {
              case ResultState.loading:
                return Center(child: CupertinoActivityIndicator());
              case ResultState.success:
                final firstPoint = viewModel.tripPoints.first;
                final initialCamera = CameraPosition(
                  target: LatLng(firstPoint.latitude, firstPoint.longitude),
                  zoom: 15,
                );
                return Stack(
                  children: [

                    // Peta
                    GoogleMap(
                      zoomControlsEnabled: false,
                      initialCameraPosition: initialCamera,
                      onMapCreated: (controller) {
                        viewModel.setMapController(controller);
                      },
                      polylines: viewModel.polylines,
                      style: viewModel.mapStyle,
                      markers: _buildMarkers(viewModel),
                      circles: viewModel.circles,
                    ),

                    // Info Card
                    Positioned(
                      top: 24,
                      right: 24,
                      left: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColorTheme.gray50,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColorTheme.gray900.withValues(
                                alpha: 0.1,
                              ),
                              blurRadius: 10,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              color: AppColorTheme.primary,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${viewModel.currentPoint?.fixTime.toIndonesianDate()}",
                                          style: AppTextTheme.titleSmall
                                              .copyWith(
                                                color: AppColorTheme.gray50,
                                              ),
                                        ),
                                        Text(
                                          "${viewModel.currentPoint?.speed.toStringAsFixed(2)} km/h · ${viewModel.currentPoint?.course}°",
                                          style: AppTextTheme.bodySmall
                                              .copyWith(
                                                color: AppColorTheme.gray50,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  OutlinedButton(
                                    onPressed: () async {
                                      final now = DateTime.now();
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: viewModel.selectedDate,
                                        firstDate: DateTime(now.year - 5),
                                        lastDate: DateTime(now.year + 5),
                                        initialEntryMode:
                                            DatePickerEntryMode.calendarOnly,
                                      );
                                      if (picked != null) {
                                        viewModel.setSelectedDate(picked);
                                        viewModel.loadRouteHistory(
                                          deviceId: vehicleId,
                                        );
                                      }
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColorTheme.gray50,
                                      side: const BorderSide(
                                        color: AppColorTheme.gray50,
                                      ),
                                    ),
                                    child: const Text("Pilih Tanggal"),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 8),

                            DefaultPadding(
                              paddingHorizontal: 16,
                              paddingBottom: 4,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.directions_car_outlined,
                                    size: 14,
                                    color: AppColorTheme.gray400,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Device ID: $vehicleId",
                                    style: AppTextTheme.bodyMedium.copyWith(
                                      color: AppColorTheme.gray600,
                                    ),
                                  ),
                                  Spacer(),
                                  Icon(
                                    Icons.route_outlined,
                                    size: 14,
                                    color: AppColorTheme.gray400,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    "${viewModel.totalDistance.toStringAsFixed(2)} km",
                                    style: AppTextTheme.bodyMedium.copyWith(
                                      color: AppColorTheme.gray600,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            DefaultPadding(
                              paddingHorizontal: 16,
                              paddingBottom: 4,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.moving,
                                    size: 14,
                                    color: AppColorTheme.gray400
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Ditempuh:",
                                    style: AppTextTheme.bodyMedium.copyWith(
                                        color: AppColorTheme.gray600),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    viewModel.distanceTraveledFormatted,
                                    style: AppTextTheme.bodyMedium.copyWith(
                                      color: AppColorTheme.gray600,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    "Titik ${viewModel.currentIndex + 1}/${viewModel.tripPoints.length}",
                                    style: AppTextTheme.bodySmall.copyWith(
                                        color: AppColorTheme.gray400),
                                  ),
                                ],
                              ),
                            ),
                            if (viewModel.currentIndex > 0)
                              DefaultPadding(
                                paddingHorizontal: 16,
                                paddingBottom: 4,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.square_foot_outlined,
                                      size: 14, 
                                      color: AppColorTheme.gray400
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Jarak Antar Titik: ",
                                      style: AppTextTheme.bodyMedium.copyWith(
                                        color: AppColorTheme.gray600
                                      ),
                                    ),
                                    Text(
                                      viewModel.segmentDistanceFormatted,
                                      style: AppTextTheme.bodyMedium.copyWith(
                                        color: AppColorTheme.gray600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            DefaultPadding(
                              paddingHorizontal: 16,
                              paddingBottom: 4,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: AppColorTheme.gray400,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "${viewModel.currentPoint?.fixTime.toIndonesianDateTime()}",
                                    style: AppTextTheme.bodyMedium.copyWith(
                                      color: AppColorTheme.gray600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            DefaultPadding(
                              paddingHorizontal: 16,
                              paddingBottom: 4,
                              child: Row(
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 16,
                                        color: AppColorTheme.gray400,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Lat: ${viewModel.currentPoint?.latitude.toStringAsFixed(7)}",
                                        style: AppTextTheme.bodyMedium.copyWith(
                                          color: AppColorTheme.gray600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            DefaultPadding(
                              paddingHorizontal: 16,
                              paddingBottom: 4,
                              child: Row(
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 16,
                                        color: AppColorTheme.gray400,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Long: ${viewModel.currentPoint?.longitude.toStringAsFixed(7)}",
                                        style: AppTextTheme.bodyMedium.copyWith(
                                          color: AppColorTheme.gray600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 24,
                      right: 24,
                      left: 24,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          FloatingActionButton(
                            backgroundColor: AppColorTheme.gray50,
                            foregroundColor: AppColorTheme.yellow,
                            shape: const CircleBorder(),
                            onPressed: () {
                              final newIndex = (viewModel.currentIndex - 10)
                                  .clamp(0, viewModel.tripPoints.length - 1);
                              viewModel.onSliderChanged(newIndex.toDouble());
                            },
                            child: const Icon(Icons.arrow_back_ios_new_rounded),
                          ),
                          FloatingActionButton(
                            backgroundColor: AppColorTheme.gray50,
                            foregroundColor: AppColorTheme.yellow,
                            shape: const CircleBorder(),
                            onPressed: viewModel.tripPoints.isEmpty
                                ? null
                                : () {
                                    final newIndex =
                                        (viewModel.currentIndex + 10).clamp(
                                          0,
                                          viewModel.tripPoints.length - 1,
                                        );
                                    viewModel.onSliderChanged(
                                      newIndex.toDouble(),
                                    );
                                  },
                            child: const Icon(Icons.arrow_forward_ios_rounded),
                          ),
                          SizedBox(width: 120),
                          FloatingActionButton(
                            backgroundColor: viewModel.isPlaying
                                ? AppColorTheme.red
                                : AppColorTheme.green,
                            foregroundColor: AppColorTheme.gray50,
                            shape: const CircleBorder(),
                            onPressed: viewModel.tripPoints.isEmpty
                                ? null
                                : () {
                                    if (viewModel.isPlaying) {
                                      viewModel.pause();
                                    } else {
                                      viewModel.play();
                                    }
                                  },
                            child: Icon(
                              viewModel.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 2,
                      right: 2,
                      bottom: 80,
                      child: Slider(
                        value: viewModel.sliderValue,
                        min: 0,
                        max: viewModel.maxSliderValue == 0
                            ? 1
                            : viewModel.maxSliderValue,
                        onChanged: viewModel.tripPoints.isEmpty
                            ? null
                            : (v) {
                                viewModel.onSliderChanged(v);
                              },
                        activeColor: AppColorTheme.primary,
                        thumbColor: AppColorTheme.primary,
                        inactiveColor: AppColorTheme.gray50,
                      ),
                    ),
                  ],
                );
              case ResultState.error:
                return DefaultErrorWidget(errorMessage: viewModel.errorMessage);
              case ResultState.noData:
                return DefaultErrorWidget(
                  asset: 'assets/images/nodata_mascot.png',
                  errorMessage:
                      "Tidak ada data Perjalanan pada tanggal ${viewModel.selectedDate.toIndonesianDate()}",
                  onRetryButtonLabel: "Pilih Tanggal",
                  onRetry: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: viewModel.selectedDate,
                      firstDate: DateTime(now.year - 5),
                      lastDate: DateTime(now.year + 5),
                      initialEntryMode: DatePickerEntryMode.calendarOnly,
                    );
                    if (picked != null) {
                      viewModel.setSelectedDate(picked);
                      viewModel.loadRouteHistory(deviceId: vehicleId);
                    }
                  },
                );
              default:
                return SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }

  Set<Marker> _buildMarkers(RouteHistoryViewModel viewModel) {
    return <Marker>{
      Marker(
        markerId: MarkerId('1'),
        position:
            viewModel.animatedPosition ??
            LatLng(
              viewModel.currentPoint?.latitude ?? 0,
              viewModel.currentPoint?.longitude ?? 0,
            ),
        rotation: viewModel
            .currentCourse, 
        flat: true,
        anchor: const Offset(0.5, 0.5),
        icon: viewModel.getMarkerIcon(),
      ),
    };
  }
}
