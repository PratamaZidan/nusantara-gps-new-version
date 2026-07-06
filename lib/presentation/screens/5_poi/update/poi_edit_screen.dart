import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nusantara_gps/core/app/app_color_theme.dart';
import 'package:nusantara_gps/core/app/app_text_theme.dart';
import 'package:nusantara_gps/core/config/result.dart';
import 'package:nusantara_gps/core/utils/inconsistent_value_extention.dart';
import 'package:nusantara_gps/presentation/screens/5_poi/update/poi_edit_view_model.dart';
import 'package:nusantara_gps/presentation/widgets/app_button.dart';
import 'package:nusantara_gps/presentation/widgets/custom_snack_bar.dart';
import 'package:nusantara_gps/presentation/screens/5_poi/widgets/poi_form.dart';
import 'package:provider/provider.dart';

class PoiEditScreen extends StatefulWidget {
  const PoiEditScreen({super.key});

  @override
  State<PoiEditScreen> createState() => _PoiEditScreenState();
}

class _PoiEditScreenState extends State<PoiEditScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PoiEditViewModel>().loadIcons();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        title: Text('Edit Lokasi Minat', style: AppTextTheme.bodyMedium),
      ),
      body: SafeArea(
        child: Consumer<PoiEditViewModel>(
          builder: (context, vm, _) {
            return Stack(
              children: [
                // Form (shared widget)
                PoiForm(
                  namaController: vm.namaController,
                  keteranganController: vm.keteranganController,
                  latController: vm.latController,
                  lngController: vm.lngController,
                  photoFile: vm.photoFile,
                  existingPhotoUrl: vm.hasExistingPhoto && vm.localImagePath == null
                    ? vm.existingPhotoUrl
                    : null,
                  localImagePath: vm.localImagePath,
                  onPickPhoto: vm.pickPhoto,
                  onRemoveNewPhoto: vm.hasNewPhoto ? vm.removeNewPhoto : null,
                  iconList: vm.iconList,
                  selectedIcon: vm.selectedIcon,
                  iconLoadState: vm.iconLoadState,
                  onSelectIcon: vm.selectIcon,
                  markers: vm.buildMarkers(),
                  onMapTap: (latLng) {
                    vm.latController.text = latLng.latitude.toString();
                    vm.lngController.text = latLng.longitude.toString();
                  },
                ),

                // Bottom Bar
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: (vm.saveState == ResultState.loading)
                    ? const Center(child: CupertinoActivityIndicator())
                    : Row (
                        children: [
                          Expanded(
                            child: AppButton(
                              label: 'Batal',
                              isSecondary: true,
                              gradient: LinearGradient(
                                colors: [
                                  AppColorTheme.red,
                                  AppColorTheme.red.withOpacity(0.9),
                                ],
                              ),
                              onPressed: () => context.pop(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppButton(
                              label: 'Simpan',
                              onPressed: () async {
                                await vm.savePoi();
                                if (vm.saveState == ResultState.success && context.mounted) {
                                  context.pop();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                  ),
                ),

                  // Error snackbar
                  if (vm.saveState == ResultState.error)
                  CustomSnackbarWithStack(
                    message: vm.errorMessage ?? 'Terjadi Kesalahan',
                    trailling: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white)),
                      onPressed: vm.savePoi, 
                      child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                    ), 
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}