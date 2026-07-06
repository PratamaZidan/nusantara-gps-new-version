import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nusantara_gps/core/app/app_color_theme.dart';
import 'package:nusantara_gps/presentation/screens/1_auth/login_view_model.dart';
import 'package:nusantara_gps/presentation/widgets/app_button.dart';
import 'package:nusantara_gps/presentation/widgets/default_padding.dart';
import 'package:nusantara_gps/presentation/widgets/rounded_text_field.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.45),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutQuart,
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    // Delay kecil supaya animasi terasa masuk
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoginViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          body: Center(
            child: ListView(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    Image.asset(
                      'assets/images/app_banner.png',
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),

                    // Animated Logo
                    Positioned(
                      bottom: -50,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Image.asset(
                            'assets/images/nusantara_gps.png',
                            width: 300,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 60),

                DefaultPadding(
                  child: Column(
                    children: [
                      RoundedTextField(
                        controller: viewModel.usernameCtrl,
                        hint: "Username",
                        icon: Icons.person_outline_rounded,
                      ),

                      const SizedBox(height: 16),

                      RoundedTextField(
                        controller: viewModel.passwordCtrl,
                        hint: '**********',
                        icon: Icons.lock_outline_rounded,
                        obscureText: viewModel.obsecureText,
                        suffix: IconButton(
                          onPressed: () {
                            viewModel.toggleObsecureText();
                          },
                          icon: Icon(
                            viewModel.obsecureText
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFF9CA3AF),
                            size: 20,
                          ),
                          splashRadius: 20,
                        ),
                      ),

                      const SizedBox(height: 16),

                      rememberCheckBox(viewModel),

                      const SizedBox(height: 16),

                      AppButton(
                        onPressed: viewModel.canSubmit
                            ? () async {
                                final res = await viewModel.submit();

                                res.match(
                                  (_) {
                                    context.go('/splash');
                                  },
                                  (f) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(f.message),
                                      ),
                                    );
                                  },
                                );
                              }
                            : null,
                        isLoading: viewModel.isSubmitting,
                        label: "Login",
                      ),
                    ],
                  ),
                ),

                if (viewModel.error != null)
                  DefaultPadding(
                    child: Text(
                      viewModel.error ?? 'Unknown Error',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Row rememberCheckBox(LoginViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: viewModel.rememberMe,
            onChanged: (v) {
              viewModel.toggleRememberMe();
            },
            side: const BorderSide(
              color: AppColorTheme.gray200,
              width: 1.6,
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            activeColor: const Color(0xFF16A34A),
            checkColor: Colors.white,
          ),
        ),

        const SizedBox(width: 8),

        const Text(
          'Ingatkan saya',
          style: TextStyle(
            color: AppColorTheme.gray800,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}