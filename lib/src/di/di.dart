// DI bootstrap using get_it.

import 'dart:async';

import 'package:get_it/get_it.dart';

import '../features/device_discovery/data/device_repository.dart';
import '../features/device_discovery/presentation/device_discovery_view_model.dart';
import '../features/device_profile/data/device_profile_repository.dart';
import '../features/history/data/history_repository.dart';
import '../features/history/presentation/history_view_model.dart';
import '../features/send_receive/data/receive_listener.dart';
import '../features/send_receive/data/receive_repository.dart';
import '../features/send_receive/data/send_repository.dart';
import '../features/send_receive/data/send_service.dart';
import '../features/settings/data/settings_store.dart';
import '../l10n/locale_provider.dart';
import '../platform/file_opener.dart';
import '../platform/network_manager.dart';
import '../storage/storage.dart';

final GetIt getIt = GetIt.instance;

/// Configure dependency injection and register core singletons.
Future<void> setupGetIt() async {
  if (!getIt.isRegistered<Storage>()) {
    final Storage storage = PrefsStorage();
    await storage.init();
    getIt.registerSingleton<Storage>(storage);
  }

  if (!getIt.isRegistered<HistoryRepository>()) {
    getIt.registerSingleton<HistoryRepository>(HistoryRepositoryImpl(storage: getIt<Storage>()));
  }

  // Register settings store early so other singletons can read persisted prefs.
  if (!getIt.isRegistered<SettingsStore>()) {
    getIt.registerSingleton<SettingsStore>(SettingsStoreImpl(storage: getIt<Storage>()));
  }

  // Register NetworkManager. Use saved display name from settings store as the localName so discovery advertises it.
  if (!getIt.isRegistered<NetworkManager>()) {
    final SettingsStore settings = getIt<SettingsStore>();
    final String? displayName = await settings.getString('displayName');
    final nm = NetworkManagerImpl(localName: displayName);
    await nm.init();
    getIt.registerSingleton<NetworkManager>(nm);
  }

  // Device repository: provides discovered devices list (platform-backed)
  if (!getIt.isRegistered<DeviceRepository>()) {
    getIt.registerSingleton<DeviceRepository>(
      DeviceRepositoryImpl(networkManager: getIt<NetworkManager>()),
    );
  }
  if (!getIt.isRegistered<DeviceProfileRepository>()) {
    getIt.registerSingleton<DeviceProfileRepository>(
      DeviceProfileRepositoryImpl(storage: getIt<Storage>()),
    );
  }

  // Send/receive persistence
  if (!getIt.isRegistered<SendRepository>()) {
    getIt.registerSingleton<SendRepository>(SendRepositoryImpl(storage: getIt<Storage>()));
  }

  if (!getIt.isRegistered<ReceiveRepository>()) {
    getIt.registerSingleton<ReceiveRepository>(ReceiveRepositoryImpl(storage: getIt<Storage>()));
  }

  // Ensure we listen to incoming network data and persist received transfers
  if (!getIt.isRegistered<ReceiveListener>()) {
    final receiveListener = ReceiveListenerImpl(
      stream: getIt<NetworkManager>().receiveStream,
      repository: getIt<ReceiveRepository>(),
      historyRepository: getIt<HistoryRepository>(),
      deviceProfileRepository: getIt<DeviceProfileRepository>(),
    );
    getIt.registerSingleton<ReceiveListener>(receiveListener);
  }

  // Register SendService after SendRepository so it can be injected.
  if (!getIt.isRegistered<SendService>()) {
    // Provide repository and network manager so SendServiceImpl can perform framed sends.
    getIt.registerSingleton<SendService>(
      SendServiceImpl(repository: getIt<SendRepository>(), networkManager: getIt<NetworkManager>()),
    );
  }

  // Register platform-agnostic FileOpener so UI/ViewModels can open files.
  if (!getIt.isRegistered<FileOpener>()) {
    getIt.registerSingleton<FileOpener>(FileOpenerImpl());
  }

  // ViewModel factories
  if (!getIt.isRegistered<HistoryViewModel>()) {
    getIt.registerFactory<HistoryViewModel>(
      () => HistoryViewModel(
        repository: getIt<HistoryRepository>(),
        deviceRepository: getIt<DeviceRepository>(),
        profileRepository: getIt<DeviceProfileRepository>(),
      ),
    );
  }
  if (!getIt.isRegistered<DeviceDiscoveryViewModel>()) {
    getIt.registerFactory<DeviceDiscoveryViewModel>(
      () => DeviceDiscoveryViewModel(
        repository: getIt<DeviceRepository>(),
        profileRepository: getIt<DeviceProfileRepository>(),
        historyRepository: getIt<HistoryRepository>(),
      ),
    );
  }

  // Register LocaleProvider singleton
  if (!getIt.isRegistered<LocaleProvider>()) {
    final localeProvider = LocaleProvider(settings: getIt<SettingsStore>());
    await localeProvider.init();
    getIt.registerSingleton<LocaleProvider>(localeProvider);
  }
}
