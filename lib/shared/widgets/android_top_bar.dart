import 'package:flutter/material.dart';
import 'package:musea/core/theme/colors.dart';

class AndroidTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AndroidTopBar({
    super.key,
    required this.titleText,
    this.showBackButton = false,
    this.onBack,
    this.leading,
    this.trailing,
    this.bottomBorder = true,
  });

  final String titleText;
  final bool showBackButton;
  final VoidCallback? onBack;
  final Widget? leading;
  final Widget? trailing;
  final bool bottomBorder;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final left = leading ??
        (showBackButton
            ? IconButton(
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
              )
            : const SizedBox(width: 40, height: 40));
    final right = trailing ?? const SizedBox(width: 40, height: 40);

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.gray50,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0,
      bottom: bottomBorder
          ? const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1),
            )
          : null,
      title: Row(
        children: [
          SizedBox(
            width: 48,
            child: Align(alignment: Alignment.centerLeft, child: left),
          ),
          Expanded(
            child: Text(
              titleText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.gray900,
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: Align(alignment: Alignment.centerRight, child: right),
          ),
        ],
      ),
    );
  }
}
