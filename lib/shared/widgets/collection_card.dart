import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/l10n/generated/app_localizations.dart';
import 'package:musea/router/detail_route_extras.dart';

class CollectionCard extends StatelessWidget {
  const CollectionCard({super.key, required this.collection});

  final Collection collection;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final coverUrl = collection.coverPhoto?.urlRegular ??
        (collection.previewPhotos.isNotEmpty
            ? collection.previewPhotos.first.smallUrl
            : null);
    final previewCount = collection.previewPhotos.length.clamp(0, 4);

    return GestureDetector(
      onTap: () => context.push(
        '/collection/${collection.id}',
        extra: CollectionDetailExtra(collection: collection),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            SizedBox(
              height: 152,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (coverUrl != null)
                    CachedNetworkImage(
                      imageUrl: coverUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => _placeholder(),
                    )
                  else
                    _placeholder(),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.08),
                          Colors.black.withValues(alpha: 0.36),
                          Colors.black.withValues(alpha: 0.58),
                        ],
                        stops: const [0.0, 0.24, 0.72, 1.0],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 42, 14, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                collection.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.2,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _metaText(l10n),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.78),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isFeatured) ...[
                              _MetaPill(
                                child: Text(
                                  l10n.featured,
                                  style: _pillTextStyle,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            _MetaPill(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${collection.totalPhotos}',
                                    style: _pillTextStyle,
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.chevron_right,
                                    size: 14,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (previewCount > 0)
              SizedBox(
                height: 46,
                child: Row(
                  children:
                      collection.previewPhotos.take(previewCount).map((photo) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: CachedNetworkImage(
                          imageUrl: photo.smallUrl,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.gray200,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool get _isFeatured => collection.totalPhotos >= 20;

  String _metaText(AppLocalizations l10n) {
    if (collection.user?.name case final name? when name.isNotEmpty) {
      return l10n.byName(name);
    }
    return l10n.photoCount(collection.totalPhotos);
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.gray200,
      child: const Center(
        child: Icon(
          Icons.photo_library_outlined,
          size: 38,
          color: AppColors.gray400,
        ),
      ),
    );
  }
}

const _pillTextStyle = TextStyle(
  color: Colors.white,
  fontSize: 10,
  fontWeight: FontWeight.w700,
  height: 1.0,
);

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Center(child: child),
    );
  }
}
