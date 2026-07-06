import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nusantara_gps/core/app/app_color_theme.dart';
import 'package:nusantara_gps/core/config/result.dart';
import 'package:nusantara_gps/presentation/screens/6_setting/setting_view_model.dart';
import 'package:nusantara_gps/presentation/widgets/rounded_text_field.dart';

class EditProfileDialog extends StatelessWidget {
  final SettingViewModel vm;

  const EditProfileDialog({
    super.key,
    required this.vm,
  });

  @override
  Widget build(BuildContext context) {
    // final vm = context.read<SettingViewModel>();

    final nameCtrl = TextEditingController(text: vm.name ?? '');
    final phoneCtrl = TextEditingController(text: vm.phone ?? '');
    final emailCtrl = TextEditingController(text: vm.email ?? '');

    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text('Edit Profil'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RoundedTextField(
              controller: nameCtrl,
              hint: 'Nama Lengkap',
              icon: Icons.person_outline_rounded,
            ),

            const SizedBox(height: 12),

            RoundedTextField(
              controller: phoneCtrl,
              hint: 'Nomor Telepon',
              icon: Icons.phone_outlined,
            ),

            const SizedBox(height: 12),

            RoundedTextField(
              controller: emailCtrl,
              hint: 'Email',
              icon: Icons.mail_outline,
            ),
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
          child: const Text('Batal'),
        ),

        ElevatedButton(
          onPressed: vm.saveState == ResultState.loading
              ? null
              : () async {
                  final ok = await vm.saveProfile(
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                  );

                  if (!context.mounted) return;

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok
                            ? 'Profil berhasil disimpan'
                            : vm.errorMessage ?? 'Gagal menyimpan',
                      ),
                    ),
                  );
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColorTheme.primary,
            foregroundColor: Colors.white,
          ),

          child: vm.saveState == ResultState.loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}