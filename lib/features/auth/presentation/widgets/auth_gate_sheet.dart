import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/features/auth/presentation/providers/auth_provider.dart';
import 'package:musea/l10n/generated/app_localizations.dart';

Future<void> showAuthGateSheet(
  BuildContext context,
  WidgetRef ref, {
  String title = '',
  String body = '',
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return Consumer(
        builder: (context, ref, child) {
          final l10n = AppLocalizations.of(context)!;
          final authState = ref.watch(authControllerProvider);
          final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
          return Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(16, 10, 16, bottomInset),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 32,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4D4D8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title.isNotEmpty ? title : l10n.authTitleDefault,
                  style: const TextStyle(
                    fontSize: 30,
                    height: 1.02,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.4,
                    color: Color(0xFF09090B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body.isNotEmpty ? body : l10n.authBodyDefault,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.7,
                    color: Color(0xFF52525B),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _AuthBenefitCard(
                        icon: Icons.favorite_border_rounded,
                        title: l10n.authLikedPhotos,
                        body: l10n.authLikedPhotosDesc,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _AuthBenefitCard(
                        icon: Icons.bookmark_border_rounded,
                        title: l10n.authSaveForLater,
                        body: l10n.authSaveForLaterDesc,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const _AuthTrustCard(),
                if (authState.errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    authState.errorMessage!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFB91C1C),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: authState.isAuthorizing
                        ? null
                        : () async {
                            Navigator.of(context).pop();
                            await ref
                                .read(authControllerProvider.notifier)
                                .beginSignIn();
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF18181B),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: authState.isAuthorizing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.chevron_right_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                l10n.continueWithUnsplash,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF3F3F46),
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      l10n.notNow,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _AuthBenefitCard extends StatelessWidget {
  const _AuthBenefitCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDEDF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF3F3F46)),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF18181B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Color(0xFF71717A),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthTrustCard extends StatelessWidget {
  const _AuthTrustCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.authTrustTitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF18181B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.authTrustBody,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Color(0xFF71717A),
            ),
          ),
        ],
      ),
    );
  }
}
