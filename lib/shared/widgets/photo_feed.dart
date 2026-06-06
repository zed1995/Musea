import 'package:flutter/material.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/l10n/generated/app_localizations.dart';
import 'package:musea/shared/widgets/empty_state.dart';
import 'package:musea/shared/widgets/loading_indicator.dart';
import 'package:musea/shared/widgets/photo_card.dart';

class PhotoFeed extends StatelessWidget {
  const PhotoFeed({
    super.key,
    required this.photos,
    this.isLoadingMore = false,
    this.onPhotoTap,
    this.onUserTap,
    this.onLikeTap,
    this.onBookmarkTap,
  });

  final List<Photo> photos;
  final bool isLoadingMore;
  final void Function(Photo photo)? onPhotoTap;
  final void Function(Photo photo)? onUserTap;
  final void Function(Photo photo)? onLikeTap;
  final void Function(Photo photo)? onBookmarkTap;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty && !isLoadingMore) {
      return SliverFillRemaining(
        child: EmptyState(
          icon: Icons.photo_library_outlined,
          title: AppLocalizations.of(context)!.noPhotos,
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
              onBookmarkTap: onBookmarkTap != null ? () => onBookmarkTap!(photo) : null,
            );
          },
          childCount: photos.length + (isLoadingMore ? 1 : 0),
        ),
      ),
    );
  }
}
