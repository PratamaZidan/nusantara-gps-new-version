import 'package:flutter/material.dart';

class SimpleFadeIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double delay;

  const SimpleFadeIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 800),
    this.delay = 0.6,
  });

  @override
  State<SimpleFadeIn> createState() => _SimpleFadeInState();
}

class _SimpleFadeInState extends State<SimpleFadeIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // FadeTransition sangat efisien karena dioptimalkan oleh engine Flutter
    return FadeTransition(opacity: _fadeAnimation, child: widget.child);
  }
}
