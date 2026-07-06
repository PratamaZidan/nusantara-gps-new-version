import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nusantara_gps/core/app/app_color_theme.dart';
import 'package:nusantara_gps/core/app/app_text_theme.dart';
import 'package:nusantara_gps/presentation/screens/6_setting/setting_view_model.dart';

class ProfileHeader extends StatelessWidget {
  final SettingViewModel vm;

  const ProfileHeader({
    super.key,
    required this.vm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: AppColorTheme.green100,
                backgroundImage: vm.localPhotoPath != null
                    ? FileImage(File(vm.localPhotoPath!))
                    : const AssetImage('assets/images/profile_placeholder.png')
                      as ImageProvider,
              ),

              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.white,
                      builder: (_) {
                        return SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.photo_camera_outlined),
                                title: const Text('Ganti Foto'),
                                onTap: () async {
                                  Navigator.pop(context);
                                  await vm.pickAndSavePhoto();
                                },
                              ),

                              if (vm.localPhotoPath != null)
                                ListTile(
                                  leading: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  title: const Text(
                                    'Hapus Foto',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    await vm.removePhoto();
                                  },
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColorTheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        Text(
          vm.name ?? vm.username ?? '-',
          style: AppTextTheme.titleMedium,
        ),
      ],
    );
  }
}
