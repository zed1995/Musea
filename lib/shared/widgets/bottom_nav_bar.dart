import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:musea/l10n/generated/app_localizations.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _calculateSelectedIndex(location);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            border: Border(
              top: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon:
                    selectedIndex == 0 ? Icons.explore : Icons.explore_outlined,
                label: l10n.discoverNavLabel,
                isActive: selectedIndex == 0,
                onTap: () => _onItemTapped(0, context),
              ),
              _NavItem(
                icon: selectedIndex == 1
                    ? Icons.collections_bookmark
                    : Icons.collections_bookmark_outlined,
                label: l10n.collectionsNavLabel,
                isActive: selectedIndex == 1,
                onTap: () => _onItemTapped(1, context),
              ),
              _NavItem(
                icon: selectedIndex == 2 ? Icons.person : Icons.person_outline,
                label: l10n.mineNavLabel,
                isActive: selectedIndex == 2,
                onTap: () => _onItemTapped(2, context),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.only(bottom: 4, top: 4),
          color: Colors.white.withValues(alpha: 0.95),
          child: Center(
            child: Container(
              width: 128,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  int _calculateSelectedIndex(String location) {
    if (location.startsWith('/discover')) return 0;
    if (location.startsWith('/collections')) return 1;
    if (location == '/profile') return 2;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/discover');
        return;
      case 1:
        context.go('/collections');
        return;
      case 2:
        context.go('/profile');
        return;
    }
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minWidth: 64),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color:
                  isActive ? const Color(0xFF18181B) : const Color(0xFFA1A1AA),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: 0.2,
                color: isActive
                    ? const Color(0xFF18181B)
                    : const Color(0xFFA1A1AA),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
