import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/core/theme/text_styles.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/collections/presentation/providers/collections_provider.dart';
import 'package:musea/shared/widgets/loading_indicator.dart';
import 'package:musea/shared/widgets/error_state.dart';
import 'package:musea/shared/widgets/empty_state.dart';

class CollectionsPage extends ConsumerWidget {
  const CollectionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionsAsync = ref.watch(collectionsProvider(1));

    return Scaffold(
      appBar: AppBar(title: const Text('Collections')),
      body: collectionsAsync.when(
        data: (collections) {
          if (collections.isEmpty) {
            return const EmptyState(
              icon: Icons.collections_bookmark_outlined,
              title: 'No collections',
              subtitle: 'Check back later for curated collections',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(collectionsProvider),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: collections.length,
                itemBuilder: (context, index) {
                  return _CollectionCard(collection: collections[index]);
                },
              ),
            ),
          );
        },
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, stack) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(collectionsProvider),
        ),
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({required this.collection});

  final Collection collection;

  @override
  Widget build(BuildContext context) {
    final previewUrl = collection.coverPhoto?.urlSmall
        ?? (collection.previewPhotos.isNotEmpty ? collection.previewPhotos.first.smallUrl : null);

    return GestureDetector(
      onTap: () => context.push('/collection/${collection.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: AppColors.gray100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: previewUrl != null
                    ? CachedNetworkImage(
                        imageUrl: previewUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.gray200,
                          child: const Icon(Icons.broken_image),
                        ),
                      )
                    : Container(
                        color: AppColors.gray200,
                        child: const Icon(Icons.photo_library_outlined, size: 48, color: AppColors.gray400),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collection.title,
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${collection.totalPhotos} photos',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
