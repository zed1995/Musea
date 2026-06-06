// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsTitle => 'Settings';

  @override
  String get preferencesTitle => 'Preferences';

  @override
  String get languageSetting => 'Language';

  @override
  String get downloadOverWifiOnlySetting => 'Download over Wi-Fi only';

  @override
  String get storageTitle => 'Storage';

  @override
  String get cacheSetting => 'Cache';

  @override
  String get clearCacheTitle => 'Clear cache?';

  @override
  String get clearCacheBody =>
      'This removes temporary cache but keeps completed downloads.';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get clearAction => 'Clear';

  @override
  String get downloadsSetting => 'Downloads';

  @override
  String downloadsTaskCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks',
      one: '1 task',
    );
    return '$_temp0';
  }

  @override
  String get aboutTitle => 'About';

  @override
  String get versionSetting => 'Version';

  @override
  String get feedbackSetting => 'Feedback';

  @override
  String get signOutAction => 'Sign out';

  @override
  String get signOutTitle => 'Sign out?';

  @override
  String get signOutBody =>
      'Your current account session will be removed from this device.';

  @override
  String get followSystemLanguage => 'Follow system';

  @override
  String get downloadsPageTitle => 'Downloads';

  @override
  String get downloadingSection => 'Downloading';

  @override
  String get completedSection => 'Completed';

  @override
  String get failedSection => 'Failed';

  @override
  String get retryAction => 'Retry';

  @override
  String get activeStatus => 'Active';

  @override
  String get doneStatus => 'Done';

  @override
  String get failedStatus => 'Failed';

  @override
  String get noDownloadsYet => 'No downloads yet';

  @override
  String get discoverNavLabel => 'Discover';

  @override
  String get collectionsNavLabel => 'Collections';

  @override
  String get mineNavLabel => 'Mine';

  @override
  String get searchPlaceholder => 'Search photos, collections, users...';

  @override
  String get minePageTitle => 'Mine';

  @override
  String get collectionsPageTitle => 'Collections';
}
