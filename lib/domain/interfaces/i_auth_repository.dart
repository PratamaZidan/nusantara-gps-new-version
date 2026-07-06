import 'package:nusantara_gps/core/config/result.dart';
import 'package:nusantara_gps/data/models/user_model.dart';

abstract class IAuthRepository {
  Future<Result<User, Failure>> login(String username, String password);
  Future<void> logout();
  Future<bool> checkSession();
}
