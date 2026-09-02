// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'LocalSend - Flutter';

  @override
  String get historyTitle => 'Historia konwersacji';

  @override
  String get discoverTitle => 'Wykryj urządzenia';

  @override
  String get settingsTitle => 'Ustawienia';

  @override
  String get languageLabel => 'Język';

  @override
  String get filePickerTitle => 'Wybierz plik do wysłania';

  @override
  String get cancelLabel => 'Anuluj';

  @override
  String get eraseLabel => 'Usuń';

  @override
  String get eraseAllDataLabel => 'Usuń wszystkie dane';

  @override
  String get eraseConfirmTitle => 'Usuń wszystkie dane';

  @override
  String get eraseConfirmBody =>
      'Spowoduje to usunięcie historii, transferów i profili urządzeń. Tej akcji nie można cofnąć.';

  @override
  String get noConversations => 'Brak konwersacji';

  @override
  String get noDevicesFound => 'Nie znaleziono urządzeń';

  @override
  String get noMessages => 'Brak wiadomości';

  @override
  String get historyLabel => 'Historia';

  @override
  String get discoverLabel => 'Wykryj';

  @override
  String get settingsLabel => 'Ustawienia';

  @override
  String get sentTransfersTooltip => 'Wysłane transfery';

  @override
  String get receivedTransfersTooltip => 'Otrzymane transfery';

  @override
  String get sentTransfersTitle => 'Wysłane transfery';

  @override
  String get receivedTransfersTitle => 'Otrzymane transfery';

  @override
  String get sentLabel => 'Wysłane';

  @override
  String get receivedLabel => 'Otrzymane';

  @override
  String get noSentTransfers => 'Brak wysłanych transferów';

  @override
  String get noReceivedTransfers => 'Brak otrzymanych transferów';

  @override
  String get bytesLabel => 'bajty';

  @override
  String get sendFileButton => 'Wyślij plik';

  @override
  String get sendMessageButton => 'Wyślij wiadomość';

  @override
  String get fileSent => 'Plik wysłany';

  @override
  String get failedToSendFile => 'Nie udało się wysłać pliku';

  @override
  String get messageSent => 'Wiadomość wysłana';

  @override
  String get typeMessageHint => 'Wpisz wiadomość';

  @override
  String get failedToOpenFile => 'Nie udało się otworzyć pliku';

  @override
  String get addDeviceTitle => 'Dodaj urządzenie';

  @override
  String get displayNameLabel => 'Nazwa wyświetlana';

  @override
  String get enterANameError => 'Podaj nazwę';

  @override
  String get deviceTypeLabel => 'Typ urządzenia';

  @override
  String get laptopLabel => 'Laptop';

  @override
  String get phoneLabel => 'Telefon';

  @override
  String get otherLabel => 'Inne';

  @override
  String get sentMessageColorLabel => 'Kolor wiadomości wysłanych';

  @override
  String get receivedMessageColorLabel => 'Kolor wiadomości odebranych';

  @override
  String get addButtonLabel => 'Dodaj';

  @override
  String deviceAdded(Object name) {
    return 'Urządzenie \"$name\" dodane';
  }

  @override
  String displayNameSaved(Object name) {
    return 'Nazwa wyświetlana ustawiona na \"$name\"';
  }

  @override
  String get okLabel => 'OK';

  @override
  String get allDataErased => 'Wszystkie dane zostały usunięte';

  @override
  String get saveButtonLabel => 'Zapisz';

  @override
  String get editDeviceTitle => 'Edytuj urządzenie';

  @override
  String get lanDevicesHeader => 'Urządzenia sieci LAN';

  @override
  String get networkConnected => 'Połączono z siecią';

  @override
  String get networkDisconnected => 'Brak połączenia — dołącz do sieci';

  @override
  String get wifiDirectHeader => 'Wi‑Fi Direct';

  @override
  String get wifiDirectStart => 'Rozpocznij wykrywanie Wi‑Fi Direct';

  @override
  String get wifiDirectStop => 'Zatrzymaj wykrywanie Wi‑Fi Direct';

  @override
  String get noWifiDirectDevices => 'Nie znaleziono urządzeń Wi‑Fi Direct';

  @override
  String get bluetoothDisabledTitle => 'Bluetooth wyłączony';

  @override
  String get bluetoothDisabledBody =>
      'Bluetooth jest wyłączony. Włącz Bluetooth, aby używać wykrywania Wi‑Fi Direct.';

  @override
  String get bluetoothEnable => 'Otwórz ustawienia Bluetooth';

  @override
  String get bluetoothCancel => 'Anuluj';
}
