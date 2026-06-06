import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/features/auth/presentation/providers/auth_provider.dart';
import 'package:musea/features/auth/presentation/widgets/auth_gate_sheet.dart';
import 'package:musea/features/collections/presentation/providers/collections_provider.dart';
import 'package:musea/features/collections/presentation/widgets/create_collection_sheet.dart';
import 'package:musea/shared/widgets/collection_card.dart';
import 'package:musea/shared/widgets/empty_state.dart';
import 'package:musea/shared/widgets/error_state.dart';
import 'package:musea/shared/widgets/loading_indicator.dart';
import 'package:musea/l10n/generated/app_localizations.dart';

class CollectionsPage extends ConsumerWidget {
  const CollectionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final collectionsAsync = ref.watch(collectionsProvider(1));
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      body: collectionsAsync.when(
        data: (collections) {
          if (collections.isEmpty) {
            return SafeArea(
              child: Column(
                children: [
                  _CollectionsHeader(
                    title: l10n.collectionsPageTitle,
                    onAddPressed: () =>
                        _handleAddPressed(context, ref, authState),
                  ),
                  const Expanded(
                    child: EmptyState(
                      icon: Icons.collections_bookmark_outlined,
                      title: 'No collections',
                      subtitle: 'Check back later for curated collections',
                    ),
                  ),
                ],
              ),
            );
          }

          return SafeArea(
            child: Column(
              children: [
                _CollectionsHeader(
                  title: l10n.collectionsPageTitle,
                  onAddPressed: () =>
                      _handleAddPressed(context, ref, authState),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => ref.invalidate(collectionsProvider),
                    child: CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: CollectionCard(
                                    collection: collections[index]),
                              ),
                              childCount: collections.length,
                            ),
                          ),
                        ),
                      ],
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

  void _handleAddPressed(
    BuildContext context,
    WidgetRef ref,
    AuthState authState,
  ) {
    if (authState.isAuthenticated) {
      showCreateCollectionSheet(context);
    } else {
      showAuthGateSheet(
        context,
        ref,
        title: 'Sign in to create collections',
        body:
            'Save your favorite photos into custom collections and organize them your way.',
      );
    }
  }
}

class _CollectionsHeader extends StatelessWidget {
  const _CollectionsHeader({
    required this.title,
    required this.onAddPressed,
  });

  final String title;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 30,
                height: 1.1,
                fontWeight: FontWeight.w700,
                color: Color(0xFF18181B),
              ),
            ),
          ),
          GestureDetector(
            onTap: onAddPressed,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE5E5E5)),
              ),
              child: const Icon(Icons.add, size: 18, color: Color(0xFF18181B)),
            ),
          ),
        ],
      ),
    );
  }
}
