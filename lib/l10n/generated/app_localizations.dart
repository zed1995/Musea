import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @preferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferencesTitle;

  /// No description provided for @languageSetting.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSetting;

  /// No description provided for @downloadOverWifiOnlySetting.
  ///
  /// In en, this message translates to:
  /// **'Download over Wi-Fi only'**
  String get downloadOverWifiOnlySetting;

  /// No description provided for @storageTitle.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storageTitle;

  /// No description provided for @cacheSetting.
  ///
  /// In en, this message translates to:
  /// **'Cache'**
  String get cacheSetting;

  /// No description provided for @clearCacheTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear cache?'**
  String get clearCacheTitle;

  /// No description provided for @clearCacheBody.
  ///
  /// In en, this message translates to:
  /// **'This removes temporary cache but keeps completed downloads.'**
  String get clearCacheBody;

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// No description provided for @clearAction.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearAction;

  /// No description provided for @downloadsSetting.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloadsSetting;

  /// No description provided for @downloadsTaskCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {1 task} other {{count} tasks}}'**
  String downloadsTaskCount(int count);

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @versionSetting.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get versionSetting;

  /// No description provided for @feedbackSetting.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedbackSetting;

  /// No description provided for @signOutAction.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOutAction;

  /// No description provided for @signOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutTitle;

  /// No description provided for @signOutBody.
  ///
  /// In en, this message translates to:
  /// **'Your current account session will be removed from this device.'**
  String get signOutBody;

  /// No description provided for @followSystemLanguage.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get followSystemLanguage;

  /// No description provided for @downloadsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloadsPageTitle;

  /// No description provided for @downloadingSection.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get downloadingSection;

  /// No description provided for @completedSection.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedSection;

  /// No description provided for @failedSection.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failedSection;

  /// No description provided for @retryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryAction;

  /// No description provided for @activeStatus.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeStatus;

  /// No description provided for @doneStatus.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneStatus;

  /// No description provided for @failedStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failedStatus;

  /// No description provided for @noDownloadsYet.
  ///
  /// In en, this message translates to:
  /// **'No downloads yet'**
  String get noDownloadsYet;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @simplifiedChinese.
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get simplifiedChinese;

  /// No description provided for @github.
  ///
  /// In en, this message translates to:
  /// **'GitHub'**
  String get github;

  /// No description provided for @discoverNavLabel.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discoverNavLabel;

  /// No description provided for @collectionsNavLabel.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get collectionsNavLabel;

  /// No description provided for @mineNavLabel.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get mineNavLabel;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search photos, collections, users...'**
  String get searchPlaceholder;

  /// No description provided for @segmentPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get segmentPhotos;

  /// No description provided for @segmentCollections.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get segmentCollections;

  /// No description provided for @segmentLikes.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get segmentLikes;

  /// No description provided for @segmentUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get segmentUsers;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @colorLabel.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get colorLabel;

  /// No description provided for @orientationLabel.
  ///
  /// In en, this message translates to:
  /// **'Orientation'**
  String get orientationLabel;

  /// No description provided for @contentSafety.
  ///
  /// In en, this message translates to:
  /// **'Content safety'**
  String get contentSafety;

  /// No description provided for @filterRelevant.
  ///
  /// In en, this message translates to:
  /// **'Relevant'**
  String get filterRelevant;

  /// No description provided for @filterLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get filterLatest;

  /// No description provided for @filterAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get filterAny;

  /// No description provided for @filterGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get filterGreen;

  /// No description provided for @filterBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get filterBlue;

  /// No description provided for @filterBlackAndWhite.
  ///
  /// In en, this message translates to:
  /// **'Black & White'**
  String get filterBlackAndWhite;

  /// No description provided for @filterLandscape.
  ///
  /// In en, this message translates to:
  /// **'Landscape'**
  String get filterLandscape;

  /// No description provided for @filterPortrait.
  ///
  /// In en, this message translates to:
  /// **'Portrait'**
  String get filterPortrait;

  /// No description provided for @filterSquarish.
  ///
  /// In en, this message translates to:
  /// **'Squarish'**
  String get filterSquarish;

  /// No description provided for @filterLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get filterLow;

  /// No description provided for @filterHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get filterHigh;

  /// No description provided for @noMatchingPhotos.
  ///
  /// In en, this message translates to:
  /// **'No matching photos'**
  String get noMatchingPhotos;

  /// No description provided for @noMatchingPhotosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try a different keyword or broaden the query.'**
  String get noMatchingPhotosSubtitle;

  /// No description provided for @noMatchingCollections.
  ///
  /// In en, this message translates to:
  /// **'No matching collections'**
  String get noMatchingCollections;

  /// No description provided for @noMatchingCollectionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try another phrase to find curated sets.'**
  String get noMatchingCollectionsSubtitle;

  /// No description provided for @noMatchingUsers.
  ///
  /// In en, this message translates to:
  /// **'No matching users'**
  String get noMatchingUsers;

  /// No description provided for @noMatchingUsersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try a creator name, username, or location.'**
  String get noMatchingUsersSubtitle;

  /// No description provided for @startTypingToSearch.
  ///
  /// In en, this message translates to:
  /// **'Start typing to search'**
  String get startTypingToSearch;

  /// No description provided for @searchIdleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We will query photos, collections, and creators using the live search endpoints.'**
  String get searchIdleSubtitle;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @likeError.
  ///
  /// In en, this message translates to:
  /// **'Could not update like right now'**
  String get likeError;

  /// No description provided for @signInToSavePhotos.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save photos'**
  String get signInToSavePhotos;

  /// No description provided for @signInToSavePhotosBody.
  ///
  /// In en, this message translates to:
  /// **'Build collections of what inspires you and keep them in sync with your Unsplash account.'**
  String get signInToSavePhotosBody;

  /// No description provided for @featured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featured;

  /// No description provided for @byName.
  ///
  /// In en, this message translates to:
  /// **'by {name}'**
  String byName(String name);

  /// No description provided for @noPhotos.
  ///
  /// In en, this message translates to:
  /// **'No photos'**
  String get noPhotos;

  /// No description provided for @collectionsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get collectionsPageTitle;

  /// No description provided for @minePageTitle.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get minePageTitle;

  /// No description provided for @likedPhotos.
  ///
  /// In en, this message translates to:
  /// **'Liked photos'**
  String get likedPhotos;

  /// No description provided for @savedCollections.
  ///
  /// In en, this message translates to:
  /// **'Saved collections'**
  String get savedCollections;

  /// No description provided for @personalSpace.
  ///
  /// In en, this message translates to:
  /// **'Personal space'**
  String get personalSpace;

  /// No description provided for @likedPhotosDesc.
  ///
  /// In en, this message translates to:
  /// **'Revisit favorites you loved without hunting through the feed again.'**
  String get likedPhotosDesc;

  /// No description provided for @savedCollectionsDesc.
  ///
  /// In en, this message translates to:
  /// **'Build a shelf of references, moods, and places you want to return to.'**
  String get savedCollectionsDesc;

  /// No description provided for @personalSpaceDesc.
  ///
  /// In en, this message translates to:
  /// **'A home for your archive now, with room for preferences and history later.'**
  String get personalSpaceDesc;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @yourArchiveSynced.
  ///
  /// In en, this message translates to:
  /// **'Your visual archive, synced with Unsplash'**
  String get yourArchiveSynced;

  /// No description provided for @keepLikesSaves.
  ///
  /// In en, this message translates to:
  /// **'Keep likes, saves, and your personal archive connected in one calm workspace.'**
  String get keepLikesSaves;

  /// No description provided for @weUseUnsplashAccount.
  ///
  /// In en, this message translates to:
  /// **'We use your Unsplash account to sync likes, saves, and your personal archive.'**
  String get weUseUnsplashAccount;

  /// No description provided for @continueWithUnsplash.
  ///
  /// In en, this message translates to:
  /// **'Continue with Unsplash'**
  String get continueWithUnsplash;

  /// No description provided for @guestMode.
  ///
  /// In en, this message translates to:
  /// **'Guest mode'**
  String get guestMode;

  /// No description provided for @guestModeDesc.
  ///
  /// In en, this message translates to:
  /// **'You can keep exploring without signing in'**
  String get guestModeDesc;

  /// No description provided for @guestModeBody.
  ///
  /// In en, this message translates to:
  /// **'Discover, search, browse collections, and open public photographer profiles anytime. Sign in only when you want your activity to stay with you.'**
  String get guestModeBody;

  /// No description provided for @guestChipDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get guestChipDiscover;

  /// No description provided for @guestChipSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get guestChipSearch;

  /// No description provided for @guestChipCollections.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get guestChipCollections;

  /// No description provided for @guestChipProfiles.
  ///
  /// In en, this message translates to:
  /// **'Profiles'**
  String get guestChipProfiles;

  /// No description provided for @browseAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Browse as guest'**
  String get browseAsGuest;

  /// No description provided for @browseProfiles.
  ///
  /// In en, this message translates to:
  /// **'Browse profiles'**
  String get browseProfiles;

  /// No description provided for @workspace.
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get workspace;

  /// No description provided for @personalWorkspaceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Personal workspace for photos, collections, and saved inspiration.'**
  String get personalWorkspaceSubtitle;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @downloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// No description provided for @syncingLatestProfile.
  ///
  /// In en, this message translates to:
  /// **'Syncing latest profile...'**
  String get syncingLatestProfile;

  /// No description provided for @showingCachedProfile.
  ///
  /// In en, this message translates to:
  /// **'Showing your cached profile first.'**
  String get showingCachedProfile;

  /// No description provided for @noLikedPhotosYet.
  ///
  /// In en, this message translates to:
  /// **'No liked photos yet.'**
  String get noLikedPhotosYet;

  /// No description provided for @nothingHereYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet.'**
  String get nothingHereYet;

  /// No description provided for @noCollectionsYet.
  ///
  /// In en, this message translates to:
  /// **'No collections yet.'**
  String get noCollectionsYet;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @collections.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get collections;

  /// No description provided for @likes.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get likes;

  /// No description provided for @noPublicPhotosYet.
  ///
  /// In en, this message translates to:
  /// **'No public photos yet'**
  String get noPublicPhotosYet;

  /// No description provided for @noPublicCollectionsYet.
  ///
  /// In en, this message translates to:
  /// **'No public collections yet'**
  String get noPublicCollectionsYet;

  /// No description provided for @likesReceived.
  ///
  /// In en, this message translates to:
  /// **'{count} likes received'**
  String likesReceived(int count);

  /// No description provided for @follow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get follow;

  /// No description provided for @following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get following;

  /// No description provided for @cameraInfo.
  ///
  /// In en, this message translates to:
  /// **'CAMERA INFO'**
  String get cameraInfo;

  /// No description provided for @exifCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get exifCamera;

  /// No description provided for @exifAperture.
  ///
  /// In en, this message translates to:
  /// **'Aperture'**
  String get exifAperture;

  /// No description provided for @exifShutter.
  ///
  /// In en, this message translates to:
  /// **'Shutter'**
  String get exifShutter;

  /// No description provided for @exifIso.
  ///
  /// In en, this message translates to:
  /// **'ISO'**
  String get exifIso;

  /// No description provided for @exifFocal.
  ///
  /// In en, this message translates to:
  /// **'Focal'**
  String get exifFocal;

  /// No description provided for @exifLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get exifLocation;

  /// No description provided for @exifSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get exifSize;

  /// No description provided for @downloadFree.
  ///
  /// In en, this message translates to:
  /// **'Download Free'**
  String get downloadFree;

  /// No description provided for @moreFromPhotographer.
  ///
  /// In en, this message translates to:
  /// **'More from photographer'**
  String get moreFromPhotographer;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'TAGS'**
  String get tags;

  /// No description provided for @tagsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Tags unavailable until details finish loading.'**
  String get tagsUnavailable;

  /// No description provided for @cameraDetailsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera details unavailable until hydration succeeds.'**
  String get cameraDetailsUnavailable;

  /// No description provided for @detailSectionsFailed.
  ///
  /// In en, this message translates to:
  /// **'Some detail sections could not be loaded yet.'**
  String get detailSectionsFailed;

  /// No description provided for @retryLoadingDetails.
  ///
  /// In en, this message translates to:
  /// **'Retry loading details'**
  String get retryLoadingDetails;

  /// No description provided for @authTitleDefault.
  ///
  /// In en, this message translates to:
  /// **'Sign in to like photos'**
  String get authTitleDefault;

  /// No description provided for @authBodyDefault.
  ///
  /// In en, this message translates to:
  /// **'Save what moves you, keep your visual trail together, and sync every like with your Unsplash account.'**
  String get authBodyDefault;

  /// No description provided for @authLikedPhotos.
  ///
  /// In en, this message translates to:
  /// **'Liked photos'**
  String get authLikedPhotos;

  /// No description provided for @authLikedPhotosDesc.
  ///
  /// In en, this message translates to:
  /// **'Revisit favorites across devices without losing your place.'**
  String get authLikedPhotosDesc;

  /// No description provided for @authSaveForLater.
  ///
  /// In en, this message translates to:
  /// **'Save for later'**
  String get authSaveForLater;

  /// No description provided for @authSaveForLaterDesc.
  ///
  /// In en, this message translates to:
  /// **'Build a private inspiration shelf that stays with you.'**
  String get authSaveForLaterDesc;

  /// No description provided for @authTrustTitle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Unsplash'**
  String get authTrustTitle;

  /// No description provided for @authTrustBody.
  ///
  /// In en, this message translates to:
  /// **'We use your Unsplash account to connect likes, saves, and your personal archive.'**
  String get authTrustBody;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @sizeSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get sizeSmall;

  /// No description provided for @sizeRegular.
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get sizeRegular;

  /// No description provided for @sizeFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get sizeFull;

  /// No description provided for @sizeOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get sizeOriginal;

  /// No description provided for @downloadSmall.
  ///
  /// In en, this message translates to:
  /// **'Download Small'**
  String get downloadSmall;

  /// No description provided for @downloadRegular.
  ///
  /// In en, this message translates to:
  /// **'Download Regular'**
  String get downloadRegular;

  /// No description provided for @downloadFull.
  ///
  /// In en, this message translates to:
  /// **'Download Full'**
  String get downloadFull;

  /// No description provided for @downloadOriginal.
  ///
  /// In en, this message translates to:
  /// **'Download Original'**
  String get downloadOriginal;

  /// No description provided for @downloadDescSmall.
  ///
  /// In en, this message translates to:
  /// **'Fast to save and easy to share.'**
  String get downloadDescSmall;

  /// No description provided for @downloadDescRegular.
  ///
  /// In en, this message translates to:
  /// **'A balanced choice for most screens and posts.'**
  String get downloadDescRegular;

  /// No description provided for @downloadDescFull.
  ///
  /// In en, this message translates to:
  /// **'Sharper and more detailed for larger displays.'**
  String get downloadDescFull;

  /// No description provided for @downloadDescOriginal.
  ///
  /// In en, this message translates to:
  /// **'The largest available version with the most flexibility.'**
  String get downloadDescOriginal;

  /// No description provided for @chooseSizeHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the size that works best for where you want to use this photo.'**
  String get chooseSizeHint;

  /// No description provided for @downloadProgress.
  ///
  /// In en, this message translates to:
  /// **'Download Progress'**
  String get downloadProgress;

  /// No description provided for @downloadProgressCompleted.
  ///
  /// In en, this message translates to:
  /// **'Your photo has been saved and is ready in the gallery.'**
  String get downloadProgressCompleted;

  /// No description provided for @downloadProgressFailed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while saving this image.'**
  String get downloadProgressFailed;

  /// No description provided for @downloadProgressSaving.
  ///
  /// In en, this message translates to:
  /// **'Almost there. We are moving the file into your gallery now.'**
  String get downloadProgressSaving;

  /// No description provided for @downloadProgressDownloading.
  ///
  /// In en, this message translates to:
  /// **'You can keep browsing while the download continues in the background.'**
  String get downloadProgressDownloading;

  /// No description provided for @doneAction.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneAction;

  /// No description provided for @backToSizes.
  ///
  /// In en, this message translates to:
  /// **'Back to Sizes'**
  String get backToSizes;

  /// No description provided for @downloadInBackground.
  ///
  /// In en, this message translates to:
  /// **'Download in Background'**
  String get downloadInBackground;

  /// No description provided for @imageSavedToGallery.
  ///
  /// In en, this message translates to:
  /// **'Image saved to gallery'**
  String get imageSavedToGallery;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get downloadFailed;

  /// No description provided for @collectionSummary.
  ///
  /// In en, this message translates to:
  /// **'Collection Summary'**
  String get collectionSummary;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @firstFourPhotos.
  ///
  /// In en, this message translates to:
  /// **'First four photos'**
  String get firstFourPhotos;

  /// No description provided for @openGrid.
  ///
  /// In en, this message translates to:
  /// **'Open grid'**
  String get openGrid;

  /// No description provided for @collectionFacts.
  ///
  /// In en, this message translates to:
  /// **'Collection Facts'**
  String get collectionFacts;

  /// No description provided for @continueExploring.
  ///
  /// In en, this message translates to:
  /// **'Continue Exploring'**
  String get continueExploring;

  /// No description provided for @exploreNearbyThemes.
  ///
  /// In en, this message translates to:
  /// **'Explore nearby themes first'**
  String get exploreNearbyThemes;

  /// No description provided for @photoCollection.
  ///
  /// In en, this message translates to:
  /// **'Photo collection'**
  String get photoCollection;

  /// No description provided for @private.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get private;

  /// No description provided for @public.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get public;

  /// No description provided for @unknownCurator.
  ///
  /// In en, this message translates to:
  /// **'Unknown curator'**
  String get unknownCurator;

  /// No description provided for @published.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get published;

  /// No description provided for @updated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updated;

  /// No description provided for @lastCollected.
  ///
  /// In en, this message translates to:
  /// **'Last collected'**
  String get lastCollected;

  /// No description provided for @visibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get visibility;

  /// No description provided for @privateCollection.
  ///
  /// In en, this message translates to:
  /// **'Private collection'**
  String get privateCollection;

  /// No description provided for @publicCollection.
  ///
  /// In en, this message translates to:
  /// **'Public collection'**
  String get publicCollection;

  /// No description provided for @insideTheCollection.
  ///
  /// In en, this message translates to:
  /// **'Inside the collection'**
  String get insideTheCollection;

  /// No description provided for @noPhotosInCollection.
  ///
  /// In en, this message translates to:
  /// **'No photos in this collection yet'**
  String get noPhotosInCollection;

  /// No description provided for @previewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Preview unavailable until details finish loading.'**
  String get previewUnavailable;

  /// No description provided for @previewWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Preview will appear when photos are added'**
  String get previewWillAppear;

  /// No description provided for @collectionDetailsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Some collection details are still unavailable.'**
  String get collectionDetailsUnavailable;

  /// No description provided for @factsWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Additional collection facts will appear after details finish loading.'**
  String get factsWillAppear;

  /// No description provided for @jumpToFeed.
  ///
  /// In en, this message translates to:
  /// **'Jump to feed'**
  String get jumpToFeed;

  /// No description provided for @noDescriptionFallback.
  ///
  /// In en, this message translates to:
  /// **'No curator description has been added for this collection yet. The layout stays intact and shifts emphasis to the curator and photo stream.'**
  String get noDescriptionFallback;

  /// No description provided for @curatedSets.
  ///
  /// In en, this message translates to:
  /// **'Curated sets'**
  String get curatedSets;

  /// No description provided for @photoCount.
  ///
  /// In en, this message translates to:
  /// **'{count} photos'**
  String photoCount(int count);

  /// No description provided for @collectionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} collections'**
  String collectionsCount(int count);

  /// No description provided for @publishedDate.
  ///
  /// In en, this message translates to:
  /// **'Published {date}'**
  String publishedDate(String date);

  /// No description provided for @updatedDate.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String updatedDate(String date);

  /// No description provided for @lastCollectedDate.
  ///
  /// In en, this message translates to:
  /// **'Last collected {date}'**
  String lastCollectedDate(String date);

  /// No description provided for @newCollection.
  ///
  /// In en, this message translates to:
  /// **'New collection'**
  String get newCollection;

  /// No description provided for @newCollectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Name it, add an optional note, and choose visibility.'**
  String get newCollectionDesc;

  /// No description provided for @collectionName.
  ///
  /// In en, this message translates to:
  /// **'Collection Name'**
  String get collectionName;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get enterName;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description Optional'**
  String get descriptionOptional;

  /// No description provided for @addDescription.
  ///
  /// In en, this message translates to:
  /// **'Add a description...'**
  String get addDescription;

  /// No description provided for @onlyYouCanSee.
  ///
  /// In en, this message translates to:
  /// **'Only you can see it.'**
  String get onlyYouCanSee;

  /// No description provided for @visibleOnProfile.
  ///
  /// In en, this message translates to:
  /// **'Visible on your profile.'**
  String get visibleOnProfile;

  /// No description provided for @visibleOnYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Visible on your profile'**
  String get visibleOnYourProfile;

  /// No description provided for @onlyForYourArchive.
  ///
  /// In en, this message translates to:
  /// **'Only for your own archive'**
  String get onlyForYourArchive;

  /// No description provided for @createCollection.
  ///
  /// In en, this message translates to:
  /// **'Create collection'**
  String get createCollection;

  /// No description provided for @selectCollection.
  ///
  /// In en, this message translates to:
  /// **'Select collection'**
  String get selectCollection;

  /// No description provided for @savePhotoToCollection.
  ///
  /// In en, this message translates to:
  /// **'Save this photo to one of your collections.'**
  String get savePhotoToCollection;

  /// No description provided for @createNewCollection.
  ///
  /// In en, this message translates to:
  /// **'Create new collection'**
  String get createNewCollection;

  /// No description provided for @noPerfectFitYet.
  ///
  /// In en, this message translates to:
  /// **'No perfect fit yet? Make a new one.'**
  String get noPerfectFitYet;

  /// No description provided for @myCollections.
  ///
  /// In en, this message translates to:
  /// **'MY COLLECTIONS'**
  String get myCollections;

  /// No description provided for @backToCollections.
  ///
  /// In en, this message translates to:
  /// **'Back to collections'**
  String get backToCollections;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @savedTo.
  ///
  /// In en, this message translates to:
  /// **'Saved to {title}'**
  String savedTo(String title);

  /// No description provided for @deleteCollection.
  ///
  /// In en, this message translates to:
  /// **'Delete collection?'**
  String get deleteCollection;

  /// No description provided for @deleteCollectionDesc.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes the collection and its saved links.'**
  String get deleteCollectionDesc;

  /// No description provided for @willBeDeleted.
  ///
  /// In en, this message translates to:
  /// **'{title} will be deleted'**
  String willBeDeleted(String title);

  /// No description provided for @photosRemainUnsplash.
  ///
  /// In en, this message translates to:
  /// **'The photos remain on Unsplash, but this collection cannot be restored once removed.'**
  String get photosRemainUnsplash;

  /// No description provided for @typeToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type to confirm'**
  String get typeToConfirm;

  /// No description provided for @deleteCollectionAction.
  ///
  /// In en, this message translates to:
  /// **'Delete collection'**
  String get deleteCollectionAction;

  /// No description provided for @editCollection.
  ///
  /// In en, this message translates to:
  /// **'Edit collection'**
  String get editCollection;

  /// No description provided for @editCollectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Only the fields supported by the API are editable.'**
  String get editCollectionDesc;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @manageCollection.
  ///
  /// In en, this message translates to:
  /// **'Manage collection'**
  String get manageCollection;

  /// No description provided for @manageCollectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Update the collection, clean up saved photos, or delete it safely.'**
  String get manageCollectionDesc;

  /// No description provided for @editDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get editDetails;

  /// No description provided for @editDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Title, description, and visibility'**
  String get editDetailsSubtitle;

  /// No description provided for @removePhotos.
  ///
  /// In en, this message translates to:
  /// **'Remove photos'**
  String get removePhotos;

  /// No description provided for @removePhotosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select multiple photos to remove them from this collection. Photos stay available on Unsplash.'**
  String get removePhotosSubtitle;

  /// No description provided for @deleteCollectionAction2.
  ///
  /// In en, this message translates to:
  /// **'Delete collection'**
  String get deleteCollectionAction2;

  /// No description provided for @deleteCollectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanent action with confirmation'**
  String get deleteCollectionSubtitle;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Oops! Something went wrong'**
  String get genericError;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error: {message}'**
  String networkError(String message);

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Server error: {message}'**
  String serverError(String message);

  /// No description provided for @signInAgain.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again.'**
  String get signInAgain;

  /// No description provided for @tooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please try again later.'**
  String get tooManyRequests;

  /// No description provided for @photoAlreadyInCollection.
  ///
  /// In en, this message translates to:
  /// **'Photo already in this collection.'**
  String get photoAlreadyInCollection;

  /// No description provided for @couldNotIdentifyUser.
  ///
  /// In en, this message translates to:
  /// **'Could not identify user. Please sign in again.'**
  String get couldNotIdentifyUser;

  /// No description provided for @signInAgainToCreate.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to create collections.'**
  String get signInAgainToCreate;

  /// No description provided for @batchMode.
  ///
  /// In en, this message translates to:
  /// **'Batch Mode'**
  String get batchMode;

  /// No description provided for @selection.
  ///
  /// In en, this message translates to:
  /// **'Selection'**
  String get selection;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// No description provided for @willRemovePhotosDesc.
  ///
  /// In en, this message translates to:
  /// **'{count} photos will be removed from {title}. This does not delete the original photos.'**
  String willRemovePhotosDesc(int count, String title);

  /// No description provided for @removeCountPhotos.
  ///
  /// In en, this message translates to:
  /// **'Remove {count} photos'**
  String removeCountPhotos(int count);

  /// No description provided for @noCollectionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check back later for curated collections'**
  String get noCollectionsSubtitle;

  /// No description provided for @signInToCreateCollections.
  ///
  /// In en, this message translates to:
  /// **'Sign in to create collections'**
  String get signInToCreateCollections;

  /// No description provided for @signInToCreateCollectionsBody.
  ///
  /// In en, this message translates to:
  /// **'Save your favorite photos into custom collections and organize them your way.'**
  String get signInToCreateCollectionsBody;

  /// No description provided for @colorPalette.
  ///
  /// In en, this message translates to:
  /// **'COLOR PALETTE'**
  String get colorPalette;

  /// No description provided for @copiedHex.
  ///
  /// In en, this message translates to:
  /// **'Copied {hex}'**
  String copiedHex(String hex);

  /// No description provided for @unableToLoadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Unable to load photo'**
  String get unableToLoadPhoto;

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'@unknown'**
  String get unknownUser;

  /// No description provided for @exploreThemeRoadTrips.
  ///
  /// In en, this message translates to:
  /// **'Road trips'**
  String get exploreThemeRoadTrips;

  /// No description provided for @exploreThemeNationalParks.
  ///
  /// In en, this message translates to:
  /// **'National parks'**
  String get exploreThemeNationalParks;

  /// No description provided for @exploreThemeLandscape.
  ///
  /// In en, this message translates to:
  /// **'Landscape'**
  String get exploreThemeLandscape;

  /// No description provided for @exploreThemeOpenSky.
  ///
  /// In en, this message translates to:
  /// **'Open sky'**
  String get exploreThemeOpenSky;

  /// No description provided for @exploreThemeTravelNotes.
  ///
  /// In en, this message translates to:
  /// **'Travel notes'**
  String get exploreThemeTravelNotes;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
