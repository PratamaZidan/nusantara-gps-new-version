abstract class IProfileRepository {
  Future<Map<String, dynamic>> getProfile();

  Future<void> editProfile({
    required String username,
    required String name,
    required String phone,
    required String email,
  });

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  });
}