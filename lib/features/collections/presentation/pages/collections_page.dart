import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:musea/core/theme/colors.dart';
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
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(collections)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CollectionCard(collection: collections[index]),
                        );
                      },
                      childCount: collections.length,
                    ),
                  ),
                ),
              ],
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

  Widget _buildHeader(List<Collection> collections) {
    final totalPhotos = collections.fold<int>(
      0,
      (sum, c) => sum + c.totalPhotos,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Collections',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${collections.length} collections · $totalPhotos photos',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFA1A1AA),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF18181B),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({required this.collection});

  final Collection collection;

  @override
  Widget build(BuildContext context) {
    final previewUrl = collection.coverPhoto?.urlRegular ??
        (collection.previewPhotos.isNotEmpty
            ? collection.previewPhotos.first.smallUrl
            : null);

    return GestureDetector(
      onTap: () => context.push('/collection/${collection.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: double.infinity,
          child: AspectRatio(
            aspectRatio: 5 / 2,
            child: Stack(
              children: [
                // Cover image
                if (previewUrl != null)
                  CachedNetworkImage(
                    imageUrl: previewUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorWidget: (context, url, error) => _placeholder(),
                  )
                else
                  _placeholder(),

                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.65),
                        Colors.black.withValues(alpha: 0.20),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // Content
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                collection.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _subtitle(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.gray200,
      child: const Icon(Icons.photo_library_outlined, size: 40, color: AppColors.gray400),
    );
  }

  String _subtitle() {
    final parts = <String>[];
    final count = collection.totalPhotos > 0
        ? collection.totalPhotos
        : collection.previewPhotos.length;
    parts.add('$count photos');

    if (collection.updatedAt != null) {
      final now = DateTime.now();
      final diff = now.difference(collection.updatedAt!);
      if (diff.inDays == 0) {
        parts.add('Updated today');
      } else if (diff.inDays == 1) {
        parts.add('Updated yesterday');
      } else if (diff.inDays < 30) {
        parts.add('Updated ${diff.inDays} days ago');
      } else if (diff.inDays < 60) {
        parts.add('Updated 1 month ago');
      } else {
        parts.add('Updated ${(diff.inDays / 30).floor()} months ago');
      }
    }

    return parts.join(' · ');
  }
}
