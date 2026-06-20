import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:musea/features/settings/presentation/providers/settings_provider.dart';
import 'package:musea/features/settings/presentation/widgets/settings_section.dart';
import 'package:musea/l10n/generated/app_localizations.dart';
import 'package:musea/shared/widgets/android_top_bar.dart';

class SettingsAppearancePage extends ConsumerWidget {
  const SettingsAppearancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsControllerProvider);
    final selected = settings.value?.themeMode ?? AppThemeMode.system;

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AndroidTopBar(
        titleText: l10n.appearanceTitle,
        showBackButton: Navigator.of(context).canPop(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          SettingsSection(
            title: l10n.appearanceTitle,
            children: [
              _ThemeOption(
                title: l10n.themeSystem,
                isSelected: selected == AppThemeMode.system,
                onTap: () => ref
                    .read(settingsControllerProvider.notifier)
                    .setThemeMode(AppThemeMode.system),
              ),
              _ThemeOption(
                title: l10n.themeLight,
                isSelected: selected == AppThemeMode.light,
                onTap: () => ref
                    .read(settingsControllerProvider.notifier)
                    .setThemeMode(AppThemeMode.light),
              ),
              _ThemeOption(
                title: l10n.themeDark,
                isSelected: selected == AppThemeMode.dark,
                onTap: () => ref
                    .read(settingsControllerProvider.notifier)
                    .setThemeMode(AppThemeMode.dark),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
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
