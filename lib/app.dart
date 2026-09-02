import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'src/di/di.dart' as di;
import 'src/features/device_discovery/presentation/device_discovery_screen.dart';
import 'src/features/history/presentation/history_screen.dart';
import 'src/features/settings/presentation/settings_screen.dart';
import 'src/l10n/app_localizations.dart';
import 'src/l10n/locale_provider.dart';

/// Root widget that hosts localization and the app's bottom tabs.
class App extends StatefulWidget {
  /// Creates the App.
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  int _currentIndex = 0;

  Widget _pageForIndex(int index) {
    switch (index) {
      case 0:
        return const HistoryScreen();
      case 1:
        return const DeviceDiscoveryScreen();
      case 2:
        return const SettingsScreen();
      default:
        return const HistoryScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final LocaleProvider localeProvider = di.getIt<LocaleProvider>();
    return AnimatedBuilder(
      animation: localeProvider,
      builder: (context, _) {
        return MaterialApp(
          locale: localeProvider.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          onGenerateTitle: (context) =>
              AppLocalizations.of(context)?.appTitle ?? 'LocalSend - Flutter',
          theme: ThemeData.from(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: SafeArea(child: _pageForIndex(_currentIndex)),
                bottomNavigationBar: BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: (index) => setState(() => _currentIndex = index),
                  items: [
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.history),
                      label: AppLocalizations.of(context)?.historyLabel ?? 'History',
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.devices),
                      label: AppLocalizations.of(context)?.discoverLabel ?? 'Discover',
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.settings),
                      label: AppLocalizations.of(context)?.settingsLabel ?? 'Settings',
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
