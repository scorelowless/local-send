import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class DisplayNameEditor extends StatelessWidget {
  const DisplayNameEditor({super.key, required this.controller, required this.onSave});

  final TextEditingController controller;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth < 200 ? constraints.maxWidth : 200;
            return SizedBox(
              width: width,
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)?.displayNameLabel ?? 'Display name',
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: onSave,
          child: Text(AppLocalizations.of(context)?.okLabel ?? 'Save'),
        ),
      ],
    );
  }
}
