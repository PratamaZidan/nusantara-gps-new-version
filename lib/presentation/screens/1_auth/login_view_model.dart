import 'package:flutter/material.dart';
import 'package:nusantara_gps/core/config/result.dart';
import 'package:nusantara_gps/domain/interfaces/i_auth_repository.dart';
import 'package:nusantara_gps/domain/manager/session_manager.dart';

class LoginViewModel extends ChangeNotifier {
  final IAuthRepository _authRepo;
  final SessionManager _sessionManager;
  LoginViewModel(this._authRepo, this._sessionManager) {
    usernameCtrl.addListener(_onTextChanged);
    passwordCtrl.addListener(_onTextChanged);
  }

  final TextEditingController usernameCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();

  bool rememberMe = false;
  bool _isSubmitting = false;
  String? _error;

  bool _obsecureText = true;
  bool get obsecureText => _obsecureText;
  void toggleObsecureText() {
    _obsecureText = !_obsecureText;
    notifyListeners();
  }

  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  bool get canSubmit =>
    _validateUsername(usernameCtrl.text) &&
    _validatePassword(passwordCtrl.text) &&
    !_isSubmitting;

  bool _validateUsername(String v) => v.trim().isNotEmpty;

  void toggleRememberMe() {
    rememberMe = !rememberMe;
    notifyListeners();
  }

  Future<Result<Unit, Failure>> submit() async {
    if (!canSubmit) {
      return const Error(Failure(FailureType.unknown, 'Form belum valid.'));
    }
    _setSubmitting(true);
    _setError(null);

    final result = await _authRepo.login(
      usernameCtrl.text.trim(),
      passwordCtrl.text,
    );

    result.match((user) {}, (failure) {
      _setError(failure.message);
    });

    _setSubmitting(false);
    return result.match<Result<Unit, Failure>>((_) {
      _sessionManager.login();
      return const Success(Unit());
    }, (f) => Error(f));
  }

  // — util kecil —
  void _onTextChanged() => notifyListeners();
  void _setSubmitting(bool v) {
    _isSubmitting = v;
    notifyListeners();
  }

  void _setError(String? msg) {
    _error = msg;
    notifyListeners();
  }

  bool _validateEmail(String v) => RegExp(r'^.+@.+\..+$').hasMatch(v.trim());
  bool _validatePassword(String v) =>
      v.trim().isNotEmpty; // ganti policy jika perlu

  @override
  void dispose() {
    usernameCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }
}

class Unit {
  const Unit();
}

const unit = Unit();
