import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/core/theme/text_styles.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/collections/presentation/providers/collections_provider.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/shared/widgets/error_state.dart';
import 'package:musea/shared/widgets/loading_indicator.dart';

class CollectionDetailPage extends ConsumerWidget {
  const CollectionDetailPage({super.key, required this.collectionId});

  final String collectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionAsync = ref.watch(collectionDetailProvider(collectionId));
    final photosAsync = ref.watch(collectionPhotosProvider(collectionId));

    return collectionAsync.when(
      data: (collection) => _CollectionDetailContent(
        collection: collection,
        photosAsync: photosAsync,
      ),
      loading: () => const Scaffold(
        body: Center(child: LoadingIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(),
        body: ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(collectionDetailProvider(collectionId)),
        ),
      ),
    );
  }
}

class _CollectionDetailContent extends StatelessWidget {
  const _CollectionDetailContent({
    required this.collection,
    required this.photosAsync,
  });

  final Collection collection;
  final AsyncValue<List<Photo>> photosAsync;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _CollectionHero(
              collection: collection,
              coverUrl: _coverUrl(collection),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionEyebrow('Collection Summary'),
                        const SizedBox(height: 8),
                        Text(
                          _summaryText(collection),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.gray600,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _buildMetaPills(collection),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _DetailSectionHeader(
                          eyebrow: 'Preview',
                          title: 'First four photos',
                          actionLabel: 'Open grid',
                        ),
                        const SizedBox(height: 12),
                        _PreviewGrid(
                          previewUrls: _previewUrls(
                            collection.previewPhotos,
                            photosAsync,
                          ),
                          remainingCount:
                              (collection.totalPhotos - 4).clamp(0, 999999),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionEyebrow('Collection Facts'),
                        const SizedBox(height: 10),
                        ..._buildFactRows(collection),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _FeedSection(
                    photosAsync: photosAsync,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionHero extends StatelessWidget {
  const _CollectionHero({
    required this.collection,
    required this.coverUrl,
  });

  final Collection collection;
  final String? coverUrl;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final curator = collection.user;
    final curatorUsername = curator?.username;
    final canOpenProfile =
        curatorUsername != null && curatorUsername.isNotEmpty;

    return SizedBox(
      height: 328 + topPadding,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (coverUrl != null && coverUrl!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: coverUrl!,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Container(
                color: AppColors.gray300,
              ),
            )
          else
            Container(color: AppColors.gray300),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.12),
                  Colors.black.withValues(alpha: 0.28),
                  Colors.black.withValues(alpha: 0.68),
                ],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _GlassActionButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onPressed: () => context.pop(),
                      ),
                      Row(
                        children: [
                          _GlassActionButton(
                            icon: Icons.bookmark_border_rounded,
                            onPressed: () {},
                          ),
                          const SizedBox(width: 8),
                          _GlassActionButton(
                            icon: Icons.ios_share_rounded,
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _GlassChip(label: '${collection.totalPhotos} photos'),
                        const SizedBox(width: 8),
                        const _GlassChip(label: 'Photo collection'),
                        const SizedBox(width: 8),
                        _GlassChip(
                          label: _collectionIsPrivate(collection)
                              ? 'Private'
                              : 'Public',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    collection.title,
                    style: AppTextStyles.heading1.copyWith(
                      color: Colors.white,
                      fontSize: 28,
                      height: 1.02,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.1,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: canOpenProfile
                              ? () => context.push('/profile/$curatorUsername')
                              : null,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                _CuratorAvatar(user: curator, size: 40),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        curator?.name ?? 'Unknown curator',
                                        style:
                                            AppTextStyles.bodyMedium.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _curatorMeta(curator),
                                        style: AppTextStyles.caption.copyWith(
                                          color: Colors.white.withValues(
                                            alpha: 0.96,
                                          ),
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 36,
                        child: FilledButton(
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.gray900,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text(
                            'Follow',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.gray900,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedSection extends StatelessWidget {
  const _FeedSection({required this.photosAsync});

  final AsyncValue<List<Photo>> photosAsync;

  @override
  Widget build(BuildContext context) {
    return photosAsync.when(
      data: (photos) {
        if (photos.isEmpty) {
          return const _SectionCard(
            child: _EmptyFeedCard(message: 'No photos in this collection yet'),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'Photo feed',
                style: AppTextStyles.heading3,
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: photos.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.8,
              ),
              itemBuilder: (context, index) {
                final photo = photos[index];
                return GestureDetector(
                  onTap: () => context.push('/photo/${photo.id}'),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: photo.urlSmall,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.gray100,
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.18),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 10,
                          right: 10,
                          bottom: 10,
                          child: Row(
                            children: [
                              _CuratorAvatar(user: photo.user, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  photo.user.name,
                                  style: AppTextStyles.caption.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
      loading: () => const SectionLoadingCard(),
      error: (error, stack) => SectionErrorCard(message: error.toString()),
    );
  }
}

class _PreviewGrid extends StatelessWidget {
  const _PreviewGrid({
    required this.previewUrls,
    required this.remainingCount,
  });

  final List<String> previewUrls;
  final int remainingCount;

  @override
  Widget build(BuildContext context) {
    if (previewUrls.isEmpty) {
      return const _EmptyFeedCard(
        message: 'Preview will appear when photos are added',
      );
    }

    final displayed = previewUrls.take(5).toList();

    return SizedBox(
      height: 150,
      child: Row(
        children: [
          Expanded(
            flex: 13,
            child: _PreviewImageTile(url: displayed.first),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 10,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _PreviewTile(url: displayed.elementAtOrNull(1)),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _PreviewTile(url: displayed.elementAtOrNull(2)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _PreviewTile(url: displayed.elementAtOrNull(3)),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: remainingCount > 0
                            ? _PreviewMoreTile(remainingCount: remainingCount)
                            : _PreviewTile(
                                url: displayed.elementAtOrNull(4),
                                showPlaceholderWhenEmpty: true,
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewImageTile extends StatelessWidget {
  const _PreviewImageTile({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox.expand(
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => Container(
            color: AppColors.gray100,
          ),
        ),
      ),
    );
  }
}

class _PreviewTile extends StatelessWidget {
  const _PreviewTile({
    required this.url,
    this.showPlaceholderWhenEmpty = false,
  });

  final String? url;
  final bool showPlaceholderWhenEmpty;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return _PreviewPlaceholderTile(visible: showPlaceholderWhenEmpty);
    }

    return _PreviewImageTile(url: url!);
  }
}

class _PreviewMoreTile extends StatelessWidget {
  const _PreviewMoreTile({required this.remainingCount});

  final int remainingCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF27272A),
            Color(0xFF18181B),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '+$remainingCount',
            style: AppTextStyles.heading3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Jump to feed',
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PreviewPlaceholderTile extends StatelessWidget {
  const _PreviewPlaceholderTile({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: visible ? 1 : 0,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _DetailSectionHeader extends StatelessWidget {
  const _DetailSectionHeader({
    required this.eyebrow,
    required this.title,
    required this.actionLabel,
  });

  final String eyebrow;
  final String title;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionEyebrow(eyebrow),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Text(
          actionLabel,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.gray500,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF4F4F5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A18181B),
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _GlassActionButton extends StatelessWidget {
  const _GlassActionButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Icon(
          icon,
          size: 18,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CuratorAvatar extends StatelessWidget {
  const _CuratorAvatar({
    required this.user,
    required this.size,
  });

  final User? user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final imageUrl = user == null ? '' : _bestProfileImage(user!);

    if (imageUrl.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.24),
        ),
      );
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) => Container(
          width: size,
          height: size,
          color: AppColors.gray200,
        ),
      ),
    );
  }
}

class SectionLoadingCard extends StatelessWidget {
  const SectionLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SectionCard(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: LoadingIndicator()),
      ),
    );
  }
}

class SectionErrorCard extends StatelessWidget {
  const SectionErrorCard({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: ErrorState(
        message: message,
        onRetry: () {},
      ),
    );
  }
}

class _EmptyFeedCard extends StatelessWidget {
  const _EmptyFeedCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.gray600,
        ),
      ),
    );
  }
}

Text _sectionEyebrow(String text) {
  return Text(
    text,
    style: AppTextStyles.caption.copyWith(
      color: AppColors.gray400,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.3,
    ),
  );
}

List<Widget> _buildFactRows(Collection collection) {
  final rows = <MapEntry<String, String>>[
    if (collection.publishedAt != null)
      MapEntry('Published', _formatDate(collection.publishedAt!)),
    if (collection.updatedAt != null)
      MapEntry('Updated', _formatDate(collection.updatedAt!)),
    if (collection.lastCollectedAt != null)
      MapEntry('Last collected', _formatDate(collection.lastCollectedAt!)),
    MapEntry(
      'Visibility',
      _collectionIsPrivate(collection) ? 'Private' : 'Public',
    ),
    MapEntry('Photos', '${collection.totalPhotos}'),
  ];

  return rows
      .map(
        (row) => Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xFFF4F4F5)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  row.key,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.gray500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                row.value,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      )
      .toList();
}

List<Widget> _buildMetaPills(Collection collection) {
  final pills = <Widget>[];

  if (collection.publishedAt != null) {
    if (pills.isNotEmpty) pills.add(const SizedBox(width: 8));
    pills.add(
      _MetaPill(label: 'Published ${_formatDate(collection.publishedAt!)}'),
    );
  }
  if (collection.updatedAt != null) {
    if (pills.isNotEmpty) pills.add(const SizedBox(width: 8));
    pills.add(
      _MetaPill(label: 'Updated ${_formatDate(collection.updatedAt!)}'),
    );
  }
  if (collection.lastCollectedAt != null) {
    if (pills.isNotEmpty) pills.add(const SizedBox(width: 8));
    pills.add(
      _MetaPill(
        label: 'Last collected ${_formatDate(collection.lastCollectedAt!)}',
      ),
    );
  }
  if (pills.isEmpty) {
    pills.add(
      _MetaPill(
        label: _collectionIsPrivate(collection)
            ? 'Private collection'
            : 'Public collection',
      ),
    );
  }

  return pills;
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.gray700,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

List<String> _previewUrls(
  List<PreviewPhoto> previews,
  AsyncValue<List<Photo>> photosAsync,
) {
  if (previews.isNotEmpty) {
    return previews
        .map((photo) => photo.smallUrl)
        .where((url) => url.isNotEmpty)
        .toList();
  }

  return photosAsync.maybeWhen(
    data: (photos) => photos
        .take(4)
        .map((photo) => photo.urlSmall)
        .where((url) => url.isNotEmpty)
        .toList(),
    orElse: () => const [],
  );
}

String _summaryText(Collection collection) {
  final description = collection.description?.trim();
  if (description != null && description.isNotEmpty) {
    return description;
  }
  return 'No curator description has been added for this collection yet. The layout stays intact and shifts emphasis to the curator and photo stream.';
}

String? _coverUrl(Collection collection) {
  final cover = collection.coverPhoto?.urlRegular;
  if (cover != null && cover.isNotEmpty) return cover;
  if (collection.previewPhotos.isNotEmpty) {
    return collection.previewPhotos.first.regularUrl;
  }
  return null;
}

String _curatorMeta(User? user) {
  if (user == null) {
    return '@unknown';
  }

  final parts = <String>['@${user.username}'];
  if (user.totalCollections > 0) {
    parts.add('${user.totalCollections} collections');
  }
  return parts.join(' · ');
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String _bestProfileImage(User user) {
  if (user.profileImageLarge.isNotEmpty) return user.profileImageLarge;
  if (user.profileImageMedium.isNotEmpty) return user.profileImageMedium;
  return user.profileImageSmall;
}

bool _collectionIsPrivate(Collection collection) {
  final dynamic value = (collection as dynamic).isPrivate;
  return value == true;
}
