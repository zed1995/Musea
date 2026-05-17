import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musea/features/discover/presentation/providers/photos_provider.dart';
import 'package:musea/features/discover/presentation/providers/topics_provider.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/topic.dart';
import 'package:musea/shared/widgets/loading_indicator.dart';
import 'package:musea/shared/widgets/error_state.dart';
import 'package:musea/shared/widgets/photo_feed.dart';
import 'package:musea/core/theme/colors.dart';

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
            TopicPhotosParams(topicSlug: _selectedTopicSlug!, page: _currentPage),
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
                    _buildHeader(),
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
                  onPhotoTap: (photo) => context.push('/photo/${photo.id}'),
                  onUserTap: (photo) => context.push('/profile/${photo.user.username}'),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, color: AppColors.gray400, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Search photos...',
                    style: TextStyle(color: AppColors.gray400, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _handleRandom,
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shuffle, color: AppColors.onPrimary, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(List<Topic> topics) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
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
        padding: const EdgeInsets.symmetric(horizontal: 12),
        margin: const EdgeInsets.only(right: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isActive ? const Color(0xFF18181B) : const Color(0xFFA1A1AA),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 2,
              width: label.length * 8.5 + 4,
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
    context.go('/photo/${randomPhoto.id}');
  }
}
