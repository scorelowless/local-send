import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Shows a simple informational dialog with an OK button.
/// The OK button label is taken from localizations (okLabel) when available.
Future<void> showMessageDialog(BuildContext context, String message) {
  final AppLocalizations? loc = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.of(c).pop(), child: Text(loc?.okLabel ?? 'OK')),
      ],
    ),
  );
}
