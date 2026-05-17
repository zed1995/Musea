import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/core/theme/text_styles.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';

class PhotoCard extends StatelessWidget {
  const PhotoCard({
    super.key,
    required this.photo,
    this.onPhotoTap,
    this.onUserTap,
    this.onLikeTap,
    this.onDownloadTap,
    this.showDownloadButton = true,
  });

  final Photo photo;
  final VoidCallback? onPhotoTap;
  final VoidCallback? onUserTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onDownloadTap;
  final bool showDownloadButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              imageUrl: photo.urlRegular,
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.6),
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            GestureDetector(
              onTap: onUserTap,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: CachedNetworkImageProvider(
                      photo.user.profileImageSmall,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    photo.user.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Row(
              children: [
                GestureDetector(
                  onTap: onLikeTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite, size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        _formatCount(photo.likes),
                        style: AppTextStyles.caption.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                if (showDownloadButton) ...[
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: onDownloadTap,
                    child: const Icon(Icons.download, size: 16, color: Colors.white),
                  ),
                ],
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
