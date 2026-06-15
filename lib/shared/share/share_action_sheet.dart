import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/l10n/generated/app_localizations.dart';
import 'package:musea/shared/share/app_share_service.dart';

Future<void> showShareActionSheet(
  BuildContext context,
  WidgetRef ref, {
  required String? shareUrl,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final l10n = AppLocalizations.of(sheetContext)!;
      final shareService = ref.read(appShareServiceProvider);

      Future<void> handleShare() async {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(sheetContext).pop();

        final result = await shareService.shareUrl(shareUrl);
        if (!context.mounted || result is! ShareResolutionFailure) return;

        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(l10n.shareUnavailable)),
          );
      }

      Future<void> handleCopyLink() async {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(sheetContext).pop();

        final result = await shareService.copyUrl(shareUrl);
        if (!context.mounted) return;

        messenger.hideCurrentSnackBar();
        if (result is ShareResolutionFailure) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.shareUnavailable)),
          );
          return;
        }

        messenger.showSnackBar(
          SnackBar(content: Text(l10n.linkCopied)),
        );
      }

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.ios_share_rounded),
              title: Text(l10n.share),
              onTap: handleShare,
            ),
            ListTile(
              leading: const Icon(Icons.link_rounded),
              title: Text(l10n.copyLink),
              onTap: handleCopyLink,
            ),
          ],
        ),
      );
    },
  );
}
