import '../../../storage/storage.dart';

/// Simple settings store abstraction for user preferences.
abstract class SettingsStore {
  Future<void> init();

  Future<void> setString(String key, String value);

  Future<String?> getString(String key);

  Future<void> remove(String key);
}

/// SharedPreferences-backed SettingsStore implementation using [Storage] adapter.
class SettingsStoreImpl implements SettingsStore {
  SettingsStoreImpl({required this.storage});
  final Storage storage;

  @override
  Future<void> init() async {
    // Storage is initialized by DI earlier; nothing to do here for now.
  }

  @override
  Future<String?> getString(String key) => storage.readString(key);

  @override
  Future<void> remove(String key) => storage.remove(key);

  @override
  Future<void> setString(String key, String value) => storage.writeString(key, value);
}
