abstract class IKeyValueStorage {
  Future<bool> setString(String key, String value);
  Future<String?> getString(String key);
  Future<bool> remove(String key);
  Future<bool> clear();
}
