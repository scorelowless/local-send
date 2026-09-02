import 'package:flutter/foundation.dart';

import '../../device_discovery/data/device_repository.dart';
import '../../device_profile/data/device_profile_repository.dart';
import '../data/history_repository.dart';

/// ViewModel that exposes conversation history.
class HistoryViewModel with ChangeNotifier {
  HistoryViewModel({
    required this.repository,
    required this.deviceRepository,
    required this.profileRepository,
  }) : _reachable = {};

  final HistoryRepository repository;
  final DeviceRepository deviceRepository;
  final DeviceProfileRepository profileRepository;

  List<Conversation> conversations = [];

  /// Map of device id -> device type (e.g. 'phone', 'laptop') loaded from profiles.
  final Map<String, String> deviceTypeMap = {};
  bool isLoading = false;

  final Map<String, bool> _reachable;

  /// Returns whether a device id is currently reachable.
  bool isReachable(String deviceId) => _reachable[deviceId] ?? false;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    try {
      conversations = await repository.loadAll();
      // Sort so favorited conversations come first, then by timestamp desc (newest first)
      conversations.sort((a, b) {
        if (a.favorite && !b.favorite) {
          return -1;
        }
        if (!a.favorite && b.favorite) {
          return 1;
        }
        return b.timestamp.compareTo(a.timestamp);
      });
      // Load device profile types if repository available
      deviceTypeMap.clear();
      try {
        final List<DeviceProfile> profiles = await profileRepository.loadAll();
        for (final p in profiles) {
          deviceTypeMap[p.id] = p.type;
        }
      } catch (_) {
        // ignore
      }
      await refreshReachability();
    } catch (_) {
      conversations = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Refreshes device reachability by querying [DeviceRepository].
  Future<void> refreshReachability() async {
    try {
      final List<DeviceInfo> devices = await deviceRepository.discoverDevices();
      _reachable.clear();
      for (final d in devices) {
        _reachable[d.id] = true;
      }
      notifyListeners();
    } catch (_) {
      // ignore errors
    }
  }

  /// Toggle favorite state for a conversation and persist it.
  Future<void> toggleFavorite(String conversationId) async {
    try {
      // Find existing
      final int idx = conversations.indexWhere((c) => c.id == conversationId);
      if (idx == -1) {
        return;
      }
      final Conversation old = conversations[idx];
      final updated = Conversation(
        id: old.id,
        title: old.title,
        lastMessage: old.lastMessage,
        timestamp: old.timestamp,
        favorite: !old.favorite,
      );
      // Update repository
      await repository.updateFavorite(conversationId, updated.favorite);
      // Update in-memory and re-sort
      conversations[idx] = updated;
      conversations.sort((a, b) {
        if (a.favorite && !b.favorite) {
          return -1;
        }
        if (!a.favorite && b.favorite) {
          return 1;
        }
        return b.timestamp.compareTo(a.timestamp);
      });
      notifyListeners();
    } catch (_) {
      // ignore errors for now
    }
  }

  /// Refresh the whole history view model (convenience wrapper).
  Future<void> refresh() => load();
}
