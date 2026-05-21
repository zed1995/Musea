import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musea/features/auth/presentation/providers/auth_provider.dart';
import 'package:musea/features/auth/presentation/widgets/auth_gate_sheet.dart';
import 'package:musea/features/discover/presentation/providers/photos_provider.dart';
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
  int _currentPage = 1;

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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    setState(() {
      _currentPage++;
    });
  }

  void _onTopicTap(String? slug) {
    setState(() {
      _selectedTopicSlug = slug;
      _currentPage = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final topicsAsync = ref.watch(topicsProvider);
    final photosAsync = _selectedTopicSlug == null
        ? ref.watch(photosProvider(_currentPage))
        : ref.watch(topicPhotosProvider(
            TopicPhotosParams(
                topicSlug: _selectedTopicSlug!, page: _currentPage),
          ));

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(photosProvider);
            ref.invalidate(topicsProvider);
          },
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFF1F1F2)),
                        ),
                      ),
                      child: _buildHeader(),
                    ),
                    topicsAsync.when(
                      data: (topics) => _buildFilterTabs(topics),
                      loading: () => const SizedBox(
                        height: 38,
                        child: Center(child: LoadingIndicator()),
                      ),
                      error: (error, stack) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              photosAsync.when(
                data: (photos) => PhotoFeed(
                  photos: photos,
                  isLoadingMore: false,
                  onPhotoTap: (photo) => context.push(
                    '/photo/${photo.id}',
                    extra: PhotoDetailExtra(photo: photo),
                  ),
                  onUserTap: (photo) =>
                      context.push('/profile/${photo.user.username}'),
                  onLikeTap: (photo) => _toggleLike(photo),
                  onBookmarkTap: (photo) => _handleDownload(context),
                ),
                loading: () => const SliverFillRemaining(
                  child: Center(child: LoadingIndicator()),
                ),
                error: (error, stack) => SliverFillRemaining(
                  child: ErrorState(
                    message: error.toString(),
                    onRetry: () => ref.invalidate(photosProvider),
                  ),
                ),
              ),
            ],
          ),
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

  void _toggleLike(Photo photo) {
    final authState = ref.read(authControllerProvider);
    if (!authState.isAuthenticated) {
      showAuthGateSheet(context, ref);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Liked "${photo.user.name}"\'s photo')),
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
}
