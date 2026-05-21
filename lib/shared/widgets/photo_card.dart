import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/presentation/providers/photo_like_provider.dart';

class PhotoCard extends ConsumerWidget {
  static const Color _likedColor = Color(0xFFE11D48);

  const PhotoCard({
    super.key,
    required this.photo,
    this.onPhotoTap,
    this.onUserTap,
    this.onLikeTap,
    this.onBookmarkTap,
  });

  final Photo photo;
  final VoidCallback? onPhotoTap;
  final VoidCallback? onUserTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onBookmarkTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likeState = ref.watch(photoLikeStateProvider(photo));

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: GestureDetector(
          onTap: onPhotoTap,
          child: Stack(
            children: [
              Hero(
                tag: photo.id,
                child: _buildPhoto(),
              ),
              _buildBottomOverlay(likeState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto() {
    double aspectRatio = photo.width / photo.height;
    if (aspectRatio > 0 &&
        aspectRatio < 1 &&
        (photo.height / photo.width) > 3) {
      aspectRatio = 0.6;
    }
    if (aspectRatio <= 0) aspectRatio = 1.5;

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: photo.blurHash != null
          ? CachedNetworkImage(
              imageUrl: photo.urlRegular,
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder: (context, url) => BlurHash(hash: photo.blurHash!),
              errorWidget: (context, url, error) => Container(
                color: Color(int.parse(photo.color.replaceFirst('#', '0xFF'))),
                child: const Icon(Icons.broken_image, color: Colors.white54),
              ),
            )
          : CachedNetworkImage(
              imageUrl: photo.urlSmall,
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder: (context, url) => Container(
                color: Color(int.parse(photo.color.replaceFirst('#', '0xFF'))),
                child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (context, url, error) => Container(
                color: AppColors.gray200,
                child: const Icon(Icons.broken_image),
              ),
            ),
    );
  }

  Widget _buildBottomOverlay(PhotoLikeState likeState) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 46, 12, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.50),
              Colors.black.withValues(alpha: 0.22),
              Colors.black.withValues(alpha: 0.03),
              Colors.transparent,
            ],
            stops: const [0.0, 0.35, 0.72, 1.0],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onUserTap,
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.22),
                            blurRadius: 5,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 13,
                        backgroundImage: CachedNetworkImageProvider(
                          photo.user.profileImageMedium,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        photo.user.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Row(
              children: [
                _OverlayPillButton(
                  icon: likeState.likedByUser
                      ? Icons.favorite
                      : Icons.favorite_border,
                  label: _formatCount(likeState.likes),
                  onTap: onLikeTap,
                  iconColor: likeState.likedByUser ? _likedColor : Colors.white,
                  labelColor:
                      likeState.likedByUser ? _likedColor : Colors.white,
                ),
                const SizedBox(width: 6),
                _OverlayPillButton(
                  icon: Icons.bookmark_border,
                  onTap: onBookmarkTap,
                  isIconOnly: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}

class _OverlayPillButton extends StatelessWidget {
  const _OverlayPillButton({
    required this.icon,
    this.label,
    this.onTap,
    this.isIconOnly = false,
    this.iconColor = Colors.white,
    this.labelColor = Colors.white,
  });

  final IconData icon;
  final String? label;
  final VoidCallback? onTap;
  final bool isIconOnly;
  final Color iconColor;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      height: 28,
      constraints: BoxConstraints(minWidth: isIconOnly ? 28 : 0),
      padding: EdgeInsets.symmetric(horizontal: isIconOnly ? 0 : 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: iconColor),
          if (!isIconOnly && label != null) ...[
            const SizedBox(width: 2),
            Text(
              label!,
              style: TextStyle(
                color: labelColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: child,
    );
  }
}
