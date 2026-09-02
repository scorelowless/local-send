import 'package:flutter/material.dart';
import '../data/device_repository.dart';

/// Simple tile representing a discovered device.
class DeviceTile extends StatelessWidget {
  /// Creates a [DeviceTile].
  const DeviceTile({super.key, required this.device, this.onTap});

  final DeviceInfo device;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(device.name),
      subtitle: Text(device.id),
      onTap: onTap,
      leading: const Icon(Icons.devices),
    );
  }
}
