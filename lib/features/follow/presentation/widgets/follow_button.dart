import 'package:flutter/material.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/l10n/generated/app_localizations.dart';

enum FollowButtonSize { compact, regular }

/// Read-only follow status badge.
///
/// The Unsplash API does not expose a follow/unfollow user endpoint, so this
/// widget only mirrors the `followedByUser` flag returned in the user payload.
/// Tapping the pill surfaces a hint directing users to follow on unsplash.com.
class FollowButton extends StatelessWidget {
  const FollowButton({
    super.key,
    required this.user,
    this.size = FollowButtonSize.regular,
  });

  final User user;
  final FollowButtonSize size;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final followed = user.followedByUser ?? false;

    return _FollowPill(
      size: size,
      label: followed ? l10n.following : l10n.follow,
      showCheck: followed,
      onTap: () => _showHint(context, l10n),
    );
  }

  void _showHint(BuildContext context, AppLocalizations l10n) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.followReadOnlyHint)));
  }
}

class _FollowPill extends StatelessWidget {
  const _FollowPill({
    required this.size,
    required this.label,
    required this.showCheck,
    required this.onTap,
  });

  final FollowButtonSize size;
  final String label;
  final bool showCheck;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final compact = size == FollowButtonSize.compact;
    final height = compact ? 28.0 : 36.0;
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 12)
        : const EdgeInsets.symmetric(horizontal: 18);
    final fontSize = compact ? 11.0 : 13.0;
    final followed = showCheck;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: followed ? AppColors.gray100 : AppColors.primary,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (followed) const Icon(Icons.check, size: 14, color: AppColors.gray900),
            if (followed) const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: followed ? AppColors.gray900 : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
