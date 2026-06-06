import 'package:flutter/material.dart';

class ImmersiveHeroAppBar extends StatelessWidget {
  const ImmersiveHeroAppBar({
    super.key,
    this.onBack,
    this.actions = const [],
    this.topPadding,
  });

  final VoidCallback? onBack;
  final List<Widget> actions;
  final double? topPadding;

  @override
  Widget build(BuildContext context) {
    final resolvedTopPadding = topPadding ?? MediaQuery.paddingOf(context).top;

    return Container(
      padding: EdgeInsets.only(
        top: resolvedTopPadding + 8,
        left: 4,
        right: 4,
        bottom: 28,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.38),
            Colors.black.withValues(alpha: 0.12),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
              ),
            ),
          ),
          const Spacer(),
          for (final action in actions)
            SizedBox(
              width: 48,
              height: 48,
              child: Center(child: action),
            ),
        ],
      ),
    );
  }
}
