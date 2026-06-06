import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/core/theme/text_styles.dart';
import 'package:musea/features/auth/presentation/providers/auth_provider.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/collections/presentation/pages/collection_remove_photos_page.dart';
import 'package:musea/features/collections/presentation/providers/collections_provider.dart';
import 'package:musea/features/collections/presentation/widgets/collection_delete_sheet.dart';
import 'package:musea/features/collections/presentation/widgets/collection_edit_sheet.dart';
import 'package:musea/features/collections/presentation/widgets/collection_manage_sheet.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/router/detail_route_extras.dart';
import 'package:musea/shared/widgets/error_state.dart';
import 'package:musea/shared/widgets/loading_indicator.dart';
import 'package:musea/l10n/generated/app_localizations.dart';
import 'package:musea/shared/widgets/photo_grid.dart';

class CollectionDetailPage extends ConsumerWidget {
  const CollectionDetailPage({
    super.key,
    required this.collectionId,
    this.initialCollection,
  });

  final String collectionId;
  final Collection? initialCollection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionAsync = ref.watch(collectionDetailProvider(collectionId));
    final photosAsync = ref.watch(collectionPhotosProvider(collectionId));
    final hydratedCollection = collectionAsync.valueOrNull;
    final resolvedCollection = hydratedCollection ?? initialCollection;
    final isUsingInitialCollection =
        initialCollection != null && hydratedCollection == null;
    final authState = ref.watch(currentAuthStateProvider);
    final isOwner = authState?.isAuthenticated == true &&
        authState?.session?.user.id == resolvedCollection?.user?.id;
    final showDeferredPreview =
        isUsingInitialCollection && _hasDeferredPreviewGap(initialCollection!);
    final showDeferredFacts =
        isUsingInitialCollection && _hasDeferredFactGaps(initialCollection!);

    debugPrint(
      '[CollectionDetailPage] build id=$collectionId '
      'hasInitial=${initialCollection != null} '
      'detailLoading=${collectionAsync.isLoading} '
      'detailHasError=${collectionAsync.hasError} '
      'photosLoading=${photosAsync.isLoading} '
      'photosHasError=${photosAsync.hasError} '
      'photosCount=${photosAsync.valueOrNull?.length}',
    );

    if (resolvedCollection != null) {
      return _CollectionDetailContent(
        collection: resolvedCollection,
        photosAsync: photosAsync,
        isOwner: isOwner,
        allowPhotoFeedPreviewFallback: !isUsingInitialCollection,
        onRetryFeed: () =>
            ref.invalidate(collectionPhotosProvider(collectionId)),
        showDeferredPreviewSkeleton:
            collectionAsync.isLoading && showDeferredPreview,
        showDeferredPreviewRetry:
            collectionAsync.hasError && showDeferredPreview,
        showDeferredFactSkeleton:
            collectionAsync.isLoading && showDeferredFacts,
        showDeferredFactRetry: collectionAsync.hasError && showDeferredFacts,
        onRetryDeferred: () =>
            ref.invalidate(collectionDetailProvider(collectionId)),
      );
    }

    return collectionAsync.when(
      data: (collection) {
        final dataIsOwner = authState?.isAuthenticated == true &&
            authState?.session?.user.id == collection.user?.id;
        return _CollectionDetailContent(
          collection: collection,
          photosAsync: photosAsync,
          isOwner: dataIsOwner,
          onRetryFeed: () =>
              ref.invalidate(collectionPhotosProvider(collectionId)),
        );
      },
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

  bool _hasDeferredFactGaps(Collection collection) {
    return collection.publishedAt == null ||
        collection.updatedAt == null ||
        collection.lastCollectedAt == null;
  }

  bool _hasDeferredPreviewGap(Collection collection) {
    return collection.previewPhotos.isEmpty;
  }
}

class _CollectionDetailContent extends StatelessWidget {
  const _CollectionDetailContent({
    required this.collection,
    required this.photosAsync,
    this.isOwner = false,
    this.allowPhotoFeedPreviewFallback = true,
    required this.onRetryFeed,
    this.showDeferredPreviewSkeleton = false,
    this.showDeferredPreviewRetry = false,
    this.showDeferredFactSkeleton = false,
    this.showDeferredFactRetry = false,
    this.onRetryDeferred,
  });

  final Collection collection;
  final AsyncValue<List<Photo>> photosAsync;
  final bool isOwner;
  final bool allowPhotoFeedPreviewFallback;
  final VoidCallback onRetryFeed;
  final bool showDeferredPreviewSkeleton;
  final bool showDeferredPreviewRetry;
  final bool showDeferredFactSkeleton;
  final bool showDeferredFactRetry;
  final VoidCallback? onRetryDeferred;

  void _showManageSheet(BuildContext context) {
    final photosList = photosAsync.valueOrNull ?? [];
    showCollectionManageSheet(
      context,
      collection: collection,
      onEdit: () =>
          showCollectionEditSheet(context, collection: collection),
      onRemovePhotos: () => context.push(
        '/collection/${collection.id}/remove',
        extra: collection.title,
      ),
      onDelete: () =>
          showCollectionDeleteSheet(context, collection: collection),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final factRows = _buildFactRows(collection, l10n, locale);
    final previewUrls = _previewUrls(
      collection.previewPhotos,
      photosAsync,
      allowPhotosFallback: allowPhotoFeedPreviewFallback,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _CollectionHero(
              collection: collection,
              coverUrl: _coverUrl(collection),
              isOwner: isOwner,
              onManageTap: () => _showManageSheet(context),
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
                        _sectionEyebrow(l10n.collectionSummary),
                        const SizedBox(height: 8),
                        Text(
                          _summaryText(collection, l10n),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.gray600,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _buildMetaPills(collection, l10n, locale),
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
                        _DetailSectionHeader(
                          eyebrow: l10n.preview,
                          title: l10n.firstFourPhotos,
                          actionLabel: l10n.openGrid,
                        ),
                        const SizedBox(height: 12),
                        if (previewUrls.isNotEmpty)
                          _PreviewGrid(
                            previewUrls: previewUrls,
                            remainingCount:
                                (collection.totalPhotos - 4).clamp(0, 999999),
                          )
                        else if (showDeferredPreviewSkeleton)
                          const _PreviewSectionSkeleton(
                            key: ValueKey('collection-detail-preview-skeleton'),
                          )
                        else if (showDeferredPreviewRetry)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _DeferredRetryBanner(onRetry: onRetryDeferred),
                              const SizedBox(height: 12),
                              _DeferredSectionPlaceholder(
                                 message: l10n.previewUnavailable,
                               ),
                            ],
                          )
                        else
                          _EmptyFeedCard(
                             message: l10n.previewWillAppear,
                           ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionEyebrow(l10n.collectionFacts),
                        const SizedBox(height: 10),
                        ...factRows,
                        if (showDeferredFactSkeleton) ...[
                          const SizedBox(height: 8),
                          const _DeferredSectionSkeleton(
                            key: ValueKey('collection-detail-facts-skeleton'),
                            lines: 2,
                          ),
                        ] else if (showDeferredFactRetry) ...[
                          const SizedBox(height: 8),
                          _DeferredRetryBanner(onRetry: onRetryDeferred),
                          const SizedBox(height: 12),
                          _DeferredSectionPlaceholder(
                             message: l10n.factsWillAppear,
                           ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    child: _ContinueExploringSection(collection: collection),
                  ),
                  const SizedBox(height: 12),
                  _FeedSection(
                    photosAsync: photosAsync,
                    onRetry: onRetryFeed,
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
    this.isOwner = false,
    this.onManageTap,
  });

  final Collection collection;
  final String? coverUrl;
  final bool isOwner;
  final VoidCallback? onManageTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                        onPressed: () => Navigator.maybePop(context),
                      ),
                      Row(
                        children: [
                          if (isOwner) ...[
                            _GlassActionButton(
                              icon: Icons.grid_view_rounded,
                              onPressed: onManageTap ?? () {},
                            ),
                            const SizedBox(width: 8),
                          ],
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
                        _GlassChip(label: l10n.photoCount(collection.totalPhotos)),
                        const SizedBox(width: 8),
                        _GlassChip(label: l10n.photoCollection),
                        const SizedBox(width: 8),
                        _GlassChip(
                          label: _collectionIsPrivate(collection)
                              ? l10n.private
                              : l10n.public,
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
                              ? () => context.push(
                                    '/profile/$curatorUsername',
                                    extra: ProfileDetailExtra(user: collection.user!),
                                  )
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
                                        curator?.name ?? l10n.unknownCurator,
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
                                        _curatorMeta(curator, l10n),
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
                            l10n.follow,
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
  const _FeedSection({
    required this.photosAsync,
    required this.onRetry,
  });

  final AsyncValue<List<Photo>> photosAsync;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return photosAsync.when(
      data: (photos) {
        debugPrint(
          '[CollectionDetailPage] feed data count=${photos.length}',
        );
        if (photos.isEmpty) {
          debugPrint(
            '[CollectionDetailPage] feed empty state rendered',
          );
          return _SectionCard(
            child: _EmptyFeedCard(message: l10n.noPhotosInCollection),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionEyebrow(l10n.segmentPhotos),
                  const SizedBox(height: 4),
                  Text(
                    l10n.insideTheCollection,
                    style: AppTextStyles.heading3,
                  ),
                ],
              ),
            ),
            PhotoGrid(
              photos: photos,
              showLikes: true,
            ),
          ],
        );
      },
      loading: () {
        debugPrint('[CollectionDetailPage] feed loading state rendered');
        return const SectionLoadingCard();
      },
      error: (error, stack) {
        debugPrint(
          '[CollectionDetailPage] feed error state rendered error=$error',
        );
        return SectionErrorCard(
          key: const ValueKey('collection-detail-feed-error'),
          message: error.toString(),
          onRetry: onRetry,
        );
      },
    );
  }
}

class _ContinueExploringSection extends StatelessWidget {
  const _ContinueExploringSection({required this.collection});

  final Collection collection;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themes = _buildExploreThemes(collection, l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailSectionHeader(
          eyebrow: l10n.continueExploring,
          title: l10n.exploreNearbyThemes,
          actionLabel: l10n.seeAll,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: themes.map((theme) => _MetaPill(label: theme)).toList(),
        ),
      ],
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
    final l10n = AppLocalizations.of(context)!;
    if (previewUrls.isEmpty) {
      return _EmptyFeedCard(
        message: l10n.previewWillAppear,
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
    final l10n = AppLocalizations.of(context)!;
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
            l10n.jumpToFeed,
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
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: ErrorState(
        message: message,
        onRetry: onRetry,
      ),
    );
  }
}

class _DeferredRetryBanner extends StatelessWidget {
  const _DeferredRetryBanner({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.collectionDetailsUnavailable,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF475569),
              ),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: onRetry,
            child: Text(l10n.retryLoadingDetails),
          ),
        ],
      ),
    );
  }
}

class _DeferredSectionSkeleton extends StatelessWidget {
  const _DeferredSectionSkeleton({
    super.key,
    required this.lines,
  });

  final int lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        lines,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index == lines - 1 ? 0 : 10),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 84,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeferredSectionPlaceholder extends StatelessWidget {
  const _DeferredSectionPlaceholder({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        message,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.gray600,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PreviewSectionSkeleton extends StatelessWidget {
  const _PreviewSectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    Widget box({double? width, double? height}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(12),
        ),
      );
    }

    return SizedBox(
      height: 150,
      child: Row(
        children: [
          Expanded(flex: 13, child: box(height: double.infinity)),
          const SizedBox(width: 6),
          Expanded(
            flex: 10,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: box(height: double.infinity)),
                      const SizedBox(width: 6),
                      Expanded(child: box(height: double.infinity)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: box(height: double.infinity)),
                      const SizedBox(width: 6),
                      Expanded(child: box(height: double.infinity)),
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

List<Widget> _buildFactRows(Collection collection, AppLocalizations l10n, String locale) {
  final rows = <MapEntry<String, String>>[
    if (collection.publishedAt != null)
      MapEntry(l10n.published, _formatDate(collection.publishedAt!, locale)),
    if (collection.updatedAt != null)
      MapEntry(l10n.updated, _formatDate(collection.updatedAt!, locale)),
    if (collection.lastCollectedAt != null)
      MapEntry(l10n.lastCollected, _formatDate(collection.lastCollectedAt!, locale)),
    MapEntry(
      l10n.visibility,
      _collectionIsPrivate(collection) ? l10n.private : l10n.public,
    ),
    MapEntry(l10n.segmentPhotos, '${collection.totalPhotos}'),
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

List<Widget> _buildMetaPills(Collection collection, AppLocalizations l10n, String locale) {
  final pills = <Widget>[];

  if (collection.publishedAt != null) {
    if (pills.isNotEmpty) pills.add(const SizedBox(width: 8));
    pills.add(
      _MetaPill(label: l10n.publishedDate(_formatDate(collection.publishedAt!, locale))),
    );
  }
  if (collection.updatedAt != null) {
    if (pills.isNotEmpty) pills.add(const SizedBox(width: 8));
    pills.add(
      _MetaPill(label: l10n.updatedDate(_formatDate(collection.updatedAt!, locale))),
    );
  }
  if (collection.lastCollectedAt != null) {
    if (pills.isNotEmpty) pills.add(const SizedBox(width: 8));
    pills.add(
      _MetaPill(
        label: l10n.lastCollectedDate(_formatDate(collection.lastCollectedAt!, locale)),
      ),
    );
  }
  if (pills.isEmpty) {
    pills.add(
      _MetaPill(
        label: _collectionIsPrivate(collection)
            ? l10n.privateCollection
            : l10n.publicCollection,
      ),
    );
  }

  return pills;
}

List<String> _buildExploreThemes(Collection collection, AppLocalizations l10n) {
  final rawThemes = <String>[
    ...collection.title
        .split(RegExp(r'[\s,/&-]+'))
        .where((part) => part.trim().length >= 4),
    ...?collection.description
        ?.split(RegExp(r'[\s,/&-]+'))
        .where((part) => part.trim().length >= 5),
    ...collection.mediaTypes,
    if ((collection.user?.totalCollections ?? 0) > 0) l10n.curatedSets,
  ];

  final deduped = <String>[];
  for (final rawTheme in rawThemes) {
    final theme = _capitalizeWords(rawTheme.trim());
    if (theme.isEmpty) continue;
    if (deduped.any((item) => item.toLowerCase() == theme.toLowerCase())) {
      continue;
    }
    deduped.add(theme);
    if (deduped.length == 5) break;
  }

  if (deduped.isNotEmpty) {
    return deduped;
  }

  return [
    l10n.exploreThemeRoadTrips,
    l10n.exploreThemeNationalParks,
    l10n.exploreThemeLandscape,
    l10n.exploreThemeOpenSky,
    l10n.exploreThemeTravelNotes,
  ];
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
  AsyncValue<List<Photo>> photosAsync, {
  bool allowPhotosFallback = true,
}) {
  if (previews.isNotEmpty) {
    return previews
        .map((photo) => photo.smallUrl)
        .where((url) => url.isNotEmpty)
        .toList();
  }

  if (!allowPhotosFallback) {
    return const [];
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

String _summaryText(Collection collection, AppLocalizations l10n) {
  final description = collection.description?.trim();
  if (description != null && description.isNotEmpty) {
    return description;
  }
  return l10n.noDescriptionFallback;
}

String _capitalizeWords(String value) {
  if (value.isEmpty) return value;

  return value
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map(
        (part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
}

String? _coverUrl(Collection collection) {
  final cover = collection.coverPhoto?.urlRegular;
  if (cover != null && cover.isNotEmpty) return cover;
  if (collection.previewPhotos.isNotEmpty) {
    return collection.previewPhotos.first.regularUrl;
  }
  return null;
}

String _curatorMeta(User? user, AppLocalizations l10n) {
  if (user == null) {
    return l10n.unknownUser;
  }

  final parts = <String>['@${user.username}'];
  if (user.totalCollections > 0) {
    parts.add(l10n.collectionsCount(user.totalCollections));
  }
  return parts.join(' · ');
}

String _formatDate(DateTime date, String locale) {
  return DateFormat.yMMMd(locale).format(date);
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
