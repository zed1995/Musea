import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/core/theme/text_styles.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/features/profile/presentation/providers/profile_provider.dart';
import 'package:musea/shared/widgets/error_state.dart';
import 'package:musea/shared/widgets/loading_indicator.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key, required this.username});

  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider(username));
    final photosAsync = ref.watch(userPhotosProvider(username));
    final collectionsAsync = ref.watch(userCollectionsProvider(username));
    final likesAsync = ref.watch(userLikesProvider(username));

    return userAsync.when(
      data: (user) => _ProfileContent(
        user: user,
        photosAsync: photosAsync,
        collectionsAsync: collectionsAsync,
        likesAsync: likesAsync,
      ),
      loading: () => const Scaffold(
        body: Center(child: LoadingIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(),
        body: ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(userProfileProvider(username)),
        ),
      ),
    );
  }
}

class _ProfileContent extends StatefulWidget {
  const _ProfileContent({
    required this.user,
    required this.photosAsync,
    required this.collectionsAsync,
    required this.likesAsync,
  });

  final User user;
  final AsyncValue<List<Photo>> photosAsync;
  final AsyncValue<List<Collection>> collectionsAsync;
  final AsyncValue<List<Photo>> likesAsync;

  @override
  State<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<_ProfileContent> {
  _ProfileSegment _selectedSegment = _ProfileSegment.photos;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
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
        return _PhotosSection(photosAsync: widget.photosAsync);
      case _ProfileSegment.collections:
        return _CollectionsSection(collectionsAsync: widget.collectionsAsync);
      case _ProfileSegment.likes:
        return _LikesSection(likesAsync: widget.likesAsync);
    }
  }
}

class _CollectionsSection extends StatelessWidget {
  const _CollectionsSection({required this.collectionsAsync});

  final AsyncValue<List<Collection>> collectionsAsync;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          eyebrow: 'Collections',
          title: 'Curated groupings',
          actionLabel: 'See all',
        ),
        const SizedBox(height: 12),
        collectionsAsync.when(
          data: (collections) {
            if (collections.isEmpty) {
              return const _SectionEmptyCard(
                message: 'No public collections yet',
              );
            }

            return Column(
              children: collections.take(4).map((collection) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ProfileCollectionCard(collection: collection),
                );
              }).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: LoadingIndicator(),
            ),
          ),
          error: (error, stack) => Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ErrorState(
              message: error.toString(),
              onRetry: () {},
            ),
          ),
        ),
      ],
    );
  }
}

class _LikesSection extends StatelessWidget {
  const _LikesSection({required this.likesAsync});

  final AsyncValue<List<Photo>> likesAsync;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          eyebrow: 'Likes',
          title: 'Saved inspiration',
          actionLabel: 'See all',
        ),
        const SizedBox(height: 12),
        likesAsync.when(
          data: (photos) {
            if (photos.isEmpty) {
              return const _SectionEmptyCard(
                message: 'No liked photos yet',
              );
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: photos.length.clamp(0, 6),
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: CachedNetworkImage(
                      imageUrl: photo.urlSmall,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.gray100,
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: LoadingIndicator(),
            ),
          ),
          error: (error, stack) => Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ErrorState(
              message: error.toString(),
              onRetry: () {},
            ),
          ),
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
                    icon: Icons.arrow_back_ios_new_rounded,
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
                    'Follow',
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
                      label: 'Photos',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricCard(
                      value: '${user.totalCollections}',
                      label: 'Collections',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricCard(
                      value: _formatCount(user.totalLikes),
                      label: 'Likes',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${_formatCount(user.totalLikes)} likes received',
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

class _PhotosSection extends StatelessWidget {
  const _PhotosSection({required this.photosAsync});

  final AsyncValue<List<Photo>> photosAsync;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          eyebrow: 'Public Work',
          title: 'Latest uploads',
          actionLabel: 'Newest first',
        ),
        const SizedBox(height: 12),
        photosAsync.when(
          data: (photos) {
            if (photos.isEmpty) {
              return const _SectionEmptyCard(
                message: 'No public photos yet',
              );
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: photos.length.clamp(0, 6),
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: CachedNetworkImage(
                      imageUrl: photo.urlSmall,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.gray100,
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: LoadingIndicator(),
            ),
          ),
          error: (error, stack) => Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ErrorState(
              message: error.toString(),
              onRetry: () {},
            ),
          ),
        ),
      ],
    );
  }
}

class _PlaceholderSection extends StatelessWidget {
  const _PlaceholderSection({
    required this.eyebrow,
    required this.title,
    required this.message,
  });

  final String eyebrow;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          eyebrow: eyebrow,
          title: title,
          actionLabel: 'See all',
        ),
        const SizedBox(height: 12),
        _SectionEmptyCard(message: message),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
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
              eyebrow,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.gray400,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Text(
          actionLabel,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.gray500,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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

class _ProfileCollectionCard extends StatelessWidget {
  const _ProfileCollectionCard({required this.collection});

  final Collection collection;

  @override
  Widget build(BuildContext context) {
    final coverUrl = collection.coverPhoto?.urlRegular ??
        (collection.previewPhotos.isNotEmpty
            ? collection.previewPhotos.first.smallUrl
            : null);

    return GestureDetector(
      onTap: () => context.push('/collection/${collection.id}'),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            SizedBox(
              height: 176,
              width: double.infinity,
              child: coverUrl == null
                  ? Container(color: AppColors.gray100)
                  : CachedNetworkImage(
                      imageUrl: coverUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.gray100,
                      ),
                    ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.04),
                      Colors.black.withValues(alpha: 0.56),
                    ],
                    stops: const [0.26, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collection.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${collection.totalPhotos} ${collection.totalPhotos == 1 ? 'photo' : 'photos'}',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: 'Photos',
              selected: selectedSegment == _ProfileSegment.photos,
              onTap: () => onSelected(_ProfileSegment.photos),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: 'Collections',
              selected: selectedSegment == _ProfileSegment.collections,
              onTap: () => onSelected(_ProfileSegment.collections),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: 'Likes',
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
