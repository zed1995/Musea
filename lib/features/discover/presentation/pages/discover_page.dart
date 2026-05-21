import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musea/features/auth/presentation/providers/auth_provider.dart';
import 'package:musea/features/auth/presentation/widgets/auth_gate_sheet.dart';
import 'package:musea/features/discover/presentation/providers/photos_provider.dart';
import 'package:musea/features/discover/presentation/providers/photo_like_provider.dart';
import 'package:musea/features/discover/presentation/providers/topics_provider.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/topic.dart';
import 'package:musea/shared/widgets/loading_indicator.dart';
import 'package:musea/shared/widgets/error_state.dart';
import 'package:musea/shared/widgets/photo_feed.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/router/detail_route_extras.dart';

class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({super.key});

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  String? _selectedTopicSlug;
  final ScrollController _scrollController = ScrollController();
  final Map<String, double> _scrollOffsets = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    _scrollOffsets[_currentFeedKey] = position.pixels;

    if (!position.hasPixels || !position.hasContentDimensions) return;
    if (position.maxScrollExtent <= 0) return;
    if (position.userScrollDirection != ScrollDirection.reverse) return;

    if (position.pixels >= position.maxScrollExtent - 200) {
      ref.read(discoverFeedProvider(_selectedTopicSlug).notifier).loadMore();
    }
  }

  void _onTopicTap(String? slug) {
    if (_selectedTopicSlug == slug) return;

    if (_scrollController.hasClients) {
      _scrollOffsets[_currentFeedKey] = _scrollController.position.pixels;
    }

    setState(() {
      _selectedTopicSlug = slug;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final targetOffset = _scrollOffsets[_currentFeedKey] ?? 0;
      final maxExtent = _scrollController.position.maxScrollExtent;
      _scrollController.jumpTo(targetOffset.clamp(0, maxExtent));
    });
  }

  @override
  Widget build(BuildContext context) {
    final topics = ref.watch(topicsProvider);
    final feedState = ref.watch(discoverFeedProvider(_selectedTopicSlug));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Fixed search bar
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFF1F1F2)),
                ),
              ),
              child: _buildHeader(),
            ),
            // Fixed filter tabs
            _buildFilterTabs(topics),
            // Scrollable photo feed
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await ref
                      .read(discoverFeedProvider(_selectedTopicSlug).notifier)
                      .refresh();
                },
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    if (feedState.isInitialLoading)
                      const SliverFillRemaining(
                        child: Center(child: LoadingIndicator()),
                      )
                    else if (feedState.error != null &&
                        feedState.photos.isEmpty)
                      SliverFillRemaining(
                        child: ErrorState(
                          message: feedState.error.toString(),
                          onRetry: () {
                            ref
                                .read(discoverFeedProvider(_selectedTopicSlug)
                                    .notifier)
                                .refresh();
                          },
                        ),
                      )
                    else
                      PhotoFeed(
                        photos: feedState.photos,
                        isLoadingMore: feedState.isLoadingMore,
                        onPhotoTap: (photo) => context.push(
                          '/photo/${photo.id}',
                          extra: PhotoDetailExtra(photo: photo),
                        ),
                        onUserTap: (photo) =>
                            context.push('/profile/${photo.user.username}',
                                extra: ProfileDetailExtra(user: photo.user)),
                        onLikeTap: (photo) => _toggleLike(photo),
                        onBookmarkTap: (photo) => _handleDownload(context),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/search'),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.only(left: 15, right: 10),
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: AppColors.gray400, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Search photos, collections, users...',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.gray400,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _handleRandom,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shuffle_rounded,
                  color: AppColors.onPrimary, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(List<Topic> topics) {
    return Container(
      height: 45,
      alignment: Alignment.bottomLeft,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF0F0F0)),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 2, 12, 0),
        children: [
          _tabItem('All', _selectedTopicSlug == null, () {
            _onTopicTap(null);
          }),
          ...topics.map((topic) => _tabItem(
                topic.title,
                _selectedTopicSlug == topic.slug,
                () => _onTopicTap(topic.slug),
              )),
        ],
      ),
    );
  }

  Widget _tabItem(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isActive
                    ? const Color(0xFF18181B)
                    : const Color(0xFF71717A),
              ),
            ),
            const SizedBox(height: 9),
            Container(
              height: 2,
              width: label.length * 8.0 + 2,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF18181B) : Colors.transparent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleLike(Photo photo) async {
    final authState = ref.read(authControllerProvider);
    if (!authState.isAuthenticated) {
      showAuthGateSheet(context, ref);
      return;
    }

    final success = await ref
        .read(photoLikeControllerProvider.notifier)
        .toggle(photo: photo);
    if (!mounted || success) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not update like right now')),
    );
  }

  void _handleDownload(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Open photo to download')),
    );
  }

  void _handleRandom() async {
    final randomPhoto = await ref.read(randomPhotoProvider.future);
    if (!mounted) return;
    context.go(
      '/photo/${randomPhoto.id}',
      extra: PhotoDetailExtra(photo: randomPhoto),
    );
  }

  String get _currentFeedKey => _selectedTopicSlug ?? discoverAllFeedKey;
}
