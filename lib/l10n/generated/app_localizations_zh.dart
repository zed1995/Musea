// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get settingsTitle => '设置';

  @override
  String get preferencesTitle => '偏好设置';

  @override
  String get appearanceTitle => '外观';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get languageSetting => '语言';

  @override
  String get downloadOverWifiOnlySetting => '仅在 Wi‑Fi 下下载';

  @override
  String get storageTitle => '存储';

  @override
  String get cacheSetting => '缓存';

  @override
  String get clearCacheTitle => '清除缓存？';

  @override
  String get clearCacheBody => '这会移除临时缓存，但不会删除已下载的内容。';

  @override
  String get cancelAction => '取消';

  @override
  String get clearAction => '清除';

  @override
  String get downloadsSetting => '下载任务';

  @override
  String downloadsTaskCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个任务',
      one: '1 个任务',
    );
    return '$_temp0';
  }

  @override
  String get aboutTitle => '关于';

  @override
  String get versionSetting => '版本';

  @override
  String get feedbackSetting => '反馈';

  @override
  String get signOutAction => '退出登录';

  @override
  String get signOutTitle => '退出登录？';

  @override
  String get signOutBody => '当前账号会从这台设备上退出。';

  @override
  String get followSystemLanguage => '跟随系统';

  @override
  String get downloadsPageTitle => '下载任务';

  @override
  String get downloadingSection => '下载中';

  @override
  String get completedSection => '已完成';

  @override
  String get failedSection => '失败';

  @override
  String get retryAction => '重试';

  @override
  String get deleteAction => '删除';

  @override
  String get clearCompletedAction => '清除已完成';

  @override
  String get clearFailedAction => '清除失败';

  @override
  String get downloadRecordsOnlyHint => '删除任务只会移除这里的记录，不会删除系统相册中已经保存的图片。';

  @override
  String get downloadTaskRemoved => '任务记录已删除';

  @override
  String get completedTasksCleared => '已完成任务已清除';

  @override
  String get failedTasksCleared => '失败任务已清除';

  @override
  String get activeStatus => '进行中';

  @override
  String get doneStatus => '完成';

  @override
  String get failedStatus => '失败';

  @override
  String get noDownloadsYet => '还没有下载任务';

  @override
  String get english => 'English';

  @override
  String get simplifiedChinese => '简体中文';

  @override
  String get github => 'GitHub';

  @override
  String get share => '分享';

  @override
  String get copyLink => '复制链接';

  @override
  String get shareUnavailable => '当前内容暂时无法分享。';

  @override
  String get linkCopied => '链接已复制。';

  @override
  String get discoverNavLabel => '发现';

  @override
  String get collectionsNavLabel => '合集';

  @override
  String get mineNavLabel => '我的';

  @override
  String get searchPlaceholder => '搜索图片、合集、用户...';

  @override
  String get segmentPhotos => '图片';

  @override
  String get segmentCollections => '合集';

  @override
  String get segmentLikes => '喜欢';

  @override
  String get segmentUsers => '用户';

  @override
  String get sortBy => '排序';

  @override
  String get colorLabel => '颜色';

  @override
  String get orientationLabel => '方向';

  @override
  String get contentSafety => '内容安全';

  @override
  String get filterRelevant => '相关';

  @override
  String get filterLatest => '最新';

  @override
  String get filterAny => '不限';

  @override
  String get filterGreen => '绿色';

  @override
  String get filterBlue => '蓝色';

  @override
  String get filterBlackAndWhite => '黑白';

  @override
  String get filterLandscape => '横屏';

  @override
  String get filterPortrait => '竖屏';

  @override
  String get filterSquarish => '方形';

  @override
  String get filterLow => '低';

  @override
  String get filterHigh => '高';

  @override
  String get noMatchingPhotos => '没有匹配的图片';

  @override
  String get noMatchingPhotosSubtitle => '换个关键词或放宽搜索条件试试。';

  @override
  String get noMatchingCollections => '没有匹配的合集';

  @override
  String get noMatchingCollectionsSubtitle => '换个词组试试，看看有没有精选合集。';

  @override
  String get noMatchingUsers => '没有匹配的用户';

  @override
  String get noMatchingUsersSubtitle => '试试搜索创作者名称、用户名或所在地。';

  @override
  String get startTypingToSearch => '输入关键词开始搜索';

  @override
  String get searchIdleSubtitle => '我们将通过实时搜索接口查询图片、合集和创作者。';

  @override
  String get filterAll => '全部';

  @override
  String get likeError => '暂时无法更新点赞';

  @override
  String get signInToSavePhotos => '登录以保存图片';

  @override
  String get signInToSavePhotosBody => '创建灵感合集，并与 Unsplash 账号同步。';

  @override
  String get featured => '精选';

  @override
  String byName(String name) {
    return '来自 $name';
  }

  @override
  String get noPhotos => '暂无图片';

  @override
  String get collectionsPageTitle => '合集';

  @override
  String get minePageTitle => '我的';

  @override
  String get likedPhotos => '喜欢的图片';

  @override
  String get savedCollections => '保存的合集';

  @override
  String get personalSpace => '个人空间';

  @override
  String get likedPhotosDesc => '回看你曾经喜欢的图片，无需在信息流中重新翻找。';

  @override
  String get savedCollectionsDesc => '打造一个属于你的参考书签、心情和想去的地方。';

  @override
  String get personalSpaceDesc => '你的个人档案空间，未来还将容纳偏好设置和历史记录。';

  @override
  String get signIn => '登录';

  @override
  String get yourArchiveSynced => '你的视觉档案，与 Unsplash 同步';

  @override
  String get keepLikesSaves => '在统一的工作区中管理喜欢、收藏和个人档案。';

  @override
  String get weUseUnsplashAccount => '我们使用你的 Unsplash 账号来同步喜欢、收藏和个人档案。';

  @override
  String get continueWithUnsplash => '使用 Unsplash 继续';

  @override
  String get guestMode => '游客模式';

  @override
  String get guestModeDesc => '无需登录即可继续探索';

  @override
  String get guestModeBody => '随时浏览、搜索、查看合集和摄影师的公开主页。只有当你希望保存活动记录时才需要登录。';

  @override
  String get guestChipDiscover => '发现';

  @override
  String get guestChipSearch => '搜索';

  @override
  String get guestChipCollections => '合集';

  @override
  String get guestChipProfiles => '主页';

  @override
  String get browseAsGuest => '游客浏览';

  @override
  String get browseProfiles => '浏览主页';

  @override
  String get workspace => '工作区';

  @override
  String get personalWorkspaceSubtitle => '用于管理图片、合集和收藏灵感的个人工作空间。';

  @override
  String get editProfile => '编辑资料';

  @override
  String get saved => '已收藏';

  @override
  String get downloads => '下载';

  @override
  String get syncingLatestProfile => '正在同步最新资料...';

  @override
  String get showingCachedProfile => '当前显示的是缓存的个人资料。';

  @override
  String get noLikedPhotosYet => '还没有喜欢的图片。';

  @override
  String get nothingHereYet => '这里还没有内容。';

  @override
  String get noCollectionsYet => '还没有合集。';

  @override
  String get photos => '图片';

  @override
  String get collections => '合集';

  @override
  String get likes => '喜欢';

  @override
  String get noPublicPhotosYet => '暂无公开图片';

  @override
  String get noPublicCollectionsYet => '暂无公开合集';

  @override
  String likesReceived(int count) {
    return '获得 $count 次喜欢';
  }

  @override
  String get follow => '关注';

  @override
  String get following => '已关注';

  @override
  String get followReadOnlyHint => '请在 unsplash.com 上关注该摄影师';

  @override
  String get cameraInfo => '相机信息';

  @override
  String get exifCamera => '相机';

  @override
  String get exifAperture => '光圈';

  @override
  String get exifShutter => '快门';

  @override
  String get exifIso => 'ISO';

  @override
  String get exifFocal => '焦距';

  @override
  String get exifLocation => '位置';

  @override
  String get exifSize => '尺寸';

  @override
  String get downloadFree => '免费下载';

  @override
  String get moreFromPhotographer => '摄影师更多作品';

  @override
  String get seeAll => '查看全部';

  @override
  String get tags => '标签';

  @override
  String get tagsUnavailable => '标签详情加载中，请稍候。';

  @override
  String get cameraDetailsUnavailable => '相机信息加载中，完成后方可显示。';

  @override
  String get detailSectionsFailed => '部分详情段落暂时无法加载。';

  @override
  String get retryLoadingDetails => '重试加载详情';

  @override
  String get authTitleDefault => '登录以喜欢图片';

  @override
  String get authBodyDefault => '保存你喜欢的作品，记录你的视觉足迹，并同步每次喜欢到 Unsplash 账号。';

  @override
  String get authLikedPhotos => '喜欢的图片';

  @override
  String get authLikedPhotosDesc => '跨设备回顾你的喜好，轻松找回你的位置。';

  @override
  String get authSaveForLater => '稍后收藏';

  @override
  String get authSaveForLaterDesc => '打造一个专属灵感书架，随时翻阅。';

  @override
  String get authTrustTitle => '使用 Unsplash 继续';

  @override
  String get authTrustBody => '我们使用你的 Unsplash 账号关联喜欢、收藏和个人档案。';

  @override
  String get notNow => '稍后再说';

  @override
  String get sizeSmall => '小';

  @override
  String get sizeRegular => '中';

  @override
  String get sizeFull => '大';

  @override
  String get sizeOriginal => '原图';

  @override
  String get downloadSmall => '下载小尺寸';

  @override
  String get downloadRegular => '下载中尺寸';

  @override
  String get downloadFull => '下载大尺寸';

  @override
  String get downloadOriginal => '下载原图';

  @override
  String get downloadDescSmall => '保存快速，方便分享。';

  @override
  String get downloadDescRegular => '适合大多数屏幕和帖子的平衡选择。';

  @override
  String get downloadDescFull => '更清晰、更细致，适合大屏显示。';

  @override
  String get downloadDescOriginal => '最大可用版本，灵活性最高。';

  @override
  String get chooseSizeHint => '选择最适合你使用场景的图片尺寸。';

  @override
  String get downloadProgress => '下载进度';

  @override
  String get downloadProgressCompleted => '图片已保存到相册。';

  @override
  String get downloadProgressFailed => '保存图片时出现了问题。';

  @override
  String get downloadProgressSaving => '即将完成，正在将文件移至相册。';

  @override
  String get downloadProgressDownloading => '你可以继续浏览，下载将在后台进行。';

  @override
  String get doneAction => '完成';

  @override
  String get backToSizes => '返回尺寸选择';

  @override
  String get downloadInBackground => '后台下载';

  @override
  String get downloadPreparing => '准备下载…';

  @override
  String get downloadSaving => '保存到相册…';

  @override
  String get imageSavedToGallery => '图片已保存到相册';

  @override
  String get downloadRequiresWifiMessage => '请关闭“仅在 Wi‑Fi 下下载”或连接到 Wi‑Fi 后再下载。';

  @override
  String get downloadFailed => '下载失败';

  @override
  String get collectionSummary => '合集摘要';

  @override
  String get preview => '预览';

  @override
  String get firstFourPhotos => '前四张图片';

  @override
  String get openGrid => '打开网格';

  @override
  String get collectionFacts => '合集信息';

  @override
  String get continueExploring => '继续探索';

  @override
  String get exploreNearbyThemes => '先从相近主题开始探索';

  @override
  String get photoCollection => '图片合集';

  @override
  String get private => '私密';

  @override
  String get public => '公开';

  @override
  String get unknownCurator => '未知创建者';

  @override
  String get published => '发布';

  @override
  String get updated => '更新';

  @override
  String get lastCollected => '最后收藏';

  @override
  String get visibility => '可见性';

  @override
  String get privateCollection => '私密合集';

  @override
  String get publicCollection => '公开合集';

  @override
  String get insideTheCollection => '合集中内容';

  @override
  String get noPhotosInCollection => '这个合集中还没有图片';

  @override
  String get previewUnavailable => '详情加载中，预览暂时不可用。';

  @override
  String get previewWillAppear => '添加图片后预览将会出现';

  @override
  String get collectionDetailsUnavailable => '部分合集详情暂时不可用。';

  @override
  String get factsWillAppear => '更多合集信息将在详情加载完成后显示。';

  @override
  String get jumpToFeed => '跳转至信息流';

  @override
  String get noDescriptionFallback => '暂无创建者描述，重点展示创建者和图片。';

  @override
  String get curatedSets => '精选合集';

  @override
  String photoCount(int count) {
    return '$count 张图片';
  }

  @override
  String collectionsCount(int count) {
    return '$count 个合集';
  }

  @override
  String publishedDate(String date) {
    return '发布于 $date';
  }

  @override
  String updatedDate(String date) {
    return '更新于 $date';
  }

  @override
  String lastCollectedDate(String date) {
    return '最后收藏于 $date';
  }

  @override
  String get newCollection => '新建合集';

  @override
  String get newCollectionDesc => '起个名字，添加可选备注，并选择可见性。';

  @override
  String get collectionName => '合集名称';

  @override
  String get enterName => '输入名称';

  @override
  String get descriptionOptional => '描述（可选）';

  @override
  String get addDescription => '添加描述...';

  @override
  String get onlyYouCanSee => '只有你能看到。';

  @override
  String get visibleOnProfile => '个人主页上可见。';

  @override
  String get visibleOnYourProfile => '个人主页上可见';

  @override
  String get onlyForYourArchive => '仅限个人存档';

  @override
  String get createCollection => '创建合集';

  @override
  String get selectCollection => '选择合集';

  @override
  String get savePhotoToCollection => '将这张图片保存到你的某个合集。';

  @override
  String get createNewCollection => '新建合集';

  @override
  String get noPerfectFitYet => '没有合适的？新建一个。';

  @override
  String get myCollections => '我的合集';

  @override
  String get backToCollections => '返回合集列表';

  @override
  String get view => '查看';

  @override
  String get retry => '重试';

  @override
  String savedTo(String title) {
    return '已保存到「$title」';
  }

  @override
  String get deleteCollection => '删除合集？';

  @override
  String get deleteCollectionDesc => '这将永久移除该合集及其保存的链接。';

  @override
  String willBeDeleted(String title) {
    return '「$title」将被删除';
  }

  @override
  String get photosRemainUnsplash => '图片仍保留在 Unsplash 上，但该合集一旦删除无法恢复。';

  @override
  String get typeToConfirm => '输入以确认';

  @override
  String get deleteCollectionAction => '删除合集';

  @override
  String get editCollection => '编辑合集';

  @override
  String get editCollectionDesc => '仅 API 支持的字段可编辑。';

  @override
  String get description => '描述';

  @override
  String get saveChanges => '保存更改';

  @override
  String get manageCollection => '管理合集';

  @override
  String get manageCollectionDesc => '更新合集信息、清理已保存的图片或安全删除合集。';

  @override
  String get editDetails => '编辑详情';

  @override
  String get editDetailsSubtitle => '标题、描述和可见性';

  @override
  String get removePhotos => '移除图片';

  @override
  String get removePhotosSubtitle => '选择多张图片将其从此合集中移除。图片仍保留在 Unsplash 上。';

  @override
  String get deleteCollectionAction2 => '删除合集';

  @override
  String get deleteCollectionSubtitle => '需要确认的永久性操作';

  @override
  String get genericError => '哎呀！出了点问题';

  @override
  String get tryAgain => '重试';

  @override
  String networkError(String message) {
    return '网络错误：$message';
  }

  @override
  String serverError(String message) {
    return '服务器错误：$message';
  }

  @override
  String get signInAgain => '请重新登录。';

  @override
  String get tooManyRequests => '请求过于频繁，请稍后重试。';

  @override
  String get photoAlreadyInCollection => '图片已在该合集中。';

  @override
  String get couldNotIdentifyUser => '无法识别用户，请重新登录。';

  @override
  String get signInAgainToCreate => '请重新登录以创建合集。';

  @override
  String get batchMode => '批量模式';

  @override
  String get selection => '已选择';

  @override
  String selectedCount(int count) {
    return '已选 $count 张';
  }

  @override
  String willRemovePhotosDesc(int count, String title) {
    return '将从此合集移除 $count 张图片。不会删除原始图片。';
  }

  @override
  String removeCountPhotos(int count) {
    return '移除 $count 张图片';
  }

  @override
  String get noCollectionsSubtitle => '稍后再来看看精选合集吧';

  @override
  String get signInToCreateCollections => '登录以创建合集';

  @override
  String get signInToCreateCollectionsBody => '将你喜欢的图片保存到自定义合集中，随心整理。';

  @override
  String get colorPalette => '调色板';

  @override
  String copiedHex(String hex) {
    return '已复制 $hex';
  }

  @override
  String get unableToLoadPhoto => '无法加载图片';

  @override
  String get unknownUser => '@unknown';

  @override
  String get exploreThemeRoadTrips => '公路旅行';

  @override
  String get exploreThemeNationalParks => '国家公园';

  @override
  String get exploreThemeLandscape => '风光';

  @override
  String get exploreThemeOpenSky => '开阔天空';

  @override
  String get exploreThemeTravelNotes => '旅行笔记';
}
