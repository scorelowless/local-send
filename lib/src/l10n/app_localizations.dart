import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('de'), Locale('en'), Locale('pl')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'LocalSend - Flutter'**
  String get appTitle;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Conversation history'**
  String get historyTitle;

  /// No description provided for @discoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover devices'**
  String get discoverTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @filePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a file to send'**
  String get filePickerTitle;

  /// No description provided for @cancelLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelLabel;

  /// No description provided for @eraseLabel.
  ///
  /// In en, this message translates to:
  /// **'Erase'**
  String get eraseLabel;

  /// No description provided for @eraseAllDataLabel.
  ///
  /// In en, this message translates to:
  /// **'Erase all data'**
  String get eraseAllDataLabel;

  /// No description provided for @eraseConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Erase all data'**
  String get eraseConfirmTitle;

  /// No description provided for @eraseConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This will remove history, transfers and device profiles. This action cannot be undone.'**
  String get eraseConfirmBody;

  /// No description provided for @noConversations.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noConversations;

  /// No description provided for @noDevicesFound.
  ///
  /// In en, this message translates to:
  /// **'No devices found'**
  String get noDevicesFound;

  /// No description provided for @noMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages'**
  String get noMessages;

  /// No description provided for @historyLabel.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyLabel;

  /// No description provided for @discoverLabel.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discoverLabel;

  /// No description provided for @settingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsLabel;

  /// No description provided for @sentTransfersTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sent transfers'**
  String get sentTransfersTooltip;

  /// No description provided for @receivedTransfersTooltip.
  ///
  /// In en, this message translates to:
  /// **'Received transfers'**
  String get receivedTransfersTooltip;

  /// No description provided for @sentTransfersTitle.
  ///
  /// In en, this message translates to:
  /// **'Sent Transfers'**
  String get sentTransfersTitle;

  /// No description provided for @receivedTransfersTitle.
  ///
  /// In en, this message translates to:
  /// **'Received Transfers'**
  String get receivedTransfersTitle;

  /// No description provided for @sentLabel.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sentLabel;

  /// No description provided for @receivedLabel.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get receivedLabel;

  /// No description provided for @noSentTransfers.
  ///
  /// In en, this message translates to:
  /// **'No sent transfers'**
  String get noSentTransfers;

  /// No description provided for @noReceivedTransfers.
  ///
  /// In en, this message translates to:
  /// **'No received transfers'**
  String get noReceivedTransfers;

  /// No description provided for @bytesLabel.
  ///
  /// In en, this message translates to:
  /// **'bytes'**
  String get bytesLabel;

  /// No description provided for @sendFileButton.
  ///
  /// In en, this message translates to:
  /// **'Send file'**
  String get sendFileButton;

  /// No description provided for @sendMessageButton.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get sendMessageButton;

  /// No description provided for @fileSent.
  ///
  /// In en, this message translates to:
  /// **'File sent'**
  String get fileSent;

  /// No description provided for @failedToSendFile.
  ///
  /// In en, this message translates to:
  /// **'Failed to send file'**
  String get failedToSendFile;

  /// No description provided for @messageSent.
  ///
  /// In en, this message translates to:
  /// **'Message sent'**
  String get messageSent;

  /// No description provided for @typeMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message'**
  String get typeMessageHint;

  /// No description provided for @failedToOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Failed to open file'**
  String get failedToOpenFile;

  /// No description provided for @addDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Add device'**
  String get addDeviceTitle;

  /// No description provided for @displayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayNameLabel;

  /// No description provided for @enterANameError.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get enterANameError;

  /// No description provided for @deviceTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Device type'**
  String get deviceTypeLabel;

  /// No description provided for @laptopLabel.
  ///
  /// In en, this message translates to:
  /// **'Laptop'**
  String get laptopLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @otherLabel.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherLabel;

  /// No description provided for @sentMessageColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Sent message color'**
  String get sentMessageColorLabel;

  /// No description provided for @receivedMessageColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Received message color'**
  String get receivedMessageColorLabel;

  /// No description provided for @addButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addButtonLabel;

  /// No description provided for @deviceAdded.
  ///
  /// In en, this message translates to:
  /// **'Device \"{name}\" added'**
  String deviceAdded(Object name);

  /// No description provided for @displayNameSaved.
  ///
  /// In en, this message translates to:
  /// **'Display name set to \"{name}\"'**
  String displayNameSaved(Object name);

  /// No description provided for @okLabel.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okLabel;

  /// No description provided for @allDataErased.
  ///
  /// In en, this message translates to:
  /// **'All data erased'**
  String get allDataErased;

  /// No description provided for @saveButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButtonLabel;

  /// No description provided for @editDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit device'**
  String get editDeviceTitle;

  /// No description provided for @lanDevicesHeader.
  ///
  /// In en, this message translates to:
  /// **'LAN devices'**
  String get lanDevicesHeader;

  /// No description provided for @networkConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected to network'**
  String get networkConnected;

  /// No description provided for @networkDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected - please join a network'**
  String get networkDisconnected;

  /// No description provided for @wifiDirectHeader.
  ///
  /// In en, this message translates to:
  /// **'Wi‑Fi Direct'**
  String get wifiDirectHeader;

  /// No description provided for @wifiDirectStart.
  ///
  /// In en, this message translates to:
  /// **'Start Wi‑Fi Direct discovery'**
  String get wifiDirectStart;

  /// No description provided for @wifiDirectStop.
  ///
  /// In en, this message translates to:
  /// **'Stop Wi‑Fi Direct discovery'**
  String get wifiDirectStop;

  /// No description provided for @noWifiDirectDevices.
  ///
  /// In en, this message translates to:
  /// **'No Wi‑Fi Direct devices found'**
  String get noWifiDirectDevices;

  /// No description provided for @bluetoothDisabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth disabled'**
  String get bluetoothDisabledTitle;

  /// No description provided for @bluetoothDisabledBody.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is turned off. Please enable Bluetooth to use Wi‑Fi Direct discovery.'**
  String get bluetoothDisabledBody;

  /// No description provided for @bluetoothEnable.
  ///
  /// In en, this message translates to:
  /// **'Open Bluetooth settings'**
  String get bluetoothEnable;

  /// No description provided for @bluetoothCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get bluetoothCancel;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'pl':
      return AppLocalizationsPl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
