import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/l10n/generated/app_localizations.dart';
import 'package:musea/router/detail_route_extras.dart';
import 'package:musea/features/search/presentation/providers/search_controller.dart';
import 'package:musea/shared/widgets/collection_card.dart';
import 'package:musea/shared/widgets/error_state.dart';
import 'package:musea/shared/widgets/loading_indicator.dart';
import 'package:musea/shared/widgets/photo_grid.dart';

enum SearchSegment { photos, collections, users }

enum PhotoSortOption { relevant, latest }

enum PhotoColorOption { any, green, blue, blackAndWhite }

enum PhotoOrientationOption { any, landscape, portrait, squarish }

enum PhotoContentSafetyOption { low, high }

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  static const double _photoFilterPanelHeight = 210;
  late final TextEditingController _controller;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;
  String _submittedQuery = '';
  bool _ignoreInitialTextChange = false;
  SearchSegment _segment = SearchSegment.photos;
  bool _isFilterPanelVisible = false;
  PhotoSortOption _sortOption = PhotoSortOption.relevant;
  PhotoColorOption _colorOption = PhotoColorOption.any;
  PhotoOrientationOption _orientationOption = PhotoOrientationOption.any;
  PhotoContentSafetyOption _contentSafetyOption = PhotoContentSafetyOption.high;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _ignoreInitialTextChange = widget.initialQuery.trim().isNotEmpty;
    _controller.addListener(_onTextChanged);
    _scrollController.addListener(_onScroll);
    final initialQuery = widget.initialQuery.trim();
    if (initialQuery.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _performSearch(initialQuery);
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_ignoreInitialTextChange &&
        _controller.text.trim() == widget.initialQuery.trim()) {
      _ignoreInitialTextChange = false;
      setState(() {});
      return;
    }
    setState(() {});
    _debounceTimer?.cancel();
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() => _submittedQuery = '');
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    switch (_segment) {
      case SearchSegment.photos:
        ref.read(searchPhotosControllerProvider.notifier).loadMore();
      case SearchSegment.collections:
        ref.read(searchCollectionsControllerProvider.notifier).loadMore();
      case SearchSegment.users:
        ref.read(searchUsersControllerProvider.notifier).loadMore();
    }
  }

  void _performSearch(String query) {
    setState(() => _submittedQuery = query);
    ref.read(searchPhotosControllerProvider.notifier).search(
          query,
          orderBy: _sortOption == PhotoSortOption.latest ? 'latest' : 'relevant',
          color: _colorOption == PhotoColorOption.any
              ? null
              : _colorOption == PhotoColorOption.green
                  ? 'green'
                  : _colorOption == PhotoColorOption.blue
                      ? 'blue'
                      : 'black_and_white',
          orientation: _orientationOption == PhotoOrientationOption.any
              ? null
              : _orientationOption.name,
          contentFilter:
              _contentSafetyOption == PhotoContentSafetyOption.low ? 'low' : 'high',
        );
    ref.read(searchCollectionsControllerProvider.notifier).search(query);
    ref.read(searchUsersControllerProvider.notifier).search(query);
  }

  @override
  Widget build(BuildContext context) {
    final photosState = ref.watch(searchPhotosControllerProvider);
    final collectionsState = ref.watch(searchCollectionsControllerProvider);
    final usersState = ref.watch(searchUsersControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _SearchHeader(
              controller: _controller,
              selectedSegment: _segment,
              showPhotoFilterTrigger: _segment == SearchSegment.photos,
              isFilterButtonActive:
                  _isFilterPanelVisible || _hasNonDefaultPhotoFilters,
              onBack: context.pop,
              onClear: () {
                setState(() {
                  _controller.clear();
                  _submittedQuery = '';
                });
              },
              onSearch: () {
                _debounceTimer?.cancel();
                final query = _controller.text.trim();
                if (query.isNotEmpty) _performSearch(query);
              },
              onSegmentChanged: (segment) {
                setState(() {
                  _segment = segment;
                  if (segment != SearchSegment.photos) {
                    _isFilterPanelVisible = false;
                  }
                });
              },
              onFilterTap: () {
                setState(() {
                  _isFilterPanelVisible = !_isFilterPanelVisible;
                });
              },
            ),
            Expanded(
              child: _submittedQuery.isEmpty
                  ? const _SearchIdleState()
                  : Stack(
                      children: [
                        Positioned.fill(
                          child: switch (_segment) {
                            SearchSegment.photos => _PaginatedPhotoResults(
                                state: photosState,
                                scrollController: _scrollController,
                              ),
                            SearchSegment.collections =>
                              _PaginatedCollectionResults(
                                state: collectionsState,
                                scrollController: _scrollController,
                              ),
                            SearchSegment.users => _PaginatedUserResults(
                                state: usersState,
                                scrollController: _scrollController,
                              ),
                          },
                        ),
                        if (_segment == SearchSegment.photos &&
                            _isFilterPanelVisible) ...[
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: _photoFilterPanelHeight,
                              ),
                              child: GestureDetector(
                                key: const Key('photo-filter-overlay'),
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  setState(() {
                                    _isFilterPanelVisible = false;
                                  });
                                },
                                child: Container(
                                  color: const Color(0x1A18181B),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: _PhotoFilterPanel(
                              sortOption: _sortOption,
                              colorOption: _colorOption,
                              orientationOption: _orientationOption,
                              contentSafetyOption: _contentSafetyOption,
                              onSortChanged: (value) {
                                setState(() => _sortOption = value);
                              },
                              onColorChanged: (value) {
                                setState(() => _colorOption = value);
                              },
                              onOrientationChanged: (value) {
                                setState(() => _orientationOption = value);
                              },
                              onContentSafetyChanged: (value) {
                                setState(() => _contentSafetyOption = value);
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _hasNonDefaultPhotoFilters {
    return _colorOption != PhotoColorOption.any ||
        _orientationOption != PhotoOrientationOption.any ||
        _contentSafetyOption != PhotoContentSafetyOption.high;
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.controller,
    required this.selectedSegment,
    required this.showPhotoFilterTrigger,
    required this.isFilterButtonActive,
    required this.onBack,
    required this.onClear,
    required this.onSearch,
    required this.onSegmentChanged,
    required this.onFilterTap,
  });

  final TextEditingController controller;
  final SearchSegment selectedSegment;
  final bool showPhotoFilterTrigger;
  final bool isFilterButtonActive;
  final VoidCallback onBack;
  final VoidCallback onClear;
  final VoidCallback onSearch;
  final ValueChanged<SearchSegment> onSegmentChanged;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            hintText: l10n.searchPlaceholder,
                            hintStyle: const TextStyle(
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
                      const SizedBox(width: 8),
                      GestureDetector(
                        key: const Key('search-submit-button'),
                        onTap: onSearch,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF18181B),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: Colors.white,
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
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _SegmentButton(
                        label: l10n.segmentPhotos,
                        isActive: selectedSegment == SearchSegment.photos,
                        onTap: () => onSegmentChanged(SearchSegment.photos),
                      ),
                      const SizedBox(width: 8),
                      _SegmentButton(
                        label: l10n.segmentCollections,
                        isActive: selectedSegment == SearchSegment.collections,
                        onTap: () =>
                            onSegmentChanged(SearchSegment.collections),
                      ),
                      const SizedBox(width: 8),
                      _SegmentButton(
                        label: l10n.segmentUsers,
                        isActive: selectedSegment == SearchSegment.users,
                        onTap: () => onSegmentChanged(SearchSegment.users),
                      ),
                    ],
                  ),
                ),
              ),
              if (showPhotoFilterTrigger) ...[
                const SizedBox(width: 8),
                _PhotoFilterTrigger(
                  isActive: isFilterButtonActive,
                  onTap: onFilterTap,
                ),
              ],
            ],
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
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 16),
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

class _PhotoFilterTrigger extends StatelessWidget {
  const _PhotoFilterTrigger({
    required this.isActive,
    required this.onTap,
  });

  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('photo-filter-trigger'),
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF18181B) : Colors.white,
          border: Border.all(
            color: isActive ? const Color(0xFF18181B) : const Color(0xFFECECF0),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.tune_rounded,
          size: 18,
          color: isActive ? Colors.white : const Color(0xFF27272A),
        ),
      ),
    );
  }
}

class _PhotoFilterPanel extends StatelessWidget {
  const _PhotoFilterPanel({
    required this.sortOption,
    required this.colorOption,
    required this.orientationOption,
    required this.contentSafetyOption,
    required this.onSortChanged,
    required this.onColorChanged,
    required this.onOrientationChanged,
    required this.onContentSafetyChanged,
  });

  final PhotoSortOption sortOption;
  final PhotoColorOption colorOption;
  final PhotoOrientationOption orientationOption;
  final PhotoContentSafetyOption contentSafetyOption;
  final ValueChanged<PhotoSortOption> onSortChanged;
  final ValueChanged<PhotoColorOption> onColorChanged;
  final ValueChanged<PhotoOrientationOption> onOrientationChanged;
  final ValueChanged<PhotoContentSafetyOption> onContentSafetyChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      key: const Key('photo-filter-panel'),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFECECF0)),
          bottom: BorderSide(color: Color(0xFFECECF0)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FilterSection<PhotoSortOption>(
            title: l10n.sortBy,
            options: [
              _FilterOption(
                label: l10n.filterRelevant,
                value: PhotoSortOption.relevant,
              ),
              _FilterOption(
                label: l10n.filterLatest,
                value: PhotoSortOption.latest,
              ),
            ],
            selectedValue: sortOption,
            onSelected: onSortChanged,
          ),
          const SizedBox(height: 16),
          _FilterSection<PhotoColorOption>(
            title: l10n.colorLabel,
            options: [
              _FilterOption(label: l10n.filterAny, value: PhotoColorOption.any),
              _FilterOption(label: l10n.filterGreen, value: PhotoColorOption.green),
              _FilterOption(label: l10n.filterBlue, value: PhotoColorOption.blue),
              _FilterOption(
                label: l10n.filterBlackAndWhite,
                value: PhotoColorOption.blackAndWhite,
              ),
            ],
            selectedValue: colorOption,
            onSelected: onColorChanged,
          ),
          const SizedBox(height: 16),
          _FilterSection<PhotoOrientationOption>(
            title: l10n.orientationLabel,
            options: [
              _FilterOption(label: l10n.filterAny, value: PhotoOrientationOption.any),
              _FilterOption(
                label: l10n.filterLandscape,
                value: PhotoOrientationOption.landscape,
              ),
              _FilterOption(
                label: l10n.filterPortrait,
                value: PhotoOrientationOption.portrait,
              ),
              _FilterOption(
                label: l10n.filterSquarish,
                value: PhotoOrientationOption.squarish,
              ),
            ],
            selectedValue: orientationOption,
            onSelected: onOrientationChanged,
          ),
          const SizedBox(height: 16),
          _FilterSection<PhotoContentSafetyOption>(
            title: l10n.contentSafety,
            options: [
              _FilterOption(label: l10n.filterLow, value: PhotoContentSafetyOption.low),
              _FilterOption(
                label: l10n.filterHigh,
                value: PhotoContentSafetyOption.high,
              ),
            ],
            selectedValue: contentSafetyOption,
            onSelected: onContentSafetyChanged,
          ),
        ],
      ),
    );
  }
}

class _FilterSection<T> extends StatelessWidget {
  const _FilterSection({
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  final String title;
  final List<_FilterOption<T>> options;
  final T selectedValue;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF18181B),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isActive = selectedValue == option.value;
            return GestureDetector(
              onTap: () => onSelected(option.value),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF18181B) : Colors.white,
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFF18181B)
                        : const Color(0xFFECECF0),
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  child: Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : const Color(0xFF52525B),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _FilterOption<T> {
  const _FilterOption({
    required this.label,
    required this.value,
  });

  final String label;
  final T value;
}

class _PaginatedPhotoResults extends StatelessWidget {
  const _PaginatedPhotoResults({
    required this.state,
    required this.scrollController,
  });

  final PaginatedState<Photo> state;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (state.isLoading) {
      return const Center(child: LoadingIndicator());
    }
    if (state.error != null && state.items.isEmpty) {
      return ErrorState(message: state.error.toString());
    }
    if (state.items.isEmpty) {
      return _SearchEmptyState(
        title: l10n.noMatchingPhotos,
        subtitle: l10n.noMatchingPhotosSubtitle,
      );
    }

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
      child: Column(
        children: [
          PhotoGrid(photos: state.items, showLikes: true),
          if (state.isLoadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: LoadingIndicator(),
            ),
        ],
      ),
    );
  }
}

class _PaginatedCollectionResults extends StatelessWidget {
  const _PaginatedCollectionResults({
    required this.state,
    required this.scrollController,
  });

  final PaginatedState<Collection> state;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (state.isLoading) {
      return const Center(child: LoadingIndicator());
    }
    if (state.error != null && state.items.isEmpty) {
      return ErrorState(message: state.error.toString());
    }
    if (state.items.isEmpty) {
      return _SearchEmptyState(
        title: l10n.noMatchingCollections,
        subtitle: l10n.noMatchingCollectionsSubtitle,
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
      itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: LoadingIndicator(),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CollectionCard(collection: state.items[index]),
        );
      },
    );
  }
}

class _PaginatedUserResults extends StatelessWidget {
  const _PaginatedUserResults({
    required this.state,
    required this.scrollController,
  });

  final PaginatedState<User> state;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (state.isLoading) {
      return const Center(child: LoadingIndicator());
    }
    if (state.error != null && state.items.isEmpty) {
      return ErrorState(message: state.error.toString());
    }
    if (state.items.isEmpty) {
      return _SearchEmptyState(
        title: l10n.noMatchingUsers,
        subtitle: l10n.noMatchingUsersSubtitle,
      );
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF4F4F5)),
          ),
          child: Column(
            children: List.generate(state.items.length, (index) {
              final user = state.items[index];
              final isFollowing = user.followedByUser == true;
              return _UserResultTile(
                user: user,
                isFollowing: isFollowing,
                showTopBorder: index > 0,
              );
            }),
          ),
        ),
        if (state.isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: LoadingIndicator(),
          ),
      ],
    );
  }
}

class _UserResultTile extends StatelessWidget {
  const _UserResultTile({
    required this.user,
    required this.isFollowing,
    required this.showTopBorder,
  });

  final User user;
  final bool isFollowing;
  final bool showTopBorder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => context.push(
        '/profile/${user.username}',
        extra: ProfileDetailExtra(user: user),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: showTopBorder
                  ? const Color(0xFFF4F4F5)
                  : Colors.transparent,
            ),
          ),
        ),
        child: Row(
          children: [
            ClipOval(
              child: CachedNetworkImage(
                imageUrl: user.profileImageMedium,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  width: 52,
                  height: 52,
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
                  const SizedBox(height: 4),
                  Text(
                    '@${user.username} · ${l10n.photoCount(user.totalPhotos)} · ${l10n.collectionsCount(user.totalCollections)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                        fontSize: 11,
                        color: Color(0xFFA1A1AA),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              constraints: const BoxConstraints(minWidth: 82),
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isFollowing
                    ? const Color(0xFFFAFAFA)
                    : const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isFollowing
                      ? const Color(0xFFE4E4E7)
                      : const Color(0xFF18181B),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                isFollowing ? l10n.following : l10n.follow,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isFollowing
                      ? const Color(0xFF71717A)
                      : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchIdleState extends StatelessWidget {
  const _SearchIdleState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_rounded,
            size: 36,
            color: Color(0xFFA1A1AA),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.startTypingToSearch,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF18181B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.searchIdleSubtitle,
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
