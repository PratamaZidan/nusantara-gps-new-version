import 'package:flutter/foundation.dart';
import 'package:nusantara_gps/core/service/storage/i_key_value_storage.dart';
import 'package:nusantara_gps/data/repositories/auth_repository_impl.dart';
import 'package:nusantara_gps/domain/entities/auth_status.dart';

class SessionManager {
  final IKeyValueStorage _storage;
  SessionManager(this._storage);
  final _authState = ValueNotifier<AuthStatus>(AuthStatus.authenticated);

  ValueListenable<AuthStatus> get authState => _authState;

  void logout() async {
    await _storage.remove(PrefKeys.userRaw);
    await _storage.remove(PrefKeys.token);
    await _storage.remove(PrefKeys.traccarToken);
    await _storage.remove(PrefKeys.email);
    await _storage.remove(PrefKeys.username);
    await _storage.remove(PrefKeys.password);
    await _storage.remove(PrefKeys.phone);
    _authState.value = AuthStatus.unauthenticated;
  }

  void login() {
    _authState.value = AuthStatus.authenticated;
  }
}
