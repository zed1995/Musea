import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:share_plus/share_plus.dart';

sealed class ShareResolutionResult {
  const ShareResolutionResult();
}

class ShareResolutionSuccess extends ShareResolutionResult {
  const ShareResolutionSuccess(this.url);

  final String url;
}

class ShareResolutionFailure extends ShareResolutionResult {
  const ShareResolutionFailure.missingUrl();

  @override
  bool operator ==(Object other) => other is ShareResolutionFailure;

  @override
  int get hashCode => 17;
}

class AppShareService {
  const AppShareService({
    SharePlusProxy? sharePlus,
    ClipboardProxy? clipboard,
  })  : _sharePlus = sharePlus ?? const SharePlusProxy(),
        _clipboard = clipboard ?? const ClipboardProxy();

  final SharePlusProxy _sharePlus;
  final ClipboardProxy _clipboard;

  static String? resolvePhotoUrl(Photo photo) => photo.htmlLink;

  static String? resolveCollectionUrl(Collection collection) =>
      collection.links?.html;

  static String? resolveUserUrl(User user) => user.links?.html;

  static ShareResolutionResult validateUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return const ShareResolutionFailure.missingUrl();
    }
    return ShareResolutionSuccess(url);
  }

  Future<ShareResolutionResult> shareUrl(String? url) async {
    final result = validateUrl(url);
    if (result is ShareResolutionFailure) {
      return result;
    }

    try {
      await _sharePlus.share((result as ShareResolutionSuccess).url);
      return result;
    } catch (_) {
      return const ShareResolutionFailure.missingUrl();
    }
  }

  Future<ShareResolutionResult> copyUrl(String? url) async {
    final result = validateUrl(url);
    if (result is ShareResolutionFailure) {
      return result;
    }

    try {
      await _clipboard.setData((result as ShareResolutionSuccess).url);
      return result;
    } catch (_) {
      return const ShareResolutionFailure.missingUrl();
    }
  }
}

final appShareServiceProvider = Provider<AppShareService>((ref) {
  return const AppShareService();
});

class SharePlusProxy {
  const SharePlusProxy();

  Future<void> share(String text) async {
    await Share.share(text);
  }
}

class ClipboardProxy {
  const ClipboardProxy();

  Future<void> setData(String text) =>
      Clipboard.setData(ClipboardData(text: text));
}
