import 'package:flutter/foundation.dart';

import '../../device_profile/data/device_profile_repository.dart';
import '../../history/data/history_repository.dart';
import '../data/device_repository.dart';

/// ViewModel for the device discovery screen.
///
/// Exposes the current list of discovered devices and a refresh action.
class DeviceDiscoveryViewModel with ChangeNotifier {
  /// Creates a [DeviceDiscoveryViewModel].
  DeviceDiscoveryViewModel({
    required this.repository,
    required this.profileRepository,
    required this.historyRepository,
  });

  final DeviceRepository repository;
  final DeviceProfileRepository profileRepository;
  final HistoryRepository historyRepository;

  List<DeviceInfo> devices = [];
  bool isLoading = false;

  /// Refresh the device list using the repository.
  ///
  /// Devices that are already known (in profiles or history) are filtered out.
  Future<void> refresh() async {
    isLoading = true;
    notifyListeners();
    try {
      final List<DeviceInfo> raw = await repository.discoverDevices();

      final Set<String> known = await _loadKnownIds();

      final Map<String, DeviceInfo> byBase = _filterUnknownById(raw, known);

      devices = byBase.values.toList();
    } catch (err) {
      if (kDebugMode) {
        // Log the error during discovery for debugging.
        print('Error during device discovery: $err');
      }
      devices = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Load known base ids from profiles and history.
  Future<Set<String>> _loadKnownIds() async {
    final known = <String>{};
    final List<DeviceProfile> profiles = await profileRepository.loadAll();
    for (final p in profiles) {
      known.add(p.id);
    }
    final List<Conversation> convs = await historyRepository.loadAll();
    for (final c in convs) {
      known.add(c.id);
    }
    return known;
  }

  /// Deduplicate raw responses by id and filter out known ids.
  Map<String, DeviceInfo> _filterUnknownById(List<DeviceInfo> raw, Set<String> known) {
    final Map<String, DeviceInfo> byBase = {};
    for (final d in raw) {
      if (known.contains(d.id)) {
        continue;
      }
      if (!byBase.containsKey(d.id)) {
        byBase[d.id] = d;
      }
    }
    return byBase;
  }
}
