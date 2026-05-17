import 'package:flutter/material.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/shared/widgets/photo_card.dart';
import 'package:musea/shared/widgets/empty_state.dart';
import 'package:musea/shared/widgets/loading_indicator.dart';

class PhotoFeed extends StatelessWidget {
  const PhotoFeed({
    super.key,
    required this.photos,
    this.isLoadingMore = false,
    this.onPhotoTap,
    this.onUserTap,
    this.onLikeTap,
    this.onDownloadTap,
    this.showDownloadButton = true,
  });

  final List<Photo> photos;
  final bool isLoadingMore;
  final void Function(Photo photo)? onPhotoTap;
  final void Function(Photo photo)? onUserTap;
  final void Function(Photo photo)? onLikeTap;
  final void Function(Photo photo)? onDownloadTap;
  final bool showDownloadButton;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty && !isLoadingMore) {
      return const SliverFillRemaining(
        child: EmptyState(
          icon: Icons.photo_library_outlined,
          title: 'No photos',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index >= photos.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: LoadingIndicator()),
              );
            }
            final photo = photos[index];
            return PhotoCard(
              photo: photo,
              onPhotoTap: onPhotoTap != null ? () => onPhotoTap!(photo) : null,
              onUserTap: onUserTap != null ? () => onUserTap!(photo) : null,
              onLikeTap: onLikeTap != null ? () => onLikeTap!(photo) : null,
              onDownloadTap: onDownloadTap != null ? () => onDownloadTap!(photo) : null,
              showDownloadButton: showDownloadButton,
            );
          },
          childCount: photos.length + (isLoadingMore ? 1 : 0),
        ),
      ),
    );
  }
}
