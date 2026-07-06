import 'package:shared_preferences/shared_preferences.dart';

import 'i_key_value_storage.dart';

class SharedPrefsStorage implements IKeyValueStorage {
  SharedPreferences? _prefs;

  Future<SharedPreferences> _instance() async =>
      _prefs ??= await SharedPreferences.getInstance();

  @override
  Future<bool> setString(String key, String value) async {
    final prefs = await _instance();
    return prefs.setString(key, value);
  }

  @override
  Future<String?> getString(String key) async {
    final prefs = await _instance();
    return prefs.getString(key);
  }

  @override
  Future<bool> remove(String key) async {
    final prefs = await _instance();
    return prefs.remove(key);
  }

  @override
  Future<bool> clear() async {
    final prefs = await _instance();
    return prefs.clear();
  }
}
