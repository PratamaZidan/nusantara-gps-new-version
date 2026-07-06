import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nusantara_gps/domain/interfaces/i_auth_repository.dart';

class SplashViewModel extends ChangeNotifier {
  final IAuthRepository _authRepo;

  SplashViewModel(this._authRepo);

  Future<void> checkAuthentication(BuildContext context) async {
    // minimal tampil splash
    await Future.delayed(const Duration(seconds: 2));

    final ok = await _authRepo.checkSession();

    if (!context.mounted) return;

    if (ok) {
      context.go("/maps");
    } else {
      context.go("/login");
    }
  }
}