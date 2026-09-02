import 'package:flutter/material.dart';

import '../../../di/di.dart' as di;
import '../../../l10n/app_localizations.dart';
import '../../../platform/file_opener.dart';
import '../../../platform/network_manager.dart';
import '../../../ui/widgets.dart';
import '../../../utils/helpers.dart' as utils;
import '../../device_discovery/data/device_repository.dart';
import '../../device_discovery/presentation/device_add_dialog.dart';
import '../../device_profile/data/device_profile_repository.dart';
import '../../history/data/history_repository.dart';
import 'conversation_composer.dart';
import 'conversation_detail_view_model.dart';
import 'history_view_model.dart';
import 'message_bubble.dart';

/// Chat-style conversation screen showing merged sent and received messages.
class ConversationDetailScreen extends StatefulWidget {
  const ConversationDetailScreen({super.key, required this.deviceId, required this.title});

  final String deviceId;
  final String title;

  @override
  State<ConversationDetailScreen> createState() => _ConversationDetailScreenState();
}

class _ConversationDetailScreenState extends State<ConversationDetailScreen> {
  late final ConversationDetailViewModel vm;
  Color? _sentColor;
  Color? _receivedColor;
  String _displayTitle = '';
  String? _deviceType;
  bool _isReachable = false;

  Color _hexToColor(String hex) => utils.hexToColor(hex);

  Future<void> _loadProfile() async {
    try {
      final DeviceProfileRepository repo = di.getIt<DeviceProfileRepository>();
      final List<DeviceProfile> profiles = await repo.loadAll();
      DeviceProfile? found;
      for (final p in profiles) {
        if (p.id == widget.deviceId) {
          found = p;
          break;
        }
      }
      if (found != null) {
        _sentColor = _hexToColor(found.sentColorHex);
        _receivedColor = _hexToColor(found.receivedColorHex);
        _displayTitle = found.displayName;
        _deviceType = found.type;
        setState(() {});
        await _updateReachability();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            final String initialTitle = widget.title;
            final DeviceProfile? profile = await showDeviceAddDialog(
              context,
              id: widget.deviceId,
              initialName: initialTitle,
            );
            if (!mounted) {
              return;
            }
            if (profile != null) {
              await repo.save(profile);
              try {
                final HistoryRepository historyRepo = di.getIt<HistoryRepository>();
                await historyRepo.updateTitle(profile.id, profile.displayName);
              } catch (_) {}
              try {
                await di.getIt<HistoryViewModel>().refresh();
              } catch (_) {}
              if (!mounted) {
                return;
              }
              setState(() {
                _sentColor = _hexToColor(profile.sentColorHex);
                _receivedColor = _hexToColor(profile.receivedColorHex);
                _displayTitle = profile.displayName;
                _deviceType = profile.type;
              });
              await _updateReachability();
            }
          } catch (_) {}
        });
      }
    } catch (_) {}
  }

  Future<void> _updateReachability() async {
    try {
      final NetworkManager nm = di.getIt<NetworkManager>();
      var reachable = false;

      try {
        final PeerInfo? peer = nm.getPeer(widget.deviceId);
        if (peer != null) {
          reachable = true;
        }
      } catch (_) {}

      if (!reachable) {
        try {
          final DeviceRepository deviceRepo = di.getIt<DeviceRepository>();
          final List<DeviceInfo> discovered = await deviceRepo.discoverDevices();
          for (final d in discovered) {
            if (d.id == widget.deviceId) {
              reachable = true;
              break;
            }
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() => _isReachable = reachable);
      } else {
        _isReachable = reachable;
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    vm = ConversationDetailViewModel(
      deviceId: widget.deviceId,
      sendRepository: di.getIt(),
      receiveRepository: di.getIt(),
      fileOpener: di.getIt<FileOpener>(),
    );
    vm.load();
    _displayTitle = widget.title;
    _loadProfile();
  }

  @override
  void dispose() {
    try {
      vm.dispose();
    } catch (_) {}
    super.dispose();
  }

  /// Show a message using this state's BuildContext; guards `mounted`.
  Future<void> _showParentMessage(String message) async {
    if (!mounted) {
      return;
    }
    await showMessageDialog(context, message);
  }

  Widget _messageBubbleBuilder(MessageEntry entry) {
    return MessageBubble(
      entry: entry,
      sentColor: _sentColor,
      receivedColor: _receivedColor,
      vm: vm,
      onOpenFile: (path) async {
        final String msg = AppLocalizations.of(context)?.failedToOpenFile ?? 'Failed to open file';
        final bool success = await vm.openFile(path);
        if (!success) {
          await _showParentMessage(msg);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (_deviceType != null) ...[
              Icon(_iconForDeviceType(_deviceType!), size: 20),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(_displayTitle)),
            const SizedBox(width: 8),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _isReachable ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context)?.editDeviceTitle ?? 'Edit device',
            icon: const Icon(Icons.edit),
            onPressed: () async {
              try {
                final dialogContext = context;
                final AppLocalizations? locBefore = AppLocalizations.of(dialogContext);
                final DeviceProfileRepository repo = di.getIt<DeviceProfileRepository>();
                final List<DeviceProfile> profiles = await repo.loadAll();
                DeviceProfile? existing;
                for (final p in profiles) {
                  if (p.id == widget.deviceId) {
                    existing = p;
                    break;
                  }
                }
                final String? title = locBefore?.editDeviceTitle;
                final String? confirm = locBefore?.saveButtonLabel;
                final DeviceProfile? edited = await showDeviceAddDialog(
                  dialogContext,
                  id: widget.deviceId,
                  initialName: existing?.displayName ?? _displayTitle,
                  initialType: existing?.type ?? _deviceType ?? 'other',
                  initialSentColorHex:
                      existing?.sentColorHex ??
                      (_sentColor != null ? utils.colorToHex(_sentColor!) : null),
                  initialReceivedColorHex:
                      existing?.receivedColorHex ??
                      (_receivedColor != null ? utils.colorToHex(_receivedColor!) : null),
                  title: title,
                  confirmLabel: confirm,
                );

                if (!mounted) {
                  return;
                }

                if (edited != null) {
                  final normalizedProfile = DeviceProfile(
                    id: edited.id,
                    displayName: edited.displayName,
                    type: edited.type,
                    sentColorHex: edited.sentColorHex,
                    receivedColorHex: edited.receivedColorHex,
                    endpoint: edited.endpoint,
                  );
                  await repo.save(normalizedProfile);
                  try {
                    final HistoryRepository historyRepo = di.getIt<HistoryRepository>();
                    await historyRepo.updateTitle(edited.id, normalizedProfile.displayName);
                  } catch (_) {}
                  try {
                    await di.getIt<HistoryViewModel>().refresh();
                  } catch (_) {}
                  if (!mounted) {
                    return;
                  }
                  setState(() {
                    _sentColor = _hexToColor(normalizedProfile.sentColorHex);
                    _receivedColor = _hexToColor(normalizedProfile.receivedColorHex);
                    _displayTitle = normalizedProfile.displayName;
                    _deviceType = normalizedProfile.type;
                  });
                  await _updateReachability();
                }
              } catch (_) {}
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: vm,
        builder: (context, _) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (vm.messages.isEmpty) {
            return Center(child: Text(AppLocalizations.of(context)?.noMessages ?? 'No messages'));
          }
          return ListView.builder(
            reverse: true,
            itemCount: vm.messages.length,
            itemBuilder: (context, index) {
              final int revIndex = vm.messages.length - 1 - index;
              final MessageEntry entry = vm.messages[revIndex];
              return _messageBubbleBuilder(entry);
            },
          );
        },
      ),
      bottomNavigationBar: Composer(
        deviceId: widget.deviceId,
        vm: vm,
        isReachable: _isReachable,
        showMessage: _showParentMessage,
      ),
    );
  }

  IconData _iconForDeviceType(String deviceType) {
    switch (deviceType.toLowerCase()) {
      case 'phone':
        return Icons.phone_android;
      case 'tablet':
        return Icons.tablet_android;
      case 'laptop':
        return Icons.laptop;
      case 'desktop':
        return Icons.desktop_windows;
      case 'watch':
        return Icons.watch;
      default:
        return Icons.device_unknown;
    }
  }
}
