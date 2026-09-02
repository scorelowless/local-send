import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../ui/swatch_grid.dart';
import '../../../ui/widgets.dart';
import '../../../utils/helpers.dart' as utils;
import '../../device_profile/data/device_profile_repository.dart';

/// Dialog to confirm adding a discovered device with metadata.
/// Returns a [DeviceProfile] on success or null if cancelled.
Future<DeviceProfile?> showDeviceAddDialog(
  BuildContext context, {
  required String id,
  String? initialName,
  String? initialType,
  String? initialSentColorHex,
  String? initialReceivedColorHex,
  String? title,
  String? confirmLabel,
}) {
  final formKey = GlobalKey<FormState>();
  String name = initialName ?? '';
  String type = initialType ?? 'laptop';
  String sentColorHex = initialSentColorHex ?? '#2196F3'; // blue
  String receivedColorHex = initialReceivedColorHex ?? '#9E9E9E'; // grey

  final materialSwatches = <Color>[
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.grey,
    Colors.red,
    Colors.amber,
    Colors.teal,
    Colors.indigo,
  ];

  String colorToHex(Color c) => utils.colorToHex(c);
  Color hexToColor(String hex) => utils.hexToColor(hex);

  final AppLocalizations? loc = AppLocalizations.of(context);

  return showDialog<DeviceProfile>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final Color selectedSent = hexToColor(sentColorHex);
        final Color selectedReceived = hexToColor(receivedColorHex);

        return AlertDialog(
          title: Text(title ?? loc?.addDeviceTitle ?? 'Add device'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: name,
                    decoration: InputDecoration(labelText: loc?.displayNameLabel ?? 'Display name'),
                    onChanged: (v) => name = v,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? (loc?.enterANameError ?? 'Enter a name') : null,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: type,
                    items: [
                      DropdownMenuItem(value: 'laptop', child: Text(loc?.laptopLabel ?? 'Laptop')),
                      DropdownMenuItem(value: 'phone', child: Text(loc?.phoneLabel ?? 'Phone')),
                      DropdownMenuItem(value: 'other', child: Text(loc?.otherLabel ?? 'Other')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => type = v);
                      }
                    },
                    decoration: InputDecoration(labelText: loc?.deviceTypeLabel ?? 'Device type'),
                  ),
                  const SizedBox(height: 12),
                  Text(loc?.sentMessageColorLabel ?? 'Sent message color'),
                  const SizedBox(height: 8),
                  SwatchGrid(
                    swatches: materialSwatches,
                    selected: selectedSent,
                    onPick: (c) => setState(() => sentColorHex = colorToHex(c)),
                  ),
                  const SizedBox(height: 12),
                  Text(loc?.receivedMessageColorLabel ?? 'Received message color'),
                  const SizedBox(height: 8),
                  SwatchGrid(
                    swatches: materialSwatches,
                    selected: selectedReceived,
                    onPick: (c) => setState(() => receivedColorHex = colorToHex(c)),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(loc?.cancelLabel ?? 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(context).pop(
                    DeviceProfile(
                      id: id,
                      displayName: name,
                      type: type,
                      sentColorHex: sentColorHex,
                      receivedColorHex: receivedColorHex,
                    ),
                  );
                }
              },
              child: Text(confirmLabel ?? loc?.addButtonLabel ?? 'Add'),
            ),
          ],
        );
      },
    ),
  );
}
