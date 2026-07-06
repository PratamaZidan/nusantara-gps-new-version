abstract class ISecureStorageService {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
}

class SecureStorageServiceMock implements ISecureStorageService {
  final Map<String, String> _m = {};
  @override
  Future<void> delete(String key) async => _m.remove(key);
  @override
  Future<String?> read(String key) async => _m[key];
  @override
  Future<void> write(String key, String value) async => _m[key] = value;
}
