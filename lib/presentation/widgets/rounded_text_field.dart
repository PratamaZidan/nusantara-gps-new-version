import 'package:flutter/material.dart';
import 'package:nusantara_gps/core/app/app_color_theme.dart';

class RoundedTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final bool enabled;
  final int maxLines;
  final Widget? suffix;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final String? initialValue;
  final TextInputType? keyboardType;
  final String? selectedFunction;

  const RoundedTextField({
    super.key,
    this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.suffix,
    this.onChanged,
    this.validator,
    this.initialValue,
    this.keyboardType,
    this.selectedFunction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColorTheme.gray50,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: TextFormField(
        initialValue: initialValue,
        controller: controller,
        obscureText: obscureText,
        onTapOutside: (event) {
          FocusScope.of(context).unfocus();
        },
        onChanged: onChanged,
        validator: validator,
        maxLines: maxLines,
        enabled: enabled,
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColorTheme.gray200),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColorTheme.gray200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColorTheme.green500),
          ),
          prefixIcon: Icon(icon, color: AppColorTheme.neutral, size: 20),
          suffixIcon: suffix,
          hintText: hint,
          hintStyle: const TextStyle(
            color: AppColorTheme.gray300,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          contentPadding: const EdgeInsets.only(top: 16),
        ),
      ),
    );
  }
}
