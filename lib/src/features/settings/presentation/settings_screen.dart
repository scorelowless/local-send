import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import '../../../di/di.dart' as di;
import '../../../l10n/app_localizations.dart';
import '../../../l10n/locale_provider.dart';
import '../../../platform/network_manager.dart';
import '../../../storage/storage.dart';
import '../../../ui/widgets.dart';
import '../../settings/data/settings_store.dart';
import 'display_name_editor.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsStore _settings = di.getIt<SettingsStore>();
  final LocaleProvider _lp = di.getIt<LocaleProvider>();
  final TextEditingController _displayNameController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final String? dn = await _settings.getString('displayName');
    if (dn != null) {
      _displayNameController.text = dn;
    } else {
      try {
        final NetworkManager nm = di.getIt<NetworkManager>();
        _displayNameController.text = nm.localName;
      } catch (_) {
        _displayNameController.text = Platform.localHostname;
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _saveDisplayName() async {
    final String v = _displayNameController.text.trim();
    if (v.isEmpty) {
      return;
    }
    await _settings.setString('displayName', v);
    try {
      final NetworkManager _ = di.getIt<NetworkManager>()..localName = v;
    } catch (_) {}
    if (!mounted) {
      return;
    }
    final String msg = AppLocalizations.of(context)?.displayNameSaved(v) ?? 'Display name saved';
    await showMessageDialog(context, msg);
  }

  Future<void> _eraseAllData() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.eraseConfirmTitle ?? 'Erase all data'),
        content: Text(
          AppLocalizations.of(context)?.eraseConfirmBody ??
              'This will remove history, transfers and device profiles. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: Text(AppLocalizations.of(c)?.cancelLabel ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: Text(AppLocalizations.of(c)?.eraseLabel ?? 'Erase'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      final Storage storage = di.getIt<Storage>();
      await storage.clear();
      try {
        await _settings.remove('displayName');
      } catch (_) {}

      final String defaultName = Platform.localHostname;
      _displayNameController.text = defaultName;
      try {
        final NetworkManager _ = di.getIt<NetworkManager>()..localName = defaultName;
      } catch (_) {}

      try {
        if (mounted) {
          FocusScope.of(context).unfocus();
        }
      } catch (_) {}
      _displayNameController.selection = TextSelection.collapsed(offset: defaultName.length);
      setState(() {});

      if (!mounted) {
        return;
      }
      await showMessageDialog(
        context,
        AppLocalizations.of(context)?.allDataErased ?? 'All data erased',
      );
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String currentCode =
        _lp.locale?.languageCode ?? Localizations.localeOf(context).languageCode;
    final languages = <String, String>{
      'en': '🇬🇧 English',
      'de': '🇩🇪 Deutsch',
      'pl': '🇵🇱 Polski',
    };

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)?.settingsTitle ?? 'Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(AppLocalizations.of(context)?.languageLabel ?? 'Language'),
                  const SizedBox(height: 8),
                  _LanguageDropdown(
                    currentCode: currentCode,
                    languages: languages,
                    lp: _lp,
                    onLocaleChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 24),

                  DisplayNameEditor(controller: _displayNameController, onSave: _saveDisplayName),

                  const SizedBox(height: 24),
                  _EraseAllButton(onErase: _eraseAllData),
                ],
              ),
      ),
    );
  }
}

class _LanguageDropdown extends StatelessWidget {
  const _LanguageDropdown({
    required this.currentCode,
    required this.languages,
    required this.lp,
    required this.onLocaleChanged,
  });

  final String currentCode;
  final Map<String, String> languages;
  final LocaleProvider lp;
  final VoidCallback onLocaleChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: currentCode,
      items: AppLocalizations.supportedLocales
          .map(
            (l) => DropdownMenuItem(
              value: l.languageCode,
              child: Text(languages[l.languageCode] ?? l.languageCode),
            ),
          )
          .toList(),
      onChanged: (code) async {
        if (code == null) {
          return;
        }
        await lp.setLocale(Locale(code));
        onLocaleChanged();
      },
    );
  }
}

class _EraseAllButton extends StatelessWidget {
  const _EraseAllButton({required this.onErase});

  final Future<void> Function() onErase;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
      onPressed: onErase,
      child: Text(AppLocalizations.of(context)?.eraseAllDataLabel ?? 'Erase all data'),
    );
  }
}
