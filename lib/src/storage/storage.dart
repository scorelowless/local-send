import 'package:shared_preferences/shared_preferences.dart';

/// Storage abstraction for simple key-value persistence.
///
/// This allows swapping `SharedPreferences` with `flutter_secure_storage` or
/// other implementations later without changing consumers.
abstract class Storage {
  /// Initialize the storage if necessary.
  Future<void> init();

  /// Writes a string value for [key].
  Future<void> writeString(String key, String value);

  /// Reads a string value for [key], or `null` if not found.
  Future<String?> readString(String key);

  /// Removes the value for [key].
  Future<void> remove(String key);

  /// Clears all stored values.
  Future<void> clear();
}

/// Simple implementation of [Storage] using `SharedPreferences`.
class PrefsStorage implements Storage {
  SharedPreferences? _prefs;

  /// Initialize the underlying SharedPreferences instance.
  @override
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  Future<void> writeString(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  @override
  Future<String?> readString(String key) async {
    return _prefs?.getString(key);
  }

  @override
  Future<void> remove(String key) async {
    await _prefs?.remove(key);
  }

  @override
  Future<void> clear() async {
    await _prefs?.clear();
  }
}
