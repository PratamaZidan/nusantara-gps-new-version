import 'package:flutter/material.dart';

class SlideFadeIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double delay;
  final double beginOffsetY;

  const SlideFadeIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 800),
    this.delay = 0.0,
    this.beginOffsetY = 0.5, // Default muncul setengah lebar dari samping
  });

  @override
  State<SlideFadeIn> createState() => _SlideFadeInState();
}

class _SlideFadeInState extends State<SlideFadeIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Setup Controller
    _controller = AnimationController(vsync: this, duration: widget.duration);

    // 2. Setup Animasi Fade (Opacity 0.0 -> 1.0)
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // 3. Setup Animasi Slide (Offset -> Zero)
    // Offset(1.0, 0.0) artinya bergeser sejauh 1x lebar widget itu sendiri ke kanan
    _slideAnimation = Tween<Offset>(
      begin: Offset(0.0, widget.beginOffsetY),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));

    // 4. Jalankan animasi (dengan delay jika ada)
    if (widget.delay > 0) {
      Future.delayed(Duration(milliseconds: (widget.delay * 1000).round()), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose(); // Penting untuk mencegah memory leak
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Menggunakan FadeTransition dan SlideTransition bawaan Flutter
    // untuk performa maksimal (menghindari rebuild widget tree berlebihan)
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}
