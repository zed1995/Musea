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
  String get deleteAction => 'Delete';

  @override
  String get clearCompletedAction => 'Clear Completed';

  @override
  String get clearFailedAction => 'Clear Failed';

  @override
  String get downloadRecordsOnlyHint =>
      'Deleting a task removes only the record here. Saved images stay in your gallery.';

  @override
  String get downloadTaskRemoved => 'Task removed';

  @override
  String get completedTasksCleared => 'Completed tasks cleared';

  @override
  String get failedTasksCleared => 'Failed tasks cleared';

  @override
  String get activeStatus => 'Active';

  @override
  String get doneStatus => 'Done';

  @override
  String get failedStatus => 'Failed';

  @override
  String get noDownloadsYet => 'No downloads yet';

  @override
  String get english => 'English';

  @override
  String get simplifiedChinese => '简体中文';

  @override
  String get github => 'GitHub';

  @override
  String get share => 'share';

  @override
  String get copyLink => 'copyLink';

  @override
  String get shareUnavailable =>
      'Current content is temporarily unavailable to share.';

  @override
  String get linkCopied => 'Link copied.';

  @override
  String get discoverNavLabel => 'Discover';

  @override
  String get collectionsNavLabel => 'Collections';

  @override
  String get mineNavLabel => 'Mine';

  @override
  String get searchPlaceholder => 'Search photos, collections, users...';

  @override
  String get segmentPhotos => 'Photos';

  @override
  String get segmentCollections => 'Collections';

  @override
  String get segmentLikes => 'Likes';

  @override
  String get segmentUsers => 'Users';

  @override
  String get sortBy => 'Sort by';

  @override
  String get colorLabel => 'Color';

  @override
  String get orientationLabel => 'Orientation';

  @override
  String get contentSafety => 'Content safety';

  @override
  String get filterRelevant => 'Relevant';

  @override
  String get filterLatest => 'Latest';

  @override
  String get filterAny => 'Any';

  @override
  String get filterGreen => 'Green';

  @override
  String get filterBlue => 'Blue';

  @override
  String get filterBlackAndWhite => 'Black & White';

  @override
  String get filterLandscape => 'Landscape';

  @override
  String get filterPortrait => 'Portrait';

  @override
  String get filterSquarish => 'Squarish';

  @override
  String get filterLow => 'Low';

  @override
  String get filterHigh => 'High';

  @override
  String get noMatchingPhotos => 'No matching photos';

  @override
  String get noMatchingPhotosSubtitle =>
      'Try a different keyword or broaden the query.';

  @override
  String get noMatchingCollections => 'No matching collections';

  @override
  String get noMatchingCollectionsSubtitle =>
      'Try another phrase to find curated sets.';

  @override
  String get noMatchingUsers => 'No matching users';

  @override
  String get noMatchingUsersSubtitle =>
      'Try a creator name, username, or location.';

  @override
  String get startTypingToSearch => 'Start typing to search';

  @override
  String get searchIdleSubtitle =>
      'We will query photos, collections, and creators using the live search endpoints.';

  @override
  String get filterAll => 'All';

  @override
  String get likeError => 'Could not update like right now';

  @override
  String get signInToSavePhotos => 'Sign in to save photos';

  @override
  String get signInToSavePhotosBody =>
      'Build collections of what inspires you and keep them in sync with your Unsplash account.';

  @override
  String get featured => 'Featured';

  @override
  String byName(String name) {
    return 'by $name';
  }

  @override
  String get noPhotos => 'No photos';

  @override
  String get collectionsPageTitle => 'Collections';

  @override
  String get minePageTitle => 'Mine';

  @override
  String get likedPhotos => 'Liked photos';

  @override
  String get savedCollections => 'Saved collections';

  @override
  String get personalSpace => 'Personal space';

  @override
  String get likedPhotosDesc =>
      'Revisit favorites you loved without hunting through the feed again.';

  @override
  String get savedCollectionsDesc =>
      'Build a shelf of references, moods, and places you want to return to.';

  @override
  String get personalSpaceDesc =>
      'A home for your archive now, with room for preferences and history later.';

  @override
  String get signIn => 'Sign in';

  @override
  String get yourArchiveSynced => 'Your visual archive, synced with Unsplash';

  @override
  String get keepLikesSaves =>
      'Keep likes, saves, and your personal archive connected in one calm workspace.';

  @override
  String get weUseUnsplashAccount =>
      'We use your Unsplash account to sync likes, saves, and your personal archive.';

  @override
  String get continueWithUnsplash => 'Continue with Unsplash';

  @override
  String get guestMode => 'Guest mode';

  @override
  String get guestModeDesc => 'You can keep exploring without signing in';

  @override
  String get guestModeBody =>
      'Discover, search, browse collections, and open public photographer profiles anytime. Sign in only when you want your activity to stay with you.';

  @override
  String get guestChipDiscover => 'Discover';

  @override
  String get guestChipSearch => 'Search';

  @override
  String get guestChipCollections => 'Collections';

  @override
  String get guestChipProfiles => 'Profiles';

  @override
  String get browseAsGuest => 'Browse as guest';

  @override
  String get browseProfiles => 'Browse profiles';

  @override
  String get workspace => 'Workspace';

  @override
  String get personalWorkspaceSubtitle =>
      'Personal workspace for photos, collections, and saved inspiration.';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get saved => 'Saved';

  @override
  String get downloads => 'Downloads';

  @override
  String get syncingLatestProfile => 'Syncing latest profile...';

  @override
  String get showingCachedProfile => 'Showing your cached profile first.';

  @override
  String get noLikedPhotosYet => 'No liked photos yet.';

  @override
  String get nothingHereYet => 'Nothing here yet.';

  @override
  String get noCollectionsYet => 'No collections yet.';

  @override
  String get photos => 'Photos';

  @override
  String get collections => 'Collections';

  @override
  String get likes => 'Likes';

  @override
  String get noPublicPhotosYet => 'No public photos yet';

  @override
  String get noPublicCollectionsYet => 'No public collections yet';

  @override
  String likesReceived(int count) {
    return '$count likes received';
  }

  @override
  String get follow => 'Follow';

  @override
  String get following => 'Following';

  @override
  String get cameraInfo => 'CAMERA INFO';

  @override
  String get exifCamera => 'Camera';

  @override
  String get exifAperture => 'Aperture';

  @override
  String get exifShutter => 'Shutter';

  @override
  String get exifIso => 'ISO';

  @override
  String get exifFocal => 'Focal';

  @override
  String get exifLocation => 'Location';

  @override
  String get exifSize => 'Size';

  @override
  String get downloadFree => 'Download Free';

  @override
  String get moreFromPhotographer => 'More from photographer';

  @override
  String get seeAll => 'See all';

  @override
  String get tags => 'TAGS';

  @override
  String get tagsUnavailable =>
      'Tags unavailable until details finish loading.';

  @override
  String get cameraDetailsUnavailable =>
      'Camera details unavailable until hydration succeeds.';

  @override
  String get detailSectionsFailed =>
      'Some detail sections could not be loaded yet.';

  @override
  String get retryLoadingDetails => 'Retry loading details';

  @override
  String get authTitleDefault => 'Sign in to like photos';

  @override
  String get authBodyDefault =>
      'Save what moves you, keep your visual trail together, and sync every like with your Unsplash account.';

  @override
  String get authLikedPhotos => 'Liked photos';

  @override
  String get authLikedPhotosDesc =>
      'Revisit favorites across devices without losing your place.';

  @override
  String get authSaveForLater => 'Save for later';

  @override
  String get authSaveForLaterDesc =>
      'Build a private inspiration shelf that stays with you.';

  @override
  String get authTrustTitle => 'Continue with Unsplash';

  @override
  String get authTrustBody =>
      'We use your Unsplash account to connect likes, saves, and your personal archive.';

  @override
  String get notNow => 'Not now';

  @override
  String get sizeSmall => 'Small';

  @override
  String get sizeRegular => 'Regular';

  @override
  String get sizeFull => 'Full';

  @override
  String get sizeOriginal => 'Original';

  @override
  String get downloadSmall => 'Download Small';

  @override
  String get downloadRegular => 'Download Regular';

  @override
  String get downloadFull => 'Download Full';

  @override
  String get downloadOriginal => 'Download Original';

  @override
  String get downloadDescSmall => 'Fast to save and easy to share.';

  @override
  String get downloadDescRegular =>
      'A balanced choice for most screens and posts.';

  @override
  String get downloadDescFull =>
      'Sharper and more detailed for larger displays.';

  @override
  String get downloadDescOriginal =>
      'The largest available version with the most flexibility.';

  @override
  String get chooseSizeHint =>
      'Choose the size that works best for where you want to use this photo.';

  @override
  String get downloadProgress => 'Download Progress';

  @override
  String get downloadProgressCompleted =>
      'Your photo has been saved and is ready in the gallery.';

  @override
  String get downloadProgressFailed =>
      'Something went wrong while saving this image.';

  @override
  String get downloadProgressSaving =>
      'Almost there. We are moving the file into your gallery now.';

  @override
  String get downloadProgressDownloading =>
      'You can keep browsing while the download continues in the background.';

  @override
  String get doneAction => 'Done';

  @override
  String get backToSizes => 'Back to Sizes';

  @override
  String get downloadInBackground => 'Download in Background';

  @override
  String get downloadPreparing => 'Preparing download...';

  @override
  String get downloadSaving => 'Saving to gallery...';

  @override
  String get imageSavedToGallery => 'Image saved to gallery';

  @override
  String get downloadRequiresWifiMessage =>
      'Turn off Wi-Fi only or connect to Wi-Fi to download.';

  @override
  String get downloadFailed => 'Download failed';

  @override
  String get collectionSummary => 'Collection Summary';

  @override
  String get preview => 'Preview';

  @override
  String get firstFourPhotos => 'First four photos';

  @override
  String get openGrid => 'Open grid';

  @override
  String get collectionFacts => 'Collection Facts';

  @override
  String get continueExploring => 'Continue Exploring';

  @override
  String get exploreNearbyThemes => 'Explore nearby themes first';

  @override
  String get photoCollection => 'Photo collection';

  @override
  String get private => 'Private';

  @override
  String get public => 'Public';

  @override
  String get unknownCurator => 'Unknown curator';

  @override
  String get published => 'Published';

  @override
  String get updated => 'Updated';

  @override
  String get lastCollected => 'Last collected';

  @override
  String get visibility => 'Visibility';

  @override
  String get privateCollection => 'Private collection';

  @override
  String get publicCollection => 'Public collection';

  @override
  String get insideTheCollection => 'Inside the collection';

  @override
  String get noPhotosInCollection => 'No photos in this collection yet';

  @override
  String get previewUnavailable =>
      'Preview unavailable until details finish loading.';

  @override
  String get previewWillAppear => 'Preview will appear when photos are added';

  @override
  String get collectionDetailsUnavailable =>
      'Some collection details are still unavailable.';

  @override
  String get factsWillAppear =>
      'Additional collection facts will appear after details finish loading.';

  @override
  String get jumpToFeed => 'Jump to feed';

  @override
  String get noDescriptionFallback =>
      'No curator description has been added for this collection yet. The layout stays intact and shifts emphasis to the curator and photo stream.';

  @override
  String get curatedSets => 'Curated sets';

  @override
  String photoCount(int count) {
    return '$count photos';
  }

  @override
  String collectionsCount(int count) {
    return '$count collections';
  }

  @override
  String publishedDate(String date) {
    return 'Published $date';
  }

  @override
  String updatedDate(String date) {
    return 'Updated $date';
  }

  @override
  String lastCollectedDate(String date) {
    return 'Last collected $date';
  }

  @override
  String get newCollection => 'New collection';

  @override
  String get newCollectionDesc =>
      'Name it, add an optional note, and choose visibility.';

  @override
  String get collectionName => 'Collection Name';

  @override
  String get enterName => 'Enter a name';

  @override
  String get descriptionOptional => 'Description Optional';

  @override
  String get addDescription => 'Add a description...';

  @override
  String get onlyYouCanSee => 'Only you can see it.';

  @override
  String get visibleOnProfile => 'Visible on your profile.';

  @override
  String get visibleOnYourProfile => 'Visible on your profile';

  @override
  String get onlyForYourArchive => 'Only for your own archive';

  @override
  String get createCollection => 'Create collection';

  @override
  String get selectCollection => 'Select collection';

  @override
  String get savePhotoToCollection =>
      'Save this photo to one of your collections.';

  @override
  String get createNewCollection => 'Create new collection';

  @override
  String get noPerfectFitYet => 'No perfect fit yet? Make a new one.';

  @override
  String get myCollections => 'MY COLLECTIONS';

  @override
  String get backToCollections => 'Back to collections';

  @override
  String get view => 'View';

  @override
  String get retry => 'Retry';

  @override
  String savedTo(String title) {
    return 'Saved to $title';
  }

  @override
  String get deleteCollection => 'Delete collection?';

  @override
  String get deleteCollectionDesc =>
      'This permanently removes the collection and its saved links.';

  @override
  String willBeDeleted(String title) {
    return '$title will be deleted';
  }

  @override
  String get photosRemainUnsplash =>
      'The photos remain on Unsplash, but this collection cannot be restored once removed.';

  @override
  String get typeToConfirm => 'Type to confirm';

  @override
  String get deleteCollectionAction => 'Delete collection';

  @override
  String get editCollection => 'Edit collection';

  @override
  String get editCollectionDesc =>
      'Only the fields supported by the API are editable.';

  @override
  String get description => 'Description';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get manageCollection => 'Manage collection';

  @override
  String get manageCollectionDesc =>
      'Update the collection, clean up saved photos, or delete it safely.';

  @override
  String get editDetails => 'Edit details';

  @override
  String get editDetailsSubtitle => 'Title, description, and visibility';

  @override
  String get removePhotos => 'Remove photos';

  @override
  String get removePhotosSubtitle =>
      'Select multiple photos to remove them from this collection. Photos stay available on Unsplash.';

  @override
  String get deleteCollectionAction2 => 'Delete collection';

  @override
  String get deleteCollectionSubtitle => 'Permanent action with confirmation';

  @override
  String get genericError => 'Oops! Something went wrong';

  @override
  String get tryAgain => 'Try Again';

  @override
  String networkError(String message) {
    return 'Network error: $message';
  }

  @override
  String serverError(String message) {
    return 'Server error: $message';
  }

  @override
  String get signInAgain => 'Please sign in again.';

  @override
  String get tooManyRequests => 'Too many requests. Please try again later.';

  @override
  String get photoAlreadyInCollection => 'Photo already in this collection.';

  @override
  String get couldNotIdentifyUser =>
      'Could not identify user. Please sign in again.';

  @override
  String get signInAgainToCreate =>
      'Please sign in again to create collections.';

  @override
  String get batchMode => 'Batch Mode';

  @override
  String get selection => 'Selection';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String willRemovePhotosDesc(int count, String title) {
    return '$count photos will be removed from $title. This does not delete the original photos.';
  }

  @override
  String removeCountPhotos(int count) {
    return 'Remove $count photos';
  }

  @override
  String get noCollectionsSubtitle =>
      'Check back later for curated collections';

  @override
  String get signInToCreateCollections => 'Sign in to create collections';

  @override
  String get signInToCreateCollectionsBody =>
      'Save your favorite photos into custom collections and organize them your way.';

  @override
  String get colorPalette => 'COLOR PALETTE';

  @override
  String copiedHex(String hex) {
    return 'Copied $hex';
  }

  @override
  String get unableToLoadPhoto => 'Unable to load photo';

  @override
  String get unknownUser => '@unknown';

  @override
  String get exploreThemeRoadTrips => 'Road trips';

  @override
  String get exploreThemeNationalParks => 'National parks';

  @override
  String get exploreThemeLandscape => 'Landscape';

  @override
  String get exploreThemeOpenSky => 'Open sky';

  @override
  String get exploreThemeTravelNotes => 'Travel notes';
}
