import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musea/features/discover/presentation/providers/photos_provider.dart';
import 'package:musea/features/discover/presentation/providers/topics_provider.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/shared/widgets/loading_indicator.dart';
import 'package:musea/shared/widgets/error_state.dart';
import 'package:musea/shared/widgets/photo_feed.dart';
import 'package:musea/shared/widgets/topic_bar.dart';
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
                    const SizedBox(height: 8),
                    topicsAsync.when(
                      data: (topics) => TopicBar(
                        topics: topics,
                        selectedTopicSlug: _selectedTopicSlug,
                        onTopicTap: _onTopicTap,
                      ),
                      loading: () => const SizedBox(
                        height: 48,
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
                  onPhotoTap: (photo) => context.go('/photo/${photo.id}'),
                  onUserTap: (photo) => context.go('/profile/${photo.user.username}'),
                  onLikeTap: (photo) => _toggleLike(photo),
                  onDownloadTap: (photo) => _handleDownload(context),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, color: AppColors.gray500),
                  SizedBox(width: 12),
                  Text(
                    'Search photos...',
                    style: TextStyle(color: AppColors.gray500),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _handleRandom,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shuffle, color: AppColors.onPrimary),
            ),
          ),
        ],
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
