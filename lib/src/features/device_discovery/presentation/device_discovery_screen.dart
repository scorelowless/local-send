import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../di/di.dart' as di;
import '../../../l10n/app_localizations.dart';
import '../../../platform/hotspot_helper.dart';
import '../../../platform/network_manager.dart';
import '../../../ui/widgets.dart';
import '../../device_profile/data/device_profile_repository.dart';
import '../../history/data/history_repository.dart';
import '../../history/presentation/history_view_model.dart';
import '../../send_receive/data/send_service.dart';
import '../data/device_repository.dart';
import 'device_add_dialog.dart';
import 'device_discovery_view_model.dart';
import 'device_tile.dart';

class DeviceDiscoveryScreen extends StatefulWidget {
  const DeviceDiscoveryScreen({super.key});

  @override
  State<DeviceDiscoveryScreen> createState() => _DeviceDiscoveryScreenState();
}

class _DeviceDiscoveryScreenState extends State<DeviceDiscoveryScreen> {
  late final DeviceDiscoveryViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = di.getIt<DeviceDiscoveryViewModel>();
    viewModel.refresh();
  }

  Future<void> _handleDeviceTap(DeviceInfo device) async {
    final DeviceProfile? profile = await showDeviceAddDialog(
      context,
      id: device.id,
      initialName: device.name,
    );
    if (profile != null) {
      final normalized = DeviceProfile(
        id: profile.id,
        displayName: profile.displayName,
        type: profile.type,
        sentColorHex: profile.sentColorHex,
        receivedColorHex: profile.receivedColorHex,
      );
      final DeviceProfileRepository repo = di.getIt<DeviceProfileRepository>();
      await repo.save(normalized);
      final HistoryRepository history = di.getIt<HistoryRepository>();
      await history.add(
        Conversation(
          id: normalized.id,
          title: normalized.displayName,
          lastMessage: '',
          timestamp: DateTime.now().toUtc(),
        ),
      );
      try {
        await di.getIt<HistoryViewModel>().refresh();
      } catch (_) {}
      if (!mounted) {
        return;
      }
      final AppLocalizations? loc = AppLocalizations.of(context);
      final String message =
          loc?.deviceAdded(normalized.displayName) ?? 'Device "${normalized.displayName}" added';
      await showMessageDialog(context, message);
      try {
        final SendService sender = di.getIt<SendService>();
        final NetworkManager nm = di.getIt<NetworkManager>();
        final metadata = <String, String>{
          'senderId': nm.localId,
          'receiverId': device.id,
          'senderName': nm.localName,
          'receiverName': device.name,
          'deviceAdded': 'true',
        };
        await sender.sendMessage(Uint8List(0), metadata);
      } catch (_) {}
    }
  }

  Future<bool> _isConnectedToNetwork() async {
    try {
      if (Platform.isAndroid) {
        final bool hotspotOn = await HotspotHelper.isHotspotEnabled();
        if (hotspotOn) {
          return true;
        }
      }

      final List<ConnectivityResult> connResult = await Connectivity().checkConnectivity();
      if (connResult.contains(ConnectivityResult.wifi)) {
        return true;
      }

      if (kIsWeb) {
        return false;
      }
      final List<NetworkInterface> ifaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      if (ifaces.isNotEmpty) {
        return true;
      }
      final List<InternetAddress> result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc?.discoverTitle ?? 'Discover devices')),
      body: AnimatedBuilder(
        animation: viewModel,
        builder: (context, _) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: [
              FutureBuilder<bool>(
                future: _isConnectedToNetwork(),
                builder: (ctx, snap) {
                  final bool connected = snap.data ?? false;
                  final Color bg = connected ? Colors.green.shade50 : Colors.red.shade50;
                  final Color textColor = connected ? Colors.green.shade800 : Colors.red.shade800;
                  final String title = connected
                      ? (loc?.networkConnected ?? 'Connected to network')
                      : (loc?.networkDisconnected ?? 'Not connected - please join a network');
                  return Container(
                    width: double.infinity,
                    color: bg,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(connected ? Icons.wifi : Icons.wifi_off, color: textColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(color: textColor),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  loc?.lanDevicesHeader ?? 'LAN devices',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (viewModel.devices.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(loc?.noDevicesFound ?? 'No devices found'),
                )
              else
                ...viewModel.devices.map((device) {
                  final NetworkManager nm = di.getIt<NetworkManager>();
                  String displayName = device.name;
                  if (device.id == nm.localId) {
                    displayName = 'CURRENT ${device.name}';
                  }
                  final d = DeviceInfo(id: device.id, name: displayName);
                  return DeviceTile(device: d, onTap: () => _handleDeviceTap(d));
                }),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => viewModel.refresh(),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
