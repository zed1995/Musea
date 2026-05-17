import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/core/theme/text_styles.dart';
import 'package:musea/features/collections/presentation/providers/collections_provider.dart';
import 'package:musea/shared/widgets/photo_feed.dart';
import 'package:musea/shared/widgets/loading_indicator.dart';
import 'package:musea/shared/widgets/error_state.dart';

class CollectionDetailPage extends ConsumerWidget {
  const CollectionDetailPage({super.key, required this.collectionId});

  final String collectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionAsync = ref.watch(collectionDetailProvider(collectionId));
    final photosAsync = ref.watch(collectionPhotosProvider(collectionId));

    return collectionAsync.when(
      data: (collection) => Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: collection.coverPhoto != null
                    ? CachedNetworkImage(
                        imageUrl: collection.coverPhoto!.urlRegular,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.gray200,
                        ),
                      )
                    : Container(color: AppColors.gray200),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(collection.title, style: AppTextStyles.heading2),
                    if (collection.description != null && collection.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          collection.description!,
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray600),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${collection.totalPhotos} photos',
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            photosAsync.when(
              data: (photos) => PhotoFeed(
                photos: photos,
                onPhotoTap: (photo) => context.push('/photo/${photo.id}'),
                onUserTap: (photo) => context.push('/profile/${photo.user.username}'),
                showDownloadButton: false,
              ),
              loading: () => const SliverFillRemaining(
                child: Center(child: LoadingIndicator()),
              ),
              error: (error, stack) => SliverFillRemaining(
                child: ErrorState(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(collectionPhotosProvider(collectionId)),
                ),
              ),
            ),
          ],
        ),
      ),
      loading: () => const Scaffold(body: Center(child: LoadingIndicator())),
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
