import 'package:flutter/material.dart';

ThemeData buildTheme() {
  final seed = Colors.indigo;
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: seed),
    useMaterial3: true,
  );
}
