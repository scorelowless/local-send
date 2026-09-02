// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'LocalSend - Flutter';

  @override
  String get historyTitle => 'Conversation history';

  @override
  String get discoverTitle => 'Discover devices';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get languageLabel => 'Language';

  @override
  String get filePickerTitle => 'Choose a file to send';

  @override
  String get cancelLabel => 'Cancel';

  @override
  String get eraseLabel => 'Erase';

  @override
  String get eraseAllDataLabel => 'Erase all data';

  @override
  String get eraseConfirmTitle => 'Erase all data';

  @override
  String get eraseConfirmBody =>
      'This will remove history, transfers and device profiles. This action cannot be undone.';

  @override
  String get noConversations => 'No conversations yet';

  @override
  String get noDevicesFound => 'No devices found';

  @override
  String get noMessages => 'No messages';

  @override
  String get historyLabel => 'History';

  @override
  String get discoverLabel => 'Discover';

  @override
  String get settingsLabel => 'Settings';

  @override
  String get sentTransfersTooltip => 'Sent transfers';

  @override
  String get receivedTransfersTooltip => 'Received transfers';

  @override
  String get sentTransfersTitle => 'Sent Transfers';

  @override
  String get receivedTransfersTitle => 'Received Transfers';

  @override
  String get sentLabel => 'Sent';

  @override
  String get receivedLabel => 'Received';

  @override
  String get noSentTransfers => 'No sent transfers';

  @override
  String get noReceivedTransfers => 'No received transfers';

  @override
  String get bytesLabel => 'bytes';

  @override
  String get sendFileButton => 'Send file';

  @override
  String get sendMessageButton => 'Send message';

  @override
  String get fileSent => 'File sent';

  @override
  String get failedToSendFile => 'Failed to send file';

  @override
  String get messageSent => 'Message sent';

  @override
  String get typeMessageHint => 'Type a message';

  @override
  String get failedToOpenFile => 'Failed to open file';

  @override
  String get addDeviceTitle => 'Add device';

  @override
  String get displayNameLabel => 'Display name';

  @override
  String get enterANameError => 'Enter a name';

  @override
  String get deviceTypeLabel => 'Device type';

  @override
  String get laptopLabel => 'Laptop';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get otherLabel => 'Other';

  @override
  String get sentMessageColorLabel => 'Sent message color';

  @override
  String get receivedMessageColorLabel => 'Received message color';

  @override
  String get addButtonLabel => 'Add';

  @override
  String deviceAdded(Object name) {
    return 'Device \"$name\" added';
  }

  @override
  String displayNameSaved(Object name) {
    return 'Display name set to \"$name\"';
  }

  @override
  String get okLabel => 'OK';

  @override
  String get allDataErased => 'All data erased';

  @override
  String get saveButtonLabel => 'Save';

  @override
  String get editDeviceTitle => 'Edit device';

  @override
  String get lanDevicesHeader => 'LAN devices';

  @override
  String get networkConnected => 'Connected to network';

  @override
  String get networkDisconnected => 'Not connected - please join a network';

  @override
  String get wifiDirectHeader => 'Wi‑Fi Direct';

  @override
  String get wifiDirectStart => 'Start Wi‑Fi Direct discovery';

  @override
  String get wifiDirectStop => 'Stop Wi‑Fi Direct discovery';

  @override
  String get noWifiDirectDevices => 'No Wi‑Fi Direct devices found';

  @override
  String get bluetoothDisabledTitle => 'Bluetooth disabled';

  @override
  String get bluetoothDisabledBody =>
      'Bluetooth is turned off. Please enable Bluetooth to use Wi‑Fi Direct discovery.';

  @override
  String get bluetoothEnable => 'Open Bluetooth settings';

  @override
  String get bluetoothCancel => 'Cancel';
}
