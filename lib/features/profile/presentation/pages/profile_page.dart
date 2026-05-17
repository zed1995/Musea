import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/core/theme/text_styles.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/features/profile/presentation/providers/profile_provider.dart';
import 'package:musea/shared/widgets/loading_indicator.dart';
import 'package:musea/shared/widgets/error_state.dart';
import 'package:musea/shared/widgets/photo_card.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key, required this.username});

  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider(username));
    final photosAsync = ref.watch(userPhotosProvider(username));

    return userAsync.when(
      data: (user) => _ProfileContent(user: user, photosAsync: photosAsync),
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

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.user, required this.photosAsync});

  final User user;
  final AsyncValue<List<Photo>> photosAsync;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.gray100,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Spacer(),
                    CircleAvatar(
                      radius: 48,
                      backgroundImage: CachedNetworkImageProvider(
                        user.profileImageLarge,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(user.name, style: AppTextStyles.heading2),
                    if (user.bio != null && user.bio!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
                        child: Text(
                          user.bio!,
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray600),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _statItem('${user.totalPhotos}', 'Photos'),
                        const SizedBox(width: 24),
                        _statItem('${user.totalLikes}', 'Likes'),
                        const SizedBox(width: 24),
                        _statItem('${user.totalCollections}', 'Collections'),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          photosAsync.when(
            data: (photos) {
              if (photos.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('No photos yet', style: AppTextStyles.bodyMedium)),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => PhotoCard(photo: photos[index]),
                    childCount: photos.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: LoadingIndicator()),
            ),
            error: (error, stack) => SliverFillRemaining(
              child: ErrorState(
                message: error.toString(),
                onRetry: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
