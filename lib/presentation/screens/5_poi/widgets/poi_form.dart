import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nusantara_gps/core/app/app_color_theme.dart';
import 'package:nusantara_gps/core/app/app_text_theme.dart';
import 'package:nusantara_gps/core/config/result.dart';
import 'package:nusantara_gps/core/utils/inconsistent_value_extention.dart';
import 'package:nusantara_gps/presentation/screens/5_poi/widgets/poi_icon_picker.dart';
import 'package:nusantara_gps/presentation/screens/5_poi/widgets/poi_photo_picker.dart';
import 'package:nusantara_gps/presentation/widgets/rounded_text_field.dart';

class PoiForm extends StatefulWidget {
  // Controllers
  final TextEditingController namaController;
  final TextEditingController keteranganController;
  final TextEditingController latController;
  final TextEditingController lngController;

  // Foto
  final File? photoFile;
  final String? existingPhotoUrl;
  final String? localImagePath;

  final Future<void> Function(ImageSource) onPickPhoto;
  final VoidCallback? onRemoveNewPhoto;

  // Icon
  final List<String> iconList;
  final String selectedIcon;
  final ResultState iconLoadState;
  final ValueChanged<String> onSelectIcon;

  // Peta
  final Set<Marker> markers;
  final ValueChanged<LatLng> onMapTap;

  const PoiForm({
    super.key,
    required this.namaController,
    required this.keteranganController,
    required this.latController,
    required this.lngController,
    required this.photoFile,
    required this.onPickPhoto,
    required this.iconList,
    required this.selectedIcon,
    required this.iconLoadState,
    required this.onSelectIcon,
    required this.markers,
    required this.onMapTap,
    this.existingPhotoUrl,
    this.localImagePath,
    this.onRemoveNewPhoto,
  });

  @override
  State<PoiForm> createState() => _PoiFormState();
}

class _PoiFormState extends State<PoiForm> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: [
        // Nama
        Text('NAMA LOKASI', style: AppTextTheme.bodySmall),
        const SizedBox(height: 4),
        RoundedTextField(
          controller: widget.namaController,
          hint: 'Nama lokasi minat',
          icon: Icons.maps_home_work_outlined,
        ),
        const SizedBox(height: 16),

        // Keterangan
        Text('KETERANGAN', style: AppTextTheme.bodySmall),
        const SizedBox(height: 4),
        RoundedTextField(
          controller: widget.keteranganController,
          hint: 'Keterangan (opsional)',
          icon: Icons.description_outlined,
          maxLines: 3,
        ),
        const SizedBox(height: 16),

        // Upload Foto
        PoiPhotoPicker(
          photoFile:        widget.photoFile,
          existingPhotoUrl: widget.existingPhotoUrl,
          localImagePath:   widget.localImagePath,
          onPick:           widget.onPickPhoto,
          onRemoveNew:      widget.onRemoveNewPhoto,
        ),
        const SizedBox(height: 16),

        // Pilih Icon Marker
        PoiIconPicker(
          iconList:     widget.iconList,
          selectedIcon: widget.selectedIcon,
          loadState:    widget.iconLoadState,
          onSelect:     widget.onSelectIcon,
        ),
        const SizedBox(height: 16),

        // Koordinat
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LAT', style: AppTextTheme.bodySmall),
                  const SizedBox(height: 4),
                  RoundedTextField(
                    controller: widget.latController,
                    hint: 'Latitude',
                    icon: Icons.pin_drop_outlined,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LNG', style: AppTextTheme.bodySmall),
                  const SizedBox(height: 4),
                  RoundedTextField(
                    controller: widget.lngController,
                    hint: 'Longitude',
                    icon: Icons.pin_drop_outlined,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Mini-map
        Text('TAP PETA UNTUK UBAH POSISI', style: AppTextTheme.bodySmall),
        const SizedBox(height: 4),
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColorTheme.gray200),
          ),
          clipBehavior: Clip.antiAlias,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                stringToDouble(widget.latController.text),
                stringToDouble(widget.lngController.text),
              ),
              zoom: 14,
            ),
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            markers: widget.markers,
            onTap: (latLng) {
              widget.onMapTap(latLng);
              setState(() {}); // rebuild agar marker & field koordinat terupdate
            },
          ),
        ),
      ],
    );
  }
}