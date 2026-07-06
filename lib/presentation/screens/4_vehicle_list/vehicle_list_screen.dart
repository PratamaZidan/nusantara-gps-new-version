import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:nusantara_gps/core/app/app_color_theme.dart';
import 'package:nusantara_gps/core/app/app_text_theme.dart';
import 'package:nusantara_gps/data/models/vehicle_model.dart';
import 'package:nusantara_gps/presentation/screens/4_vehicle_list/vehicle_list_view_model.dart';
import 'package:nusantara_gps/presentation/widgets/animation/slide_fade_in.dart';
import 'package:nusantara_gps/presentation/widgets/default_error_widget.dart';
import 'package:provider/provider.dart';

class VehicleListScreen extends StatelessWidget {
  const VehicleListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VehicleListViewModel>();
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(140),
        child: AppBar(
          elevation: 0,
          flexibleSpace: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              gradient: AppColorTheme.defautGradient,
              color: AppColorTheme.primary,
            ),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Text(
                  "Daftar Kendaraan",
                  style: AppTextTheme.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: vm.searchQueryController,
                        decoration: InputDecoration(
                          fillColor: Colors.white,
                          filled: true,
                          hintText: 'Brand, Plat Nomor',
                          hintStyle: TextStyle(color: AppColorTheme.gray400),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColorTheme.green200,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColorTheme.primary,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.all(16),
                        ),
                        onTapOutside: (event) =>
                            FocusScope.of(context).unfocus(),
                        onEditingComplete: () async {
                          vm.pagingController.refresh();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      padding: const EdgeInsets.all(19),
                      onPressed: () async {
                        vm.pagingController.refresh();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.white),
                        ),
                      ),
                      icon: const Icon(
                        Icons.search,
                        size: 18,
                        color: AppColorTheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: Consumer<VehicleListViewModel>(
        builder: (context, viewModel, child) {
          return PagingListener(
            controller: viewModel.pagingController,
            builder: (context, state, fetchNextPage) {
              return PagedListView<int, Vehicle>(
                state: state,
                fetchNextPage: fetchNextPage,
                builderDelegate: PagedChildBuilderDelegate(
                  itemBuilder: (context, v, index) => SlideFadeIn(
                    child: ListTile(
                      title: Text(v.brand, style: AppTextTheme.labelLarge),
                      subtitle: Text(
                        v.gsm,
                        style: AppTextTheme.bodyMedium.copyWith(
                          color: AppColorTheme.gray500,
                        ),
                      ),
                      leading: Image.network(
                        v.imageUrl,
                        height: 40,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/default_car_image.png',
                            height: 40,
                          );
                        },
                      ),
                      trailing: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColorTheme.gray800),
                        ),
                        child: Text(
                          v.plateNumber,
                          style: AppTextTheme.labelMedium,
                        ),
                      ),
                      onTap: () => context.push('/vehicle-detail/${v.id}'),
                    ),
                  ),
                  firstPageProgressIndicatorBuilder: (context) =>
                      const Center(child: CupertinoActivityIndicator()),
                  newPageProgressIndicatorBuilder: (context) =>
                      const Center(child: CupertinoActivityIndicator()),
                  firstPageErrorIndicatorBuilder: (context) =>
                      DefaultErrorWidget(
                        errorMessage: vm.errorMessage,
                        onRetry: () {
                          vm.pagingController.refresh();
                        },
                      ),
                  noItemsFoundIndicatorBuilder: (context) {
                    return DefaultErrorWidget(
                      asset: 'assets/images/nodata_mascot.png',
                      errorMessage:
                          'Tidak ada hasil untuk "${viewModel.searchQueryController.text}"',
                    );
                  },
                  noMoreItemsIndicatorBuilder: (context) => Center(
                    child: Text(
                      "Tidak ada data lain",
                      style: AppTextTheme.bodySmall.copyWith(
                        color: AppColorTheme.gray500,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
