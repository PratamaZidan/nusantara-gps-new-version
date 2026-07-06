// lib/theme/AppColorTheme.dart

import 'package:flutter/material.dart';

/// Kelas ini berisi palet warna kustom untuk aplikasi.
///
/// Untuk mencegah inisialisasi yang tidak disengaja,
/// konstruktor dibuat private.
///
/// Gunakan warna secara statis, contoh:
/// `AppColorTheme.gray50`
/// `AppColorTheme.green500`
///
/// Anda juga dapat menggunakan MaterialColor swatches:
/// `AppColorTheme.gray`
/// `AppColorTheme.green`
class AppColorTheme {
  // Membuat konstruktor private agar kelas ini tidak bisa di-instantiate
  AppColorTheme._();

  static const Color neutral = Color(0xFF8593A3);
  static const Color primary = green600;

  // --- GRAY ---
  static const Color gray50 = Color(0xFFf9fafb);
  static const Color gray100 = Color(0xFFf3f4f6);
  static const Color gray200 = Color(0xFFe5e7eb);
  static const Color gray300 = Color(0xFFd1d5db);
  static const Color gray400 = Color(0xFF9ca3af);
  static const Color gray500 = Color(0xFF6b7280);
  static const Color gray600 = Color(0xFF4b5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1f2937);
  static const Color gray900 = Color(0xFF111827);
  static const Color gray950 = Color(0xFF030712);

  static const MaterialColor gray = MaterialColor(0xFF6b7280, <int, Color>{
    50: gray50,
    100: gray100,
    200: gray200,
    300: gray300,
    400: gray400,
    500: gray500,
    600: gray600,
    700: gray700,
    800: gray800,
    900: gray900,
  });

  // --- GREEN ---
  static const Color green50 = Color(0xFFf0fdf4);
  static const Color green100 = Color(0xFFdcfce7);
  static const Color green200 = Color(0xFFbbf7d0);
  static const Color green300 = Color(0xFF86efac);
  static const Color green400 = Color(0xFF4ade80);
  static const Color green500 = Color(0xFF22c55e);
  static const Color green600 = Color(0xFF16a34a);
  static const Color green700 = Color(0xFF15803d);
  static const Color green800 = Color(0xFF166534);
  static const Color green900 = Color(0xFF14532d);
  static const Color green950 = Color(0xFF052e16);

  static const MaterialColor green = MaterialColor(0xFF22c55e, <int, Color>{
    50: green50,
    100: green100,
    200: green200,
    300: green300,
    400: green400,
    500: green500,
    600: green600,
    700: green700,
    800: green800,
    900: green900,
    // 950 tidak termasuk dalam swatch MaterialColor standar,
    // gunakan AppColorTheme.green950 secara langsung.
  });

  // --- RED ---
  static const Color red50 = Color(0xFFfef2f2);
  static const Color red100 = Color(0xFFfee2e2);
  static const Color red200 = Color(0xFFfecaca);
  static const Color red300 = Color(0xFFfca5a5);
  static const Color red400 = Color(0xFFf87171);
  static const Color red500 = Color(0xFFef4444);
  static const Color red600 = Color(0xFFdc2626);
  static const Color red700 = Color(0xFFb91c1c);
  static const Color red800 = Color(0xFF991b1b);
  static const Color red900 = Color(0xFF7f1d1d);
  static const Color red950 = Color(0xFF450a0a);

  /// MaterialColor swatch untuk Red.
  /// Shade 500 (Color(0xFFef4444)) digunakan sebagai nilai utama.
  static const MaterialColor red = MaterialColor(0xFFef4444, <int, Color>{
    50: red50,
    100: red100,
    200: red200,
    300: red300,
    400: red400,
    500: red500,
    600: red600,
    700: red700,
    800: red800,
    900: red900,
    // 950 tidak termasuk dalam swatch MaterialColor standar,
    // gunakan AppColorTheme.red950 secara langsung.
  });

  // --- YELLOW ---
  static const Color yellow50 = Color(0xFFfefce8);
  static const Color yellow100 = Color(0xFFfef9c3);
  static const Color yellow200 = Color(0xFFfef08a);
  static const Color yellow300 = Color(0xFFfde047);
  static const Color yellow400 = Color(0xFFfacc15);
  static const Color yellow500 = Color(0xFFeab308);
  static const Color yellow600 = Color(0xFFca8a04);
  static const Color yellow700 = Color(0xFFa16207);
  static const Color yellow800 = Color(0xFF854d0e);
  static const Color yellow900 = Color(0xFF713f12);
  static const Color yellow950 = Color(0xFF422006);

  /// MaterialColor swatch untuk Yellow.
  /// Shade 500 (Color(0xFFeab308)) digunakan sebagai nilai utama.
  static const MaterialColor yellow = MaterialColor(0xFFeab308, <int, Color>{
    50: yellow50,
    100: yellow100,
    200: yellow200,
    300: yellow300,
    400: yellow400,
    500: yellow500,
    600: yellow600,
    700: yellow700,
    800: yellow800,
    900: yellow900,
    // 950 tidak termasuk dalam swatch MaterialColor standar,
    // gunakan AppColorTheme.yellow950 secara langsung.
  });

  static const LinearGradient defautGradient = LinearGradient(
    colors: [AppColorTheme.green700, AppColorTheme.primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [AppColorTheme.gray300, AppColorTheme.gray300],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
