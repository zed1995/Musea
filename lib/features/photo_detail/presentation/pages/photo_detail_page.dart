import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/features/auth/presentation/providers/auth_provider.dart';
import 'package:musea/features/auth/presentation/widgets/auth_gate_sheet.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/presentation/providers/photo_like_provider.dart';
import 'package:musea/features/discover/presentation/providers/photos_provider.dart';
import 'package:musea/features/photo_detail/presentation/widgets/color_palette_bar.dart';
import 'package:musea/features/photo_detail/presentation/widgets/download_sheet.dart';
import 'package:musea/features/profile/presentation/providers/profile_provider.dart';
import 'package:musea/router/detail_route_extras.dart';
import 'package:musea/shared/widgets/error_state.dart';
import 'package:musea/shared/widgets/loading_indicator.dart';

class PhotoDetailPage extends ConsumerWidget {
  const PhotoDetailPage({
    super.key,
    required this.photoId,
    this.initialPhoto,
    this.hydrateDeferredDetailsFromInitialPhoto = false,
  });

  final String photoId;
  final Photo? initialPhoto;
  final bool hydrateDeferredDetailsFromInitialPhoto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoAsync = ref.watch(photoDetailProvider(photoId));
    final resolvedPhoto = photoAsync.valueOrNull ?? initialPhoto;
    final isUsingInitialPhoto =
        initialPhoto != null && photoAsync.valueOrNull == null;
    final shouldHydrateDeferredSections =
        isUsingInitialPhoto && hydrateDeferredDetailsFromInitialPhoto;

    if (resolvedPhoto != null) {
      return _PhotoDetailContent(
        photo: resolvedPhoto,
        heroPhoto: initialPhoto ?? resolvedPhoto,
        onHeroTap: () => context.push(
          '/photo/$photoId/viewer',
          extra: PhotoViewerExtra(photo: resolvedPhoto),
        ),
        isHydratingDeferredContent:
            photoAsync.isLoading && shouldHydrateDeferredSections,
        showDeferredRetry: photoAsync.hasError && shouldHydrateDeferredSections,
        onRetryDeferred: () => ref.invalidate(photoDetailProvider(photoId)),
      );
    }

    return photoAsync.when(
      data: (photo) => _PhotoDetailContent(
        photo: photo,
        heroPhoto: photo,
        onHeroTap: () => context.push(
          '/photo/$photoId/viewer',
          extra: PhotoViewerExtra(photo: photo),
        ),
      ),
      loading: () => const Scaffold(
        body: Center(child: LoadingIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(),
        body: ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(photoDetailProvider(photoId)),
        ),
      ),
    );
  }
}

class _PhotoDetailContent extends ConsumerWidget {
  const _PhotoDetailContent({
    required this.photo,
    required this.heroPhoto,
    this.onHeroTap,
    this.isHydratingDeferredContent = false,
    this.showDeferredRetry = false,
    this.onRetryDeferred,
  });

  final Photo photo;
  final Photo heroPhoto;
  final VoidCallback? onHeroTap;
  final bool isHydratingDeferredContent;
  final bool showDeferredRetry;
  final VoidCallback? onRetryDeferred;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likeState = ref.watch(photoLikeStateProvider(photo));
    final showTagSkeleton = isHydratingDeferredContent && photo.tags.isEmpty;
    final showExifSkeleton = isHydratingDeferredContent && photo.exif == null;
    final showDeferredError =
        showDeferredRetry && (photo.tags.isEmpty || photo.exif == null);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _PhotoHero(
              photo: heroPhoto,
              onTap: onHeroTap,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _UserRow(photo: photo),
                  const SizedBox(height: 16),
                  _StatsStrip(
                    photo: photo,
                    likeState: likeState,
                    onLikeTap: () async {
                      final authState = ref.read(authControllerProvider);
                      if (!authState.isAuthenticated) {
                        await showAuthGateSheet(context, ref);
                        return;
                      }

                      final success = await ref
                          .read(photoLikeControllerProvider.notifier)
                          .toggle(photo: photo);
                      if (!context.mounted || success) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not update like right now'),
                        ),
                      );
                    },
                  ),
                  if (_description case final description?) ...[
                    const SizedBox(height: 16),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.55,
                        color: Color(0xFF52525B),
                      ),
                    ),
                  ],
                  if (showDeferredError) ...[
                    const SizedBox(height: 16),
                    _DeferredRetryBanner(onRetry: onRetryDeferred),
                  ],
                  if (photo.tags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: photo.tags
                          .map((tag) => _TagChip(label: tag.title))
                          .toList(),
                    ),
                  ] else if (showTagSkeleton) ...[
                    const SizedBox(height: 16),
                    const _DeferredSectionSkeleton(
                      key: ValueKey('photo-detail-tags-skeleton'),
                      title: 'TAGS',
                      lines: 2,
                    ),
                  ] else if (showDeferredError) ...[
                    const SizedBox(height: 16),
                    const _DeferredSectionPlaceholder(
                      title: 'TAGS',
                      message: 'Tags unavailable until details finish loading.',
                    ),
                  ],
                  if (_exifItems.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const _SectionDivider(),
                    const SizedBox(height: 6),
                    const Text(
                      'CAMERA INFO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF71717A),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 0),
                    _ExifGrid(items: _exifItems),
                  ] else if (showExifSkeleton) ...[
                    const SizedBox(height: 18),
                    const _DeferredSectionSkeleton(
                      key: ValueKey('photo-detail-exif-skeleton'),
                      title: 'CAMERA INFO',
                      lines: 3,
                    ),
                  ] else if (showDeferredError) ...[
                    const SizedBox(height: 18),
                    const _DeferredSectionPlaceholder(
                      title: 'CAMERA INFO',
                      message:
                          'Camera details unavailable until hydration succeeds.',
                    ),
                  ],
                  if (photo.color.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const _SectionDivider(),
                    const SizedBox(height: 18),
                    ColorPaletteSection(hexColor: photo.color),
                  ],
                  const SizedBox(height: 18),
                  _DownloadButton(
                    onTap: () async {
                      await DownloadSheet.show(context, photo);
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: _MoreFromPhotographer(photo: photo)),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  String? get _description => photo.description ?? photo.altDescription;

  List<_ExifItem> get _exifItems {
    final exif = photo.exif;
    if (exif == null) return const [];

    final items = <_ExifItem>[];
    final camera = _join(exif.make, exif.model);
    if (camera != null) {
      items.add(_ExifItem('Camera', camera));
    }
    if (exif.aperture != null) {
      items.add(_ExifItem('Aperture', exif.aperture!));
    }
    if (exif.exposureTime != null) {
      items.add(_ExifItem('Shutter', exif.exposureTime!));
    }
    if (exif.iso != null) {
      items.add(_ExifItem('ISO', exif.iso.toString()));
    }
    if (exif.focalLength != null) {
      items.add(_ExifItem('Focal', exif.focalLength!));
    }
    if (photo.location != null &&
        (photo.location!.city?.isNotEmpty == true ||
            photo.location!.country?.isNotEmpty == true)) {
      items.add(_ExifItem('Location', photo.location!.displayName));
    }
    if (photo.width > 0 && photo.height > 0) {
      items.add(_ExifItem('Size', '${photo.width}×${photo.height}'));
    }
    return items;
  }

  String? _join(String? a, String? b) {
    if (a == null && b == null) return null;
    return [a, b].where((x) => x != null && x.isNotEmpty).join(' ');
  }
}

class _PhotoHero extends StatefulWidget {
  const _PhotoHero({
    required this.photo,
    this.onTap,
  });

  final Photo photo;
  final VoidCallback? onTap;

  @override
  State<_PhotoHero> createState() => _PhotoHeroState();
}

class _PhotoHeroState extends State<_PhotoHero> {
  final GlobalKey _frameKey = GlobalKey();
  double? _lockedHeight;

  @override
  void initState() {
    super.initState();
    _scheduleHeightLock();
  }

  @override
  void didUpdateWidget(covariant _PhotoHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_lockedHeight == null) {
      _scheduleHeightLock();
    }
  }

  void _scheduleHeightLock() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _lockedHeight != null) return;
      final context = _frameKey.currentContext;
      final renderBox = context?.findRenderObject() as RenderBox?;
      final height = renderBox?.size.height;
      if (height != null && height > 0) {
        setState(() {
          _lockedHeight = height;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final heroImage = Hero(
      tag: widget.photo.id,
      child: GestureDetector(
        key: const ValueKey('photo-detail-hero-tap-target'),
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: CachedNetworkImage(
          imageUrl: widget.photo.urlRegular,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: 320,
            color: Color(
              int.parse(widget.photo.color.replaceFirst('#', '0xFF')),
            ),
            child: const Center(child: LoadingIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            height: 320,
            color: AppColors.gray200,
            child: const Icon(Icons.broken_image, size: 48),
          ),
        ),
      ),
    );

    return Stack(
      key: _frameKey,
      children: [
        if (_lockedHeight != null)
          SizedBox(
            key: const ValueKey('photo-detail-hero-frame'),
            height: _lockedHeight,
            width: double.infinity,
            child: heroImage,
          )
        else
          heroImage,
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.34),
                    Colors.black.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.72, 1.0],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 42),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _HeroActionButton(
                  icon: Icons.arrow_back_ios_new,
                  onTap: () => Navigator.maybePop(context),
                ),
                const Row(
                  children: [
                    _HeroActionButton(icon: Icons.bookmark_border),
                    SizedBox(width: 8),
                    _HeroActionButton(icon: Icons.ios_share),
                    SizedBox(width: 8),
                    _HeroActionButton(icon: Icons.more_horiz),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  const _HeroActionButton({
    required this.icon,
    this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.photo});

  final Photo photo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.push('/profile/${photo.user.username}'),
          child: CircleAvatar(
            radius: 17,
            backgroundImage:
                CachedNetworkImageProvider(photo.user.profileImageMedium),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                photo.user.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF18181B),
                ),
              ),
              Text(
                '@${photo.user.username}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFA1A1AA),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Center(
            child: Text(
              'Follow',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({
    required this.photo,
    required this.likeState,
    this.onLikeTap,
  });

  static const Color _likedColor = Color(0xFFE11D48);

  final Photo photo;
  final PhotoLikeState likeState;
  final VoidCallback? onLikeTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFF1F1F1)),
          bottom: BorderSide(color: Color(0xFFF1F1F1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              key: const ValueKey('photo-detail-like-button'),
              icon: likeState.likedByUser
                  ? Icons.favorite
                  : Icons.favorite_border,
              label: _formatCount(likeState.likes),
              iconColor:
                  likeState.likedByUser ? _likedColor : const Color(0xFF71717A),
              labelColor: const Color(0xFF52525B),
              onTap: onLikeTap,
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: _StatItem(
              icon: Icons.remove_red_eye_outlined,
              label: _formatCount(photo.views ?? 0),
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: _StatItem(
              icon: Icons.download_outlined,
              label: _formatCount(photo.downloads),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    super.key,
    required this.icon,
    required this.label,
    this.iconColor = const Color(0xFF71717A),
    this.labelColor = const Color(0xFF52525B),
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final Color labelColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: iconColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 42,
      child: VerticalDivider(width: 1, thickness: 1, color: Color(0xFFF1F1F1)),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF555555),
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F5));
  }
}

class _DeferredRetryBanner extends StatelessWidget {
  const _DeferredRetryBanner({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Some detail sections could not be loaded yet.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF475569),
              ),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry loading details'),
          ),
        ],
      ),
    );
  }
}

class _DeferredSectionSkeleton extends StatelessWidget {
  const _DeferredSectionSkeleton({
    super.key,
    required this.title,
    required this.lines,
  });

  final String title;
  final int lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionDivider(),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF71717A),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        for (var index = 0; index < lines; index++) ...[
          Container(
            height: 12,
            width: index.isEven ? 160 : 120,
            decoration: BoxDecoration(
              color: const Color(0xFFE4E4E7),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          if (index != lines - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _DeferredSectionPlaceholder extends StatelessWidget {
  const _DeferredSectionPlaceholder({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionDivider(),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF71717A),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF71717A),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _ExifGrid extends StatelessWidget {
  const _ExifGrid({required this.items});

  final List<_ExifItem> items;

  @override
  Widget build(BuildContext context) {
    final rows = <List<_ExifItem>>[];
    for (var index = 0; index < items.length; index += 2) {
      rows.add(items.skip(index).take(2).toList());
    }

    return Column(
      children: [
        for (final row in rows)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _ExifCell(item: row.first)),
              const SizedBox(width: 18),
              Expanded(
                child: row.length > 1
                    ? _ExifCell(item: row[1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
      ],
    );
  }
}

class _ExifCell extends StatelessWidget {
  const _ExifCell({required this.item});

  final _ExifItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF4F4F5))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 50,
            child: Text(
              item.label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFFA1A1AA),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _ExifValueText(
              label: item.label,
              value: item.value,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExifValueText extends StatelessWidget {
  const _ExifValueText({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Color(0xFF27272A),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(
            text: value,
            style: style,
          ),
          maxLines: 1,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);

        final isOverflowing = painter.didExceedMaxLines;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: isOverflowing
              ? (details) => _showValuePopup(
                    context,
                    details.globalPosition,
                  )
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: style,
            ),
          ),
        );
      },
    );
  }

  Future<void> _showValuePopup(
    BuildContext context,
    Offset globalPosition,
  ) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    return showMenu<void>(
      context: context,
      elevation: 8,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      position: RelativeRect.fromLTRB(
        globalPosition.dx - 160,
        globalPosition.dy - 8,
        overlay.size.width - globalPosition.dx,
        overlay.size.height - globalPosition.dy,
      ),
      items: [
        PopupMenuItem<void>(
          enabled: false,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF71717A),
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF27272A),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ExifItem {
  const _ExifItem(this.label, this.value);

  final String label;
  final String value;
}

class _DownloadButton extends StatelessWidget {
  const _DownloadButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.download_outlined, size: 20, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Download Free',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreFromPhotographer extends ConsumerWidget {
  const _MoreFromPhotographer({required this.photo});

  final Photo photo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(userPhotosProvider(photo.user.username));

    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'More from photographer',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF18181B),
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/profile/${photo.user.username}'),
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFA1A1AA),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          photosAsync.when(
            data: (photos) {
              final displayPhotos =
                  photos.where((item) => item.id != photo.id).take(10).toList();
              if (displayPhotos.isEmpty) return const SizedBox.shrink();

              return SizedBox(
                height: 84,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: displayPhotos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final item = displayPhotos[index];
                    return GestureDetector(
                      onTap: () => context.push(
                        '/photo/${item.id}',
                        extra: PhotoDetailExtra(photo: item),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: item.urlSmall,
                          width: 84,
                          height: 84,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            width: 84,
                            height: 84,
                            color: AppColors.gray200,
                            child: const Icon(Icons.broken_image, size: 24),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox(
              height: 84,
              child: Center(child: LoadingIndicator()),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
