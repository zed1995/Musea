import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:musea/features/settings/presentation/providers/settings_provider.dart';
import 'package:musea/features/settings/presentation/widgets/settings_section.dart';
import 'package:musea/l10n/generated/app_localizations.dart';
import 'package:musea/shared/widgets/android_top_bar.dart';

class SettingsLanguagePage extends ConsumerWidget {
  const SettingsLanguagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsControllerProvider);
    final selected = settings.value?.language ?? AppLanguage.system;

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AndroidTopBar(
        titleText: l10n.languageSetting,
        showBackButton: Navigator.of(context).canPop(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          SettingsSection(
            title: l10n.languageSetting,
            children: [
              _LanguageOption(
                title: l10n.followSystemLanguage,
                isSelected: selected == AppLanguage.system,
                onTap: () => ref
                    .read(settingsControllerProvider.notifier)
                    .setLanguage(AppLanguage.system),
              ),
              _LanguageOption(
                title: l10n.english,
                isSelected: selected == AppLanguage.english,
                onTap: () => ref
                    .read(settingsControllerProvider.notifier)
                    .setLanguage(AppLanguage.english),
              ),
              _LanguageOption(
                title: l10n.simplifiedChinese,
                isSelected: selected == AppLanguage.simplifiedChinese,
                onTap: () => ref
                    .read(settingsControllerProvider.notifier)
                    .setLanguage(AppLanguage.simplifiedChinese),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 60,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray900,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.gray900 : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: isSelected ? AppColors.gray900 : AppColors.gray300,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
