import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musea/core/services/cache_summary_service.dart';
import 'package:musea/core/services/download_notifier.dart';
import 'package:musea/core/services/providers.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/features/auth/presentation/providers/auth_provider.dart';
import 'package:musea/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:musea/features/settings/presentation/providers/settings_provider.dart';
import 'package:musea/features/settings/presentation/widgets/settings_row.dart';
import 'package:musea/features/settings/presentation/widgets/settings_section.dart';
import 'package:musea/l10n/generated/app_localizations.dart';
import 'package:musea/shared/widgets/android_top_bar.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsControllerProvider);
    final cacheBytes = ref.watch(cacheBytesProvider);
    final version = ref.watch(appVersionProvider);

    final current = settings.value;
    final downloadTasks = ref.watch(downloadNotifierProvider).tasks;
    final activeDownloadCount = downloadTasks
        .where((task) => task.status == DownloadTaskStatus.downloading)
        .length;
    final downloadTaskCount =
        activeDownloadCount > 0 ? activeDownloadCount : downloadTasks.length;
    final languageLabel = switch (current?.language ?? AppLanguage.system) {
      AppLanguage.system => l10n.followSystemLanguage,
      AppLanguage.english => l10n.english,
      AppLanguage.simplifiedChinese => l10n.simplifiedChinese,
    };
    final themeLabel = switch (current?.themeMode ?? AppThemeMode.system) {
      AppThemeMode.system => l10n.themeSystem,
      AppThemeMode.light => l10n.themeLight,
      AppThemeMode.dark => l10n.themeDark,
    };

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AndroidTopBar(
        titleText: l10n.settingsTitle,
        showBackButton: Navigator.of(context).canPop(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          SettingsSection(
            title: l10n.preferencesTitle,
            children: [
              SettingsRow(
                icon: Icons.palette_outlined,
                title: l10n.appearanceTitle,
                trailing: _ChevronValue(value: themeLabel),
                onTap: () => context.push('/settings/appearance'),
              ),
              SettingsRow(
                icon: Icons.translate_rounded,
                title: l10n.languageSetting,
                trailing: _ChevronValue(value: languageLabel),
                onTap: () => context.push('/settings/language'),
              ),
              SettingsRow(
                icon: Icons.wifi_rounded,
                title: l10n.downloadOverWifiOnlySetting,
                trailing: Switch(
                  value: current?.downloadOverWifiOnly ?? true,
                  onChanged: (value) {
                    ref
                        .read(settingsControllerProvider.notifier)
                        .setDownloadOverWifiOnly(value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SettingsSection(
            title: l10n.storageTitle,
            children: [
              SettingsRow(
                icon: Icons.delete_outline_rounded,
                title: l10n.cacheSetting,
                trailing: _ChevronValue(
                  value: CacheSummaryService.formatBytes(cacheBytes.value ?? 0),
                ),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.clearCacheTitle),
                      content: Text(l10n.clearCacheBody),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(l10n.cancelAction),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(l10n.clearAction),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await ref
                        .read(settingsControllerProvider.notifier)
                        .clearCache();
                  }
                },
              ),
              SettingsRow(
                icon: Icons.download_rounded,
                title: l10n.downloadsSetting,
                trailing: _ChevronValue(
                  value: l10n.downloadsTaskCount(downloadTaskCount),
                ),
                onTap: () => context.push('/settings/downloads'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SettingsSection(
            title: l10n.aboutTitle,
            children: [
              SettingsRow(
                icon: Icons.info_outline_rounded,
                title: l10n.versionSetting,
                trailing: Text(version.value ?? '...'),
              ),
              SettingsRow(
                icon: Icons.code_rounded,
                title: l10n.feedbackSetting,
                trailing: _ChevronValue(value: l10n.github),
                onTap: () async {
                  await ref.read(feedbackLauncherProvider)(
                    ref.read(feedbackUriProvider),
                  );
                },
              ),
            ],
          ),
          if (ref.watch(authControllerProvider).isAuthenticated) ...[
            const SizedBox(height: 28),
            SizedBox(
              height: 48,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  backgroundColor: AppColors.error.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.signOutTitle),
                      content: Text(l10n.signOutBody),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(l10n.cancelAction),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(l10n.signOutAction),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await ref.read(authControllerProvider.notifier).signOut();
                    if (context.mounted && Navigator.of(context).canPop()) {
                      context.pop();
                    }
                  }
                },
                icon: const Icon(Icons.logout_rounded),
                label: Text(l10n.signOutAction),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChevronValue extends StatelessWidget {
  const _ChevronValue({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.gray500,
          ),
        ),
        const SizedBox(width: 2),
        const Icon(
          Icons.chevron_right_rounded,
          size: 18,
          color: AppColors.gray400,
        ),
      ],
    );
  }
}
