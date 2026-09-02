import '../../../platform/network_manager.dart';

/// Abstract repository to discover nearby devices.
///
/// Implementations should provide a stream or a method to list devices
/// available on the local network or via platform-specific transports.
abstract class DeviceRepository {
  /// Returns a list of currently discovered devices.
  Future<List<DeviceInfo>> discoverDevices();
}

/// Simple model describing a discovered device.
class DeviceInfo {
  /// Creates a discoverable device info instance.
  const DeviceInfo({required this.id, required this.name});

  /// Device identifier (could be IP, UUID, or other transport-specific ID).
  final String id;

  /// Human-friendly name for display.
  final String name;
}

/// Device repository implementation that delegates discovery to the
/// platform-agnostic [NetworkManager]
class DeviceRepositoryImpl implements DeviceRepository {
  DeviceRepositoryImpl({required this.networkManager});

  final NetworkManager networkManager;

  @override
  Future<List<DeviceInfo>> discoverDevices() async {
    try {
      final List<DeviceInfo> devices = [];
      final List<PeerInfo> raw = await networkManager.discoverDevices();
      for (final m in raw) {
        final String id = m.id;
        final String name = m.name;
        devices.add(DeviceInfo(id: id, name: name));
      }
      return devices;
    } catch (_) {
      // On errors, return an empty list — callers may surface UI feedback.
      return <DeviceInfo>[];
    }
  }
}
