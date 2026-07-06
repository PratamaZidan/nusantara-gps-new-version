import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nusantara_gps/core/app/app_color_theme.dart';
import 'package:nusantara_gps/presentation/screens/0_splash/splash_view_model.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();

    Future.microtask(
      () => context.read<SplashViewModel>().checkAuthentication(context),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background map samar
          Positioned.fill(
            child: Opacity(
              opacity: 0.07,
              child: Image.asset(
                'assets/images/app_banner.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Image.asset(
                      'assets/images/pointer_logo.png',
                      width: 120,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: 15),

                    // Title
                    Image.asset(
                      'assets/images/nama_nusantara_gps.png',
                      width: 250,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: 10),

                    // Subtitle
                    const Text(
                      'Smart Vehicle Monitoring',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Loader
                    const CupertinoActivityIndicator(radius: 11),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}