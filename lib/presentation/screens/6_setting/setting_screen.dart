import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nusantara_gps/core/app/app_text_theme.dart';
import 'package:nusantara_gps/core/app/app_color_theme.dart';
import 'package:nusantara_gps/core/config/result.dart';
import 'package:nusantara_gps/presentation/screens/6_setting/setting_view_model.dart';
import 'dialogs/change_password_dialog.dart';
import 'dialogs/edit_profile_dialog.dart';
import 'package:nusantara_gps/presentation/widgets/setting_widget/about_item_widget.dart';
import 'package:nusantara_gps/presentation/widgets/setting_widget/profile_header.dart';
import 'package:nusantara_gps/presentation/widgets/setting_widget/profile_item_widget.dart';
import 'package:nusantara_gps/presentation/widgets/custom_dialog_confirmation.dart';
import 'package:nusantara_gps/presentation/widgets/default_error_widget.dart';
import 'package:nusantara_gps/presentation/widgets/default_padding.dart';
import 'package:nusantara_gps/presentation/screens/6_setting/widgets/service_health_widget.dart';
import 'package:nusantara_gps/core/utils/url_opener.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pengaturan',
          style: AppTextTheme.titleMedium,
        ),
        centerTitle: true,
      ),
      body: Consumer<SettingViewModel>(
        builder: (context, vm, child) {
          switch (vm.loadState) {
            case ResultState.loading:
              return const Center(
                child: CupertinoActivityIndicator(),
              );

            case ResultState.success:
              return ListView(
                children: [
                  const SizedBox(height: 24),

                  ProfileHeader(vm: vm),

                  const SizedBox(height: 20),

                  DefaultPadding(
                    child: Text(
                      'Profil Pengguna',
                      style: AppTextTheme.labelLarge,
                    ),
                  ),

                  const SizedBox(height: 8),

                  ProfileItemWidget(
                    title: 'Nama',
                    value: vm.name ?? '-',
                    iconData: Icons.person_outline_rounded,
                  ),

                  ProfileItemWidget(
                    title: 'Username',
                    value: vm.username ?? '-',
                    iconData: Icons.account_circle_outlined,
                  ),

                  ProfileItemWidget(
                    title: 'Telepon',
                    value: vm.phone ?? '-',
                    iconData: Icons.phone_enabled_outlined,
                  ),

                  ProfileItemWidget(
                    title: 'Email',
                    value: vm.email ?? '-',
                    iconData: Icons.mail_outline,
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => EditProfileDialog(vm: vm),
                              );
                            },
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Edit Profil'),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColorTheme.primary,
                              side: BorderSide(
                                color: AppColorTheme.primary,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => ChangePasswordDialog(vm: vm),
                              );
                            },
                            icon: const Icon(Icons.lock_outline_rounded,
                                size: 16),
                            label: const Text('Ubah Password'),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColorTheme.primary,
                              side: BorderSide(
                                color: AppColorTheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        showConfirmDialog(
                          context: context,
                          title: 'Log Out',
                          message: 'Apakah anda yakin ingin logout?',
                          onConfirm: () {
                            context
                                .read<SettingViewModel>()
                                .logout(context);
                          },
                        );
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        side: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  DefaultPadding(
                    child: const ServiceHealthWidget(),
                  ),

                  const SizedBox(height: 20),

                  DefaultPadding(
                    child: Text(
                      'Tentang Aplikasi',
                      style: AppTextTheme.labelLarge,
                    ),
                  ),

                  const SizedBox(height: 8),

                  AboutItemWidget(
                    title: 'Nama Aplikasi',
                    subtitle: 'NusantaraGPS New Version',
                    iconData: Icons.dashboard_outlined,
                  ),

                  AboutItemWidget(
                    title: 'Versi',
                    subtitle: '2.0.0',
                    iconData: Icons.verified_outlined,
                  ),

                  AboutItemWidget(
                    iconData: Icons.phone_outlined,
                    title: 'Kontak (WA)',
                    onTap: () => openUrl(
                      'https://wa.me/6281359151087?text=NusantaraGPS%0A%0AHalo%20saya%20ingin%20bertanya%20tentang%20produk%20Anda',
                    ),
                    subtitle: '+6281359151087',
                  ),

                  AboutItemWidget(
                    iconData: Icons.email_outlined,
                    title: 'Email',
                    subtitle: 'lintasjejak@gmail.com',
                    onTap: () => openUrl('mailto:lintasjejak@gmail.com'),
                  ),

                  AboutItemWidget(
                    iconData: Icons.language,
                    title: 'Website',
                    subtitle: 'https://nusantaragps.com',
                    onTap: () => openUrl('https://nusantaragps.com/profil'),
                  ),
                  
                  AboutItemWidget(
                    iconData: Icons.star_outline_rounded,
                    title: 'Rating & Review',
                    subtitle: 'Beri ulasan dan rating',
                    onTap: () {},
                  ),

                  // AboutItemWidget(
                  //   iconData: Icons.share_outlined,
                  //   title: 'Bagikan Aplikasi',
                  //   subtitle: 'Bagikan tautan aplikasi dari Play Store',
                  //   onTap: () {},
                  // ),

                  AboutItemWidget(
                    title: 'Alamat',
                    subtitle:
                        'Jl. Akordion, Tunggulwulung, Kec. Lowokwaru, Kota Malang , Jawa Timur, 65143',
                    iconData: Icons.location_on_outlined,
                    onTap: () =>
                        openUrl('https://maps.app.goo.gl/Ek2PC1x7ZrHqA7J96'),
                  ),
                  SizedBox(height: 20),
                  Text(
                    '©${DateTime.now().year} PT Lintas Jejak Nusaraya. All rights reserved',
                    textAlign: TextAlign.center,
                    style: AppTextTheme.bodySmall.copyWith(
                      color: AppColorTheme.gray400,
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              );

            case ResultState.error:
              return const DefaultErrorWidget(
                errorMessage: 'Tidak dapat load data.',
              );

            default:
              return const SizedBox.shrink();
          }
        },
      ),
    );
  }
}