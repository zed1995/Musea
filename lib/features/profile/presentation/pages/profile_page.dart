import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/core/theme/text_styles.dart';
import 'package:musea/l10n/generated/app_localizations.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/features/profile/presentation/providers/profile_controller.dart';
import 'package:musea/features/profile/presentation/providers/profile_provider.dart';
import 'package:musea/features/search/presentation/providers/search_controller.dart';
import 'package:musea/shared/widgets/collection_card.dart';
import 'package:musea/shared/widgets/error_state.dart';
import 'package:musea/shared/widgets/loading_indicator.dart';
import 'package:musea/shared/widgets/photo_grid.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({
    super.key,
    required this.username,
    this.initialUser,
  });

  final String username;
  final User? initialUser;

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(userPhotosControllerProvider(widget.username).notifier)
          .loadInitial();
      ref
          .read(userCollectionsControllerProvider(widget.username).notifier)
          .loadInitial();
      ref
          .read(userLikesControllerProvider(widget.username).notifier)
          .loadInitial();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileProvider(widget.username));
    final resolvedUser = userAsync.valueOrNull ?? widget.initialUser;

    if (resolvedUser != null) {
      return _ProfileContent(
        username: widget.username,
        user: resolvedUser,
      );
    }

    return userAsync.when(
      data: (_) => const SizedBox.shrink(),
      loading: () => const Scaffold(
        body: Center(child: LoadingIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(),
        body: ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(userProfileProvider(widget.username)),
        ),
      ),
    );
  }
}

class _ProfileContent extends ConsumerStatefulWidget {
  const _ProfileContent({
    required this.username,
    required this.user,
  });

  final String username;
  final User user;

  @override
  ConsumerState<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends ConsumerState<_ProfileContent> {
  _ProfileSegment _selectedSegment = _ProfileSegment.photos;
  final ScrollController _scrollController = ScrollController();

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
      switch (_selectedSegment) {
        case _ProfileSegment.photos:
          ref
              .read(userPhotosControllerProvider(widget.username).notifier)
              .loadMore();
        case _ProfileSegment.collections:
          ref
              .read(userCollectionsControllerProvider(widget.username).notifier)
              .loadMore();
        case _ProfileSegment.likes:
          ref
              .read(userLikesControllerProvider(widget.username).notifier)
              .loadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: _ProfileHero(
              user: user,
              onBack: () => context.pop(),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SegmentHeaderDelegate(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: _ProfileSegmentBar(
                  selectedSegment: _selectedSegment,
                  onSelected: (segment) {
                    setState(() => _selectedSegment = segment);
                  },
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              child: _buildSelectedSection(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedSection() {
    switch (_selectedSegment) {
      case _ProfileSegment.photos:
        final state = ref.watch(userPhotosControllerProvider(widget.username));
        return _PaginatedPhotoSection(state: state);
      case _ProfileSegment.collections:
        final state =
            ref.watch(userCollectionsControllerProvider(widget.username));
        return _PaginatedCollectionSection(state: state);
      case _ProfileSegment.likes:
        final state = ref.watch(userLikesControllerProvider(widget.username));
        return _PaginatedPhotoSection(state: state, showLikes: true);
    }
  }
}

class _PaginatedPhotoSection extends StatelessWidget {
  const _PaginatedPhotoSection({required this.state, this.showLikes = false});

  final PaginatedState<Photo> state;
  final bool showLikes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: LoadingIndicator()),
      );
    }
    if (state.items.isEmpty && state.error != null) {
      return ErrorState(
        message: state.error.toString(),
      );
    }
    if (state.items.isEmpty && state.error == null) {
      return _SectionEmptyCard(message: l10n.noPublicPhotosYet);
    }

    return Column(
      children: [
        PhotoGrid(photos: state.items, showLikes: showLikes),
        if (state.isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: LoadingIndicator(),
          ),
      ],
    );
  }
}

class _PaginatedCollectionSection extends StatelessWidget {
  const _PaginatedCollectionSection({required this.state});

  final PaginatedState<Collection> state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: LoadingIndicator()),
      );
    }
    if (state.items.isEmpty && state.error != null) {
      return ErrorState(
        message: state.error.toString(),
      );
    }
    if (state.items.isEmpty && state.error == null) {
      return _SectionEmptyCard(message: l10n.noPublicCollectionsYet);
    }

    return Column(
      children: [
        ...state.items.map((collection) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CollectionCard(collection: collection),
            )),
        if (state.isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: LoadingIndicator(),
          ),
      ],
    );
  }
}

enum _ProfileSegment { photos, collections, likes }

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.user,
    required this.onBack,
  });

  final User user;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locationLine = [user.username, user.location]
        .where((value) => value != null && value.trim().isNotEmpty)
        .map((value) => value == user.username ? '@$value' : value!)
        .join(' · ');

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFCFCFD),
            Color(0xFFF6F6F8),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F1F2)),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CircleActionButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: onBack,
                  ),
                  _CircleActionButton(
                    icon: Icons.ios_share_rounded,
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _AvatarImage(
                imageUrl: _bestProfileImage(user),
                size: 84,
              ),
              const SizedBox(height: 16),
              Text(
                user.name,
                textAlign: TextAlign.center,
                style: AppTextStyles.heading1.copyWith(
                  fontSize: 28,
                  height: 1,
                  letterSpacing: -1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (locationLine.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  locationLine,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.gray500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if ((user.bio ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Text(
                    user.bio!,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.gray600,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: 152,
                height: 42,
                child: FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gray900,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    l10n.follow,
                    style: AppTextStyles.button.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      value: '${user.totalPhotos}',
                      label: l10n.photos,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricCard(
                      value: '${user.totalCollections}',
                      label: l10n.collections,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricCard(
                      value: _formatCount(user.totalLikes),
                      label: l10n.likes,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l10n.likesReceived(user.totalLikes),
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.gray500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionEmptyCard extends StatelessWidget {
  const _SectionEmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Text(
        message,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.gray600,
        ),
      ),
    );
  }
}

class _ProfileSegmentBar extends StatelessWidget {
  const _ProfileSegmentBar({
    required this.selectedSegment,
    required this.onSelected,
  });

  final _ProfileSegment selectedSegment;
  final ValueChanged<_ProfileSegment> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: l10n.photos,
              selected: selectedSegment == _ProfileSegment.photos,
              onTap: () => onSelected(_ProfileSegment.photos),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: l10n.collections,
              selected: selectedSegment == _ProfileSegment.collections,
              onTap: () => onSelected(_ProfileSegment.collections),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: l10n.likes,
              selected: selectedSegment == _ProfileSegment.likes,
              onTap: () => onSelected(_ProfileSegment.likes),
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
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: selected ? AppColors.gray900 : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: selected ? Colors.white : AppColors.gray500,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF4F4F5)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.gray400,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: const BorderSide(color: Color(0xFFE4E4E7)),
          backgroundColor: Colors.white,
          shape: const CircleBorder(),
        ),
        child: Icon(
          icon,
          size: 18,
          color: AppColors.gray700,
        ),
      ),
    );
  }
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({
    required this.imageUrl,
    required this.size,
  });

  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) => Container(
          width: size,
          height: size,
          color: AppColors.gray200,
          alignment: Alignment.center,
          child: Text(
            '?',
            style: AppTextStyles.heading3.copyWith(color: AppColors.gray600),
          ),
        ),
      ),
    );
  }
}

class _SegmentHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _SegmentHeaderDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 58;

  @override
  double get maxExtent => 58;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _SegmentHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

String _bestProfileImage(User user) {
  if (user.profileImageLarge.isNotEmpty) return user.profileImageLarge;
  if (user.profileImageMedium.isNotEmpty) return user.profileImageMedium;
  return user.profileImageSmall;
}

String _formatCount(int value) {
  if (value >= 1000000) {
    final compact =
        (value / 1000000).toStringAsFixed(value % 1000000 == 0 ? 0 : 1);
    return '${compact}m';
  }
  if (value >= 1000) {
    final compact = (value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1);
    return '${compact}k';
  }
  return '$value';
}
