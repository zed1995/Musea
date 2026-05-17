import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';

class PhotoCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GestureDetector(
          onTap: onPhotoTap,
          child: Stack(
            children: [
              _buildPhoto(),
              _buildBottomOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto() {
    double aspectRatio = photo.width / photo.height;
    if (aspectRatio > 0 && aspectRatio < 1 && (photo.height / photo.width) > 3) {
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
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (context, url, error) => Container(
                color: AppColors.gray200,
                child: const Icon(Icons.broken_image),
              ),
            ),
    );
  }

  Widget _buildBottomOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 24, 14, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.55),
              Colors.black.withValues(alpha: 0.45),
              Colors.black.withValues(alpha: 0.30),
              Colors.black.withValues(alpha: 0.18),
              Colors.black.withValues(alpha: 0.06),
              Colors.black.withValues(alpha: 0.01),
              Colors.transparent,
            ],
            stops: const [0.0, 0.1, 0.3, 0.5, 0.68, 0.85, 1.0],
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onUserTap,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.7),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundImage: CachedNetworkImageProvider(
                        photo.user.profileImageMedium,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    photo.user.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Spacer(),
            Row(
              children: [
                GestureDetector(
                  onTap: onLikeTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite, size: 16, color: Colors.white),
                        const SizedBox(width: 2),
                        Text(
                          _formatCount(photo.likes),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onBookmarkTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: const Icon(Icons.bookmark_border, size: 16, color: Colors.white),
                  ),
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
