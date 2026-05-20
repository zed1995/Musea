import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/presentation/providers/photos_provider.dart';
import 'package:musea/shared/widgets/loading_indicator.dart';

class PhotoViewerPage extends ConsumerWidget {
  const PhotoViewerPage({
    super.key,
    required this.photoId,
    this.initialPhoto,
    this.heroTag,
  });

  final String photoId;
  final Photo? initialPhoto;
  final String? heroTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoAsync = ref.watch(photoDetailProvider(photoId));
    final resolvedPhoto = photoAsync.valueOrNull ?? initialPhoto;

    if (resolvedPhoto != null) {
      return _PhotoViewerScaffold(
        photo: resolvedPhoto,
        heroTag: heroTag ?? photoId,
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: photoAsync.when(
        data: (photo) => _PhotoViewerScaffold(
          photo: photo,
          heroTag: heroTag ?? photoId,
        ),
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Unable to load photo',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoViewerScaffold extends StatelessWidget {
  const _PhotoViewerScaffold({
    required this.photo,
    required this.heroTag,
  });

  final Photo photo;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                key: const ValueKey('photo-viewer-dismiss-area'),
                behavior: HitTestBehavior.opaque,
                onTap: () => _dismiss(context),
              ),
              Center(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: GestureDetector(
                    key: const ValueKey('photo-viewer-image-tap-target'),
                    behavior: HitTestBehavior.translucent,
                    onTap: () => _dismiss(context),
                    child: Hero(
                      tag: heroTag,
                      child: CachedNetworkImage(
                        imageUrl: photo.urlRegular,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => AspectRatio(
                          aspectRatio: _aspectRatio,
                          child: Container(
                            color: _placeholderColor,
                            child: const Center(child: LoadingIndicator()),
                          ),
                        ),
                        errorWidget: (context, url, error) => AspectRatio(
                          aspectRatio: _aspectRatio,
                          child: Container(
                            color: AppColors.gray200,
                            child: const Icon(
                              Icons.broken_image,
                              size: 48,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double get _aspectRatio {
    if (photo.width <= 0 || photo.height <= 0) {
      return 1;
    }
    return photo.width / photo.height;
  }

  Color get _placeholderColor {
    return Color(int.parse(photo.color.replaceFirst('#', '0xFF')));
  }

  void _dismiss(BuildContext context) {
    Navigator.of(context).pop();
  }
}
