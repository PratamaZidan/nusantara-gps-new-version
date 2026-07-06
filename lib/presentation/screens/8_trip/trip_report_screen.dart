import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nusantara_gps/core/app/app_color_theme.dart';
import 'package:nusantara_gps/core/app/app_text_theme.dart';
import 'package:nusantara_gps/core/config/result.dart';
import 'package:nusantara_gps/presentation/screens/8_trip/trip_report_view_model.dart';
import 'package:nusantara_gps/presentation/screens/8_trip/widgets/trip_report_item_widget.dart';
import 'package:nusantara_gps/presentation/widgets/default_error_widget.dart';
import 'package:nusantara_gps/presentation/widgets/default_padding.dart';
import 'package:provider/provider.dart';

class TripReportScreen extends StatelessWidget {
  final int deviceId;
  const TripReportScreen({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TripReportViewModel>();
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(140),
        child: AppBar(
          automaticallyImplyLeading: true,
          foregroundColor: AppColorTheme.gray50,
          backgroundColor: AppColorTheme.green700,
          elevation: 0,
          flexibleSpace: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                gradient: AppColorTheme.defautGradient,
                color: AppColorTheme.primary,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Text(
                    "Laporan Harian",
                    style: AppTextTheme.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: Colors.white),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              "${vm.startDate} - ${vm.endDate}",
                              style: AppTextTheme.bodyMedium,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final now = DateTime.now();
                            // 1) Tampilkan picker, tunggu pilihan user
                            final range = await showDateRangePicker(
                              initialEntryMode: DatePickerEntryMode.calendarOnly,
                              context: context,
                              firstDate: DateTime(now.year - 5),
                              lastDate: now,
                              helpText: 'Pilih Rentang Tanggal',
                              cancelText: 'Batal',
                              confirmText: 'Pilih',
                              saveText: 'Simpan',
                            );
                            // 2) Simpan ke ViewModel (null = user cancel)
                            vm.setRangeDate(range);
                            // 3) Baru load — hanya jika user memilih tanggal
                            if (range != null) {
                              await vm.loadTripReport(deviceId);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                              side: const BorderSide(color: Colors.white),
                            ),
                          ),
                          icon: const Icon(
                            Icons.calendar_month_rounded,
                            size: 18,
                            color: AppColorTheme.primary,
                          ),
                          label: const Text(
                            "Pilih Tanggal",
                            style: AppTextTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: Consumer<TripReportViewModel>(
          builder: (context, viewModel, child) {
            switch (viewModel.loadState) {
              case ResultState.loading:
                return const Center(child: CupertinoActivityIndicator());
              case ResultState.success:
                final items = viewModel.tripReports;
                if (items.isEmpty) {
                  return const DefaultErrorWidget(
                    errorMessage: "Tidak Ada Data",
                  );
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final report = items[index];
                    return DefaultPadding(
                      paddingTop: 16,
                      paddingHorizontal: 16,
                      child: TripReportItemWidget(report: report),
                    );
                  },
                );
              case ResultState.error:
                return DefaultErrorWidget(errorMessage: viewModel.errorMessage);
              case ResultState.noData:
                return DefaultErrorWidget(errorMessage: viewModel.errorMessage);
              default:
                return const SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }
}
