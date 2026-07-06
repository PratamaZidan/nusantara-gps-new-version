import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nusantara_gps/core/app/app_color_theme.dart';

void showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String cancelText = 'TIDAK',
  String confirmText = 'YA',
  Color color = AppColorTheme.red,
  required VoidCallback onConfirm,
}) {
  showDialog(
    context: context,
    barrierDismissible: false, // harus pilih salah satu tombol
    builder: (_) {
      return Dialog(
        backgroundColor: Colors.white,

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/question_mascot.png', height: 120),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: color),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(cancelText, style: TextStyle(color: color)),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // KELUAR
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.pop();
                        onConfirm();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        confirmText,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
