import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/core/theme/text_styles.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/presentation/providers/photo_like_provider.dart';
import 'package:musea/router/detail_route_extras.dart';

const _likedColor = Color(0xFFE11D48);

class PhotoGrid extends StatelessWidget {
  const PhotoGrid({
    super.key,
    required this.photos,
    this.showLikes = false,
    this.padding = EdgeInsets.zero,
    this.physics = const NeverScrollableScrollPhysics(),
    this.shrinkWrap = true,
  });

  final List<Photo> photos;
  final bool showLikes;
  final EdgeInsets padding;
  final ScrollPhysics physics;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: photos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) => PhotoGridTile(
        photo: photos[index],
        showLikes: showLikes,
      ),
    );
  }
}

class PhotoGridTile extends ConsumerWidget {
  const PhotoGridTile({
    super.key,
    required this.photo,
    this.showLikes = false,
  });

  final Photo photo;
  final bool showLikes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likeState = ref.watch(photoLikeStateProvider(photo));

    return GestureDetector(
      onTap: () => context.push(
        '/photo/${photo.id}',
        extra: PhotoDetailExtra(photo: photo),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: photo.urlSmall,
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
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.18),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Row(
                children: [
                  ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: photo.user.profileImageMedium,
                      width: 20,
                      height: 20,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        width: 20,
                        height: 20,
                        color: Colors.white24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      photo.user.name,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (showLikes) ...[
                    const SizedBox(width: 8),
                    Icon(
                      likeState.likedByUser
                          ? Icons.favorite
                          : Icons.favorite_border_rounded,
                      size: 16,
                      color: likeState.likedByUser ? _likedColor : Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatLikes(likeState.likes),
                      style: AppTextStyles.caption.copyWith(
                        color:
                            likeState.likedByUser ? _likedColor : Colors.white,
                        fontWeight: FontWeight.w700,
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
}

String _formatLikes(int likes) {
  if (likes >= 1000) {
    final rounded = (likes / 1000).toStringAsFixed(likes >= 10000 ? 0 : 1);
    return '${rounded.replaceAll('.0', '')}k';
  }
  return '$likes';
}
