import 'dart:convert';

import '../../../storage/storage.dart';

abstract class DeviceProfileRepository {
  Future<List<DeviceProfile>> loadAll();
  Future<void> save(DeviceProfile profile);
  Future<void> remove(String id);
  Future<void> clear();

  /// Update specific fields of a profile identified by [id].
  /// If the profile does not exist, it will be created using [defaultDisplayName]
  /// for the display name (or [id] if not provided) and other provided fields.
  Future<void> updateProfileFields(
    String id, {
    String? displayName,
    String? type,
    String? sentColorHex,
    String? receivedColorHex,
    String? endpoint,
    String? defaultDisplayName,
  });
}

/// Model describing persisted device profile (user's chosen display name, type and colors).
class DeviceProfile {
  const DeviceProfile({
    required this.id,
    required this.displayName,
    required this.type,
    required this.sentColorHex,
    required this.receivedColorHex,
    this.endpoint,
  });

  factory DeviceProfile.fromJson(Map<String, dynamic> json) => DeviceProfile(
    id: json['id'] as String,
    displayName: json['displayName'] as String,
    type: json['type'] as String,
    sentColorHex: json['sentColorHex'] as String,
    receivedColorHex: json['receivedColorHex'] as String,
    endpoint: json['endpoint'] as String?,
  );

  final String id;
  final String displayName;
  final String type;
  final String sentColorHex;
  final String receivedColorHex;
  final String? endpoint;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'displayName': displayName,
    'type': type,
    'sentColorHex': sentColorHex,
    'receivedColorHex': receivedColorHex,
    if (endpoint != null) 'endpoint': endpoint,
  };
}

class DeviceProfileRepositoryImpl implements DeviceProfileRepository {
  DeviceProfileRepositoryImpl({required this.storage});
  static const String _kKey = 'device_profiles';
  static const String _kBackup = 'device_profiles_corrupt_backup';

  final Storage storage;

  @override
  Future<void> clear() => storage.remove(_kKey);

  @override
  Future<List<DeviceProfile>> loadAll() async {
    final String? raw = await storage.readString(_kKey);
    if (raw == null || raw.isEmpty) {
      return <DeviceProfile>[];
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => DeviceProfile.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      try {
        await storage.writeString(_kBackup, raw);
      } catch (_) {}
      try {
        await storage.remove(_kKey);
      } catch (_) {}
      return <DeviceProfile>[];
    }
  }

  @override
  Future<void> remove(String id) async {
    final List<DeviceProfile> current = await loadAll();
    final List<DeviceProfile> updated = current.where((p) => p.id != id).toList();
    await storage.writeString(_kKey, jsonEncode(updated.map((e) => e.toJson()).toList()));
  }

  @override
  Future<void> save(DeviceProfile profile) async {
    final List<DeviceProfile> current = await loadAll();
    final updated = List<DeviceProfile>.from(current.where((p) => p.id != profile.id))
      ..insert(0, profile);
    await storage.writeString(_kKey, jsonEncode(updated.map((e) => e.toJson()).toList()));
  }

  @override
  Future<void> updateProfileFields(
    String id, {
    String? displayName,
    String? type,
    String? sentColorHex,
    String? receivedColorHex,
    String? endpoint,
    String? defaultDisplayName,
  }) async {
    final List<DeviceProfile> current = await loadAll();
    DeviceProfile? existing;
    for (final p in current) {
      if (p.id == id) {
        existing = p;
        break;
      }
    }
    final String finalDisplayName = existing?.displayName ?? (defaultDisplayName ?? id);
    final String finalType = existing?.type ?? (type ?? 'other');
    final String finalSent = sentColorHex ?? existing?.sentColorHex ?? '#2196F3';
    final String finalReceived = receivedColorHex ?? existing?.receivedColorHex ?? '#EEEEEE';
    final String? finalEndpoint = endpoint ?? existing?.endpoint;

    final profile = DeviceProfile(
      id: existing?.id ?? id,
      displayName: displayName ?? finalDisplayName,
      type: type ?? finalType,
      sentColorHex: finalSent,
      receivedColorHex: finalReceived,
      endpoint: finalEndpoint,
    );

    final updated = List<DeviceProfile>.from(current.where((p) => p.id != profile.id))
      ..insert(0, profile);
    await storage.writeString(_kKey, jsonEncode(updated.map((e) => e.toJson()).toList()));
  }
}
