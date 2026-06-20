import 'package:flutter/material.dart';
import 'package:musea/core/theme/colors.dart';

class ImmersiveHeroAppBar extends StatelessWidget {
  const ImmersiveHeroAppBar({
    super.key,
    this.onBack,
    this.actions = const [],
    this.topPadding,
    this.progress = 0.0,
    this.scrolled = false,
    this.title,
  });

  final VoidCallback? onBack;
  final List<Widget> actions;
  final double? topPadding;
  final double progress;
  final bool scrolled;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final resolvedTopPadding = topPadding ?? MediaQuery.paddingOf(context).top;
    final background =
        Color.lerp(Colors.transparent, AppColors.gray50, progress)!;
    final borderOpacity = ((progress - 0.5) * 2.0).clamp(0.0, 1.0);
    final iconColor = scrolled ? AppColors.gray900 : Colors.white;
    final showTitle = title != null && title!.isNotEmpty;
    final titleOpacity = showTitle ? borderOpacity : 0.0;

    return Container(
      padding: EdgeInsets.only(
        top: resolvedTopPadding + 8,
        left: 4,
        right: 4,
        bottom: 0,
      ),
      decoration: BoxDecoration(color: background),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  color: iconColor,
                  onPressed:
                      onBack ?? () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
              Expanded(
                child: IgnorePointer(
                  child: Center(
                    child: Opacity(
                      key: const ValueKey('immersive-hero-app-bar-title'),
                      opacity: titleOpacity,
                      child: Text(
                        title ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              for (final action in actions)
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconTheme(
                    data: IconThemeData(color: iconColor),
                    child: action,
                  ),
                ),
            ],
          ),
          IgnorePointer(
            child: Opacity(
              opacity: borderOpacity,
              child: const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.gray200,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
