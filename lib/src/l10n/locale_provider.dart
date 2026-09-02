import 'package:flutter/material.dart';
import '../features/settings/data/settings_store.dart';

/// Small provider that holds the current [Locale] and persists the selection.
class LocaleProvider with ChangeNotifier {
  LocaleProvider({required this.settings});

  final SettingsStore settings;
  Locale? _locale;

  Locale? get locale => _locale;

  Future<void> init() async {
    final String? code = await settings.getString('locale');
    if (code != null && code.isNotEmpty) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale l) async {
    _locale = l;
    await settings.setString('locale', l.languageCode);
    notifyListeners();
  }
}
