import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/features/search/domain/entities/search_result.dart';
import 'package:musea/features/search/presentation/providers/search_provider.dart';
import 'package:musea/shared/widgets/error_state.dart';
import 'package:musea/shared/widgets/loading_indicator.dart';

enum SearchSegment { photos, collections, users }

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late final TextEditingController _controller;
  SearchSegment _segment = SearchSegment.photos;
  String _selectedFilter = 'Relevant';

  static const _filters = [
    'Relevant',
    'Latest',
    'Green',
    'Landscape',
    'Safe',
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim();
    final photoParams = _photoParams(query);
    final collectionParams = _collectionParams(query);
    final userParams = _userParams(query);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _SearchHeader(
              controller: _controller,
              selectedSegment: _segment,
              selectedFilter: _selectedFilter,
              filters: _filters,
              onBack: context.pop,
              onSegmentChanged: (segment) {
                setState(() => _segment = segment);
              },
              onClear: () {
                _controller.clear();
              },
              onFilterSelected: (filter) {
                setState(() => _selectedFilter = filter);
              },
            ),
            Expanded(
              child: query.isEmpty
                  ? const _SearchIdleState()
                  : switch (_segment) {
                      SearchSegment.photos =>
                        ref.watch(photoSearchProvider(photoParams)).when(
                              data: (result) => SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  12,
                                  12,
                                  24,
                                ),
                                child: _PhotoResultsSection(
                                  photos: result.results,
                                  total: result.total,
                                ),
                              ),
                              loading: () =>
                                  const Center(child: LoadingIndicator()),
                              error: (error, stack) => ErrorState(
                                message: error.toString(),
                                onRetry: () => ref.invalidate(
                                  photoSearchProvider(photoParams),
                                ),
                              ),
                            ),
                      SearchSegment.collections => ref
                          .watch(collectionSearchProvider(collectionParams))
                          .when(
                            data: (result) => SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                12,
                                12,
                                24,
                              ),
                              child: _CollectionResultsSection(
                                collections: result.results,
                                total: result.total,
                              ),
                            ),
                            loading: () =>
                                const Center(child: LoadingIndicator()),
                            error: (error, stack) => ErrorState(
                              message: error.toString(),
                              onRetry: () => ref.invalidate(
                                collectionSearchProvider(collectionParams),
                              ),
                            ),
                          ),
                      SearchSegment.users =>
                        ref.watch(userSearchProvider(userParams)).when(
                              data: (result) => SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  12,
                                  12,
                                  24,
                                ),
                                child: _UserResultsSection(
                                  users: result.results,
                                  total: result.total,
                                ),
                              ),
                              loading: () =>
                                  const Center(child: LoadingIndicator()),
                              error: (error, stack) => ErrorState(
                                message: error.toString(),
                                onRetry: () => ref.invalidate(
                                  userSearchProvider(userParams),
                                ),
                              ),
                            ),
                    },
            ),
          ],
        ),
      ),
    );
  }

  PhotoSearchParams _photoParams(String query) {
    return switch (_selectedFilter) {
      'Latest' => PhotoSearchParams(
          query: query,
          orderBy: 'latest',
        ),
      'Green' => PhotoSearchParams(
          query: query,
          color: 'green',
        ),
      'Landscape' => PhotoSearchParams(
          query: query,
          orientation: 'landscape',
        ),
      'Safe' => PhotoSearchParams(
          query: query,
          contentFilter: 'high',
        ),
      _ => PhotoSearchParams(
          query: query,
          orderBy: 'relevant',
        ),
    };
  }

  CollectionSearchParams _collectionParams(String query) {
    return CollectionSearchParams(query: query);
  }

  UserSearchParams _userParams(String query) {
    return UserSearchParams(query: query);
  }
}

class _SearchIdleState extends StatelessWidget {
  const _SearchIdleState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_rounded,
            size: 36,
            color: Color(0xFFA1A1AA),
          ),
          SizedBox(height: 12),
          Text(
            'Start typing to search',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF18181B),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'We will query photos, collections, and creators using the live search endpoints.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF71717A),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoResultsSection extends StatelessWidget {
  const _PhotoResultsSection({
    required this.photos,
    required this.total,
  });

  final List<Photo> photos;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return const _SearchEmptyState(
        title: 'No matching photos',
        subtitle: 'Try a different keyword or broaden the query.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SearchSectionHeader(
          eyebrow: 'Photos',
          title: '${_formatCount(total)} results',
          actionLabel: 'View all',
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: photos.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final photo = photos[index];
            return GestureDetector(
              onTap: () => context.push('/photo/${photo.id}'),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: CachedNetworkImage(
                      imageUrl: photo.urlSmall,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.gray100,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: Text(
                      photo.user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.controller,
    required this.selectedSegment,
    required this.selectedFilter,
    required this.filters,
    required this.onBack,
    required this.onSegmentChanged,
    required this.onClear,
    required this.onFilterSelected,
  });

  final TextEditingController controller;
  final SearchSegment selectedSegment;
  final String selectedFilter;
  final List<String> filters;
  final VoidCallback onBack;
  final ValueChanged<SearchSegment> onSegmentChanged;
  final VoidCallback onClear;
  final ValueChanged<String> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F1F2)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              OutlinedButton(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(40, 40),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Color(0xFFE4E4E7)),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Color(0xFF3F3F46),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F6F7),
                    border: Border.all(color: const Color(0xFFECECF0)),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search,
                        color: AppColors.gray400,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          autofocus: true,
                          decoration: const InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            hintText: 'Search photos, collections, users...',
                            hintStyle: TextStyle(
                              color: AppColors.gray400,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: const TextStyle(
                            color: Color(0xFF18181B),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (controller.text.isNotEmpty)
                        GestureDetector(
                          onTap: onClear,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFD4D4D8),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Color(0xFF71717A),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SegmentButton(
                  label: 'Photos',
                  isActive: selectedSegment == SearchSegment.photos,
                  onTap: () => onSegmentChanged(SearchSegment.photos),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SegmentButton(
                  label: 'Collections',
                  isActive: selectedSegment == SearchSegment.collections,
                  onTap: () => onSegmentChanged(SearchSegment.collections),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SegmentButton(
                  label: 'Users',
                  isActive: selectedSegment == SearchSegment.users,
                  onTap: () => onSegmentChanged(SearchSegment.users),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final filter = filters[index];
                final isActive = filter == selectedFilter;
                return GestureDetector(
                  onTap: () => onFilterSelected(filter),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF18181B)
                          : const Color(0xFFF6F6F7),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      filter,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color:
                            isActive ? Colors.white : const Color(0xFF52525B),
                      ),
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemCount: filters.length,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF18181B) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : const Color(0xFF71717A),
          ),
        ),
      ),
    );
  }
}

class _CollectionResultsSection extends StatelessWidget {
  const _CollectionResultsSection({
    required this.collections,
    required this.total,
  });

  final List<Collection> collections;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (collections.isEmpty) {
      return const _SearchEmptyState(
        title: 'No matching collections',
        subtitle: 'Try another phrase to find curated sets.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SearchSectionHeader(
          eyebrow: 'Collections',
          title: '${_formatCount(total)} results',
          actionLabel: 'View all',
        ),
        const SizedBox(height: 12),
        ...collections.map(
          (collection) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => context.push('/collection/${collection.id}'),
              child: Container(
                height: 164,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: AppColors.gray100,
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (collection.coverPhoto != null)
                      CachedNetworkImage(
                        imageUrl: collection.coverPhoto!.urlRegular,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.gray100,
                        ),
                      ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.02),
                            Colors.black.withValues(alpha: 0.56),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            collection.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            collection.description ??
                                '${collection.totalPhotos} photos · by ${collection.user?.name ?? 'Musea'}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UserResultsSection extends StatelessWidget {
  const _UserResultsSection({
    required this.users,
    required this.total,
  });

  final List<User> users;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const _SearchEmptyState(
        title: 'No matching users',
        subtitle: 'Try a creator name, username, or location.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SearchSectionHeader(
          eyebrow: 'Users',
          title: '${_formatCount(total)} results',
          actionLabel: 'View all',
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF4F4F5)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: users.map((user) {
              return GestureDetector(
                onTap: () => context.push('/profile/${user.username}'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: users.first == user
                            ? Colors.transparent
                            : const Color(0xFFF4F4F5),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: user.profileImageMedium,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            width: 48,
                            height: 48,
                            color: AppColors.gray100,
                            alignment: Alignment.center,
                            child: Text(
                              user.name.isNotEmpty ? user.name[0] : '?',
                              style: const TextStyle(
                                color: Color(0xFF71717A),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF18181B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '@${user.username}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF71717A),
                              ),
                            ),
                            if ((user.bio ?? '').isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                user.bio!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF71717A),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF18181B),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Follow',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SearchSectionHeader extends StatelessWidget {
  const _SearchSectionHeader({
    required this.eyebrow,
    required this.title,
    required this.actionLabel,
  });

  final String eyebrow;
  final String title;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFA1A1AA),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF18181B),
              ),
            ),
          ],
        ),
        Text(
          actionLabel,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF71717A),
          ),
        ),
      ],
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 36,
            color: Color(0xFFA1A1AA),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF18181B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF71717A),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatCount(int count) {
  final value = count.toString();
  final buffer = StringBuffer();

  for (var i = 0; i < value.length; i++) {
    final fromEnd = value.length - i;
    buffer.write(value[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) {
      buffer.write(',');
    }
  }

  return buffer.toString();
}
