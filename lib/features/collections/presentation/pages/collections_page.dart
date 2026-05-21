import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/features/collections/presentation/providers/collections_provider.dart';
import 'package:musea/shared/widgets/collection_card.dart';
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
                          child: CollectionCard(collection: collections[index]),
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
