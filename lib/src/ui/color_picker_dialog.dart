import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../utils/helpers.dart' as utils;
import 'swatch_grid.dart';

Future<Map<String, String>?> showColorPickerDialog(
  BuildContext context, {
  required Color initialSent,
  required Color initialReceived,
}) {
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

  var sent = initialSent;
  var received = initialReceived;

  final AppLocalizations? loc = AppLocalizations.of(context);

  return showDialog<Map<String, String>>(
    context: context,
    builder: (c) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: Text(loc?.sentMessageColorLabel ?? 'Choose colors'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc?.sentMessageColorLabel ?? 'Sent message color'),
                  const SizedBox(height: 8),
                  SwatchGrid(
                    swatches: materialSwatches,
                    selected: sent,
                    onPick: (c) => setState(() => sent = c),
                  ),
                  const SizedBox(height: 12),
                  Text(loc?.receivedMessageColorLabel ?? 'Received message color'),
                  const SizedBox(height: 8),
                  SwatchGrid(
                    swatches: materialSwatches,
                    selected: received,
                    onPick: (c) => setState(() => received = c),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(loc?.cancelLabel ?? 'Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(
                  ctx,
                ).pop({'sent': colorToHex(sent), 'received': colorToHex(received)}),
                child: Text(loc?.addButtonLabel ?? 'OK'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<String?> showSingleColorPickerDialog(
  BuildContext context, {
  required Color initial,
  String? title,
}) {
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

  var selected = initial;
  final AppLocalizations? loc = AppLocalizations.of(context);

  return showDialog<String>(
    context: context,
    builder: (c) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: Text(title ?? (loc?.sentMessageColorLabel ?? 'Sent message color')),
            content: SingleChildScrollView(
              child: SwatchGrid(
                swatches: materialSwatches,
                selected: selected,
                onPick: (col) => setState(() => selected = col),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(loc?.cancelLabel ?? 'Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(colorToHex(selected)),
                child: Text(loc?.addButtonLabel ?? 'OK'),
              ),
            ],
          );
        },
      );
    },
  );
}
