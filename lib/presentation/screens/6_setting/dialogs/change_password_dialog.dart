import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nusantara_gps/core/app/app_color_theme.dart';
import 'package:nusantara_gps/presentation/screens/6_setting/setting_view_model.dart';
import 'package:nusantara_gps/presentation/widgets/rounded_text_field.dart';

class ChangePasswordDialog extends StatefulWidget {
  final SettingViewModel vm;

  const ChangePasswordDialog({
    super.key,
    required this.vm,
  });

  @override
  State<ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {

  final oldCtrl = TextEditingController();
  final newCtrl = TextEditingController();
  final confCtrl = TextEditingController();

  bool showOld = false;
  bool showNew = false;
  bool showConf = false;

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;

    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text('Ubah Password'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RoundedTextField(
              controller: oldCtrl,
              hint: 'Password lama',
              icon: Icons.lock_outline,
              obscureText: !showOld,
              suffix: IconButton(
                icon: Icon(
                  showOld
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () => setState(() => showOld = !showOld),
                
              ),
            ),

            const SizedBox(height: 12),

            RoundedTextField(
              controller: newCtrl,
              hint: 'Password baru',
              icon: Icons.lock_outline,
              obscureText: !showNew,
              suffix: IconButton(
                icon: Icon(
                  showNew
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () => setState(() => showNew = !showNew),
              ),
            ),

            const SizedBox(height: 12),

            RoundedTextField(
              controller: confCtrl,
              hint: 'Konfirmasi password',
              icon: Icons.lock_outline,
              obscureText: !showConf,
              suffix: IconButton(
                    icon: Icon(showConf
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () => setState(() => showConf = !showConf),
              ),
            ),
          ],
        ),
      ),
      
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
          style: TextButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),

        ElevatedButton(
          onPressed: () async {
            if (newCtrl.text != confCtrl.text) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password tidak cocok'),
                ),
              );
              return;
            }

            final ok = await vm.changePassword(
              oldPassword: oldCtrl.text,
              newPassword: newCtrl.text,
            );

            if (!context.mounted) return;

            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  ok
                      ? 'Password berhasil diubah'
                      : vm.errorMessage ?? 'Gagal mengubah password',
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColorTheme.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}