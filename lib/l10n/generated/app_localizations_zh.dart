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
  String get activeStatus => '进行中';

  @override
  String get doneStatus => '完成';

  @override
  String get failedStatus => '失败';

  @override
  String get noDownloadsYet => '还没有下载任务';

  @override
  String get discoverNavLabel => '发现';

  @override
  String get collectionsNavLabel => '合集';

  @override
  String get mineNavLabel => '我的';

  @override
  String get searchPlaceholder => '搜索图片、合集、用户...';

  @override
  String get minePageTitle => '我的';

  @override
  String get collectionsPageTitle => '合集';
}
