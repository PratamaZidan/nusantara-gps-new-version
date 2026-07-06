import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nusantara_gps/core/app/app_color_theme.dart';
import 'package:nusantara_gps/core/app/app_text_theme.dart';

class PoiPhotoPicker extends StatelessWidget {
  final File? photoFile;
  final String? existingPhotoUrl;
  final String? localImagePath;
  final Future<void> Function(ImageSource source) onPick;
  final VoidCallback? onRemoveNew;

  const PoiPhotoPicker({
    super.key,
    this.photoFile,
    this.existingPhotoUrl,
    this.localImagePath,
    required this.onPick,
    this.onRemoveNew,
  });

  bool get _hasNew => photoFile != null;
  bool get _hasLocal => localImagePath != null && localImagePath!.isNotEmpty;
  bool get _hasExisting => existingPhotoUrl != null && existingPhotoUrl!.isNotEmpty;
  bool get _hasAny => _hasNew || _hasLocal || _hasExisting;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Foto Lokasi', style: AppTextTheme.bodySmall),
            const SizedBox(width: 4),
            Text('(wajib)',
              style: AppTextTheme.bodySmall.copyWith(color: AppColorTheme.red)),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showSourceSheet(context),
          child: Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: AppColorTheme.gray100,
              border: Border.all(
                color: (_hasNew || _hasExisting) 
                    ? AppColorTheme.primary 
                    : AppColorTheme.gray300,
                width: 1.5,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_hasNew)
                  Image.file(photoFile!, fit: BoxFit.cover)
                else if (_hasLocal)
                  Image.file(File(localImagePath!), fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder())
                else if (_hasExisting)
                  Image.network(existingPhotoUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder())
                else
                  _placeholder(),

                if (_hasAny)
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    color: Colors.black38,
                    child: Text('Tap untuk ganti foto',
                        textAlign: TextAlign.center,
                        style: AppTextTheme.bodySmall.copyWith(color: Colors.white)),
                  ),
                ),

                if (_hasNew && onRemoveNew != null)
                Positioned(
                  top: 8, right: 8,
                  child: GestureDetector(
                    onTap: onRemoveNew,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 4),
        if(_hasNew)
          Text('Foto baru dipilih', style: AppTextTheme.bodySmall.copyWith(color: AppColorTheme.primary))
        else if (_hasLocal)
          Text('Foto tersimpan di lokal',
            style: AppTextTheme.bodySmall.copyWith(color: AppColorTheme.neutral))
        else if (_hasExisting)
          Text('Tap untuk ganti foto', 
            style: AppTextTheme.bodySmall.copyWith(color: AppColorTheme.neutral)),
      ],
    );
  }

  Widget _placeholder() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.add_a_photo_rounded, size: 40, color: AppColorTheme.gray400),
      const SizedBox(height: 8),
      Text('Tap untuk upload foto', style: AppTextTheme.bodySmall),
    ],
  );

  void _showSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context, 
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Pilih Sumber Foto', style: AppTextTheme.bodyMedium),
              const SizedBox(height: 12),
              ListTile(
                leading: Icon(Icons.camera_alt_rounded, color: AppColorTheme.primary),
                title: const Text('Kamera'),
                onTap: () { Navigator.pop(context); onPick(ImageSource.camera); },
              ),
              ListTile(
                leading: Icon(Icons.photo_library_rounded, color: AppColorTheme.primary),
                title: const Text('Galeri'),
                onTap: () { Navigator.pop(context); onPick(ImageSource.gallery); },
              ),
            ],
          ),
        ),
      ),
    );
  }
}