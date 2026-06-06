import 'package:flutter/material.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/core/theme/text_styles.dart';
import 'package:musea/features/discover/domain/entities/topic.dart';
import 'package:musea/l10n/generated/app_localizations.dart';

class TopicBar extends StatelessWidget {
  const TopicBar({
    super.key,
    required this.topics,
    this.selectedTopicSlug,
    this.showAll = true,
    required this.onTopicTap,
  });

  final List<Topic> topics;
  final String? selectedTopicSlug;
  final bool showAll;
  final ValueChanged<String?> onTopicTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: topics.length + (showAll ? 1 : 0),
        itemBuilder: (context, index) {
          if (showAll && index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _TopicChip(
                label: AppLocalizations.of(context)!.filterAll,
                isSelected: selectedTopicSlug == null,
                onTap: () => onTopicTap(null),
              ),
            );
          }
          final topicIndex = showAll ? index - 1 : index;
          final topic = topics[topicIndex];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _TopicChip(
              label: topic.title,
              isSelected: selectedTopicSlug == topic.slug,
              onTap: () => onTopicTap(topic.slug),
            ),
          );
        },
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.gray200,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isSelected ? AppColors.onPrimary : AppColors.gray600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
