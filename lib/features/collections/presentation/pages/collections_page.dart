import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/collections/presentation/providers/collections_provider.dart';
import 'package:musea/shared/widgets/empty_state.dart';
import 'package:musea/shared/widgets/error_state.dart';
import 'package:musea/shared/widgets/loading_indicator.dart';

class CollectionsPage extends ConsumerWidget {
  const CollectionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionsAsync = ref.watch(collectionsProvider(1));

    return Scaffold(
      body: SafeArea(
        child: collectionsAsync.when(
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
                  const SliverToBoxAdapter(child: _CollectionsHeader()),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child:
                              _CollectionCard(collection: collections[index]),
                        ),
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
      ),
    );
  }
}

class _CollectionsHeader extends StatelessWidget {
  const _CollectionsHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Collections',
              style: TextStyle(
                fontSize: 30,
                height: 1.1,
                fontWeight: FontWeight.w700,
                color: Color(0xFF18181B),
              ),
            ),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E5E5)),
            ),
            child: const Icon(Icons.add, size: 18, color: Color(0xFF18181B)),
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
    final coverUrl = collection.coverPhoto?.urlRegular ??
        (collection.previewPhotos.isNotEmpty
            ? collection.previewPhotos.first.smallUrl
            : null);

    final previewCount = collection.previewPhotos.length.clamp(0, 4);

    return GestureDetector(
      onTap: () => context.push('/collection/${collection.id}'),
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
                                _metaText(),
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
                              Container(
                                height: 22,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.12),
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Featured',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Container(
                              height: 28,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 9),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${collection.totalPhotos}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.chevron_right,
                                    size: 16,
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

  String _metaText() {
    if (collection.user?.name case final name? when name.isNotEmpty) {
      return 'by $name';
    }
    return '${collection.totalPhotos} photos';
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.gray200,
      child: const Center(
        child: Icon(Icons.photo_library_outlined,
            size: 38, color: AppColors.gray400),
      ),
    );
  }
}
