import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/core/theme/text_styles.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/presentation/providers/photos_provider.dart';
import 'package:musea/shared/widgets/loading_indicator.dart';
import 'package:musea/shared/widgets/error_state.dart';
import 'package:musea/features/photo_detail/presentation/widgets/download_sheet.dart';

class PhotoDetailPage extends ConsumerWidget {
  const PhotoDetailPage({super.key, required this.photoId});

  final String photoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoAsync = ref.watch(photoDetailProvider(photoId));

    return photoAsync.when(
      data: (photo) => _PhotoDetailContent(
        photo: photo,
        onDownload: (url) => _triggerDownload(photo, url, ref, context),
      ),
      loading: () => const Scaffold(
        body: Center(child: LoadingIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(),
        body: ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(photoDetailProvider(photoId)),
        ),
      ),
    );
  }

  Future<void> _triggerDownload(
      Photo photo, String url, WidgetRef ref, BuildContext context) async {
    // Track download via Unsplash API (required attribution)
    try {
      final repository = ref.read(photoRepositoryProvider);
      await repository.trackDownload(photo.id);
    } catch (_) {}

    // Download image bytes and save to gallery
    try {
      final dio = Dio(BaseOptions());
      final response = await dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.data != null && context.mounted) {
        await ImageGallerySaver.saveImage(
          Uint8List.fromList(response.data!),
          name: 'musea_${photo.id}',
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image saved to gallery')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }
}

class _PhotoDetailContent extends StatelessWidget {
  const _PhotoDetailContent({
    required this.photo,
    required this.onDownload,
  });

  final Photo photo;
  final void Function(String url) onDownload;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          _buildHeroImage(context),
          SliverToBoxAdapter(child: _buildInfoSection(context)),
          if (photo.exif != null) SliverToBoxAdapter(child: _buildExifSection()),
          if (photo.location != null) SliverToBoxAdapter(child: _buildLocationSection()),
          if (photo.tags.isNotEmpty) SliverToBoxAdapter(child: _buildTagsSection(context)),
          _buildBottomPadding(),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 0,
      pinned: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.download_outlined),
          onPressed: () async {
            final option = await DownloadSheet.show(context, photo);
            if (option != null && context.mounted) {
              onDownload(option.url);
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildHeroImage(BuildContext context) {
    return SliverToBoxAdapter(
      child: Hero(
        tag: photo.id,
        child: GestureDetector(
          onTap: () => _openFullScreen(context),
          child: CachedNetworkImage(
            imageUrl: photo.urlRegular,
            fit: BoxFit.contain,
            width: double.infinity,
            placeholder: (context, url) => Container(
              height: 300,
              color: Color(int.parse(photo.color.replaceFirst('#', '0xFF'))),
              child: const Center(child: LoadingIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              height: 300,
              color: AppColors.gray200,
              child: const Icon(Icons.broken_image, size: 48),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => context.push('/profile/${photo.user.username}'),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: CachedNetworkImageProvider(
                    photo.user.profileImageMedium,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(photo.user.name, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                    if (photo.user.bio != null && photo.user.bio!.isNotEmpty)
                      Text(photo.user.bio!, style: AppTextStyles.caption),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.favorite, size: 16, color: AppColors.gray600),
              const SizedBox(width: 4),
              Text('${photo.likes}', style: AppTextStyles.bodyMedium),
              const SizedBox(width: 24),
              const Icon(Icons.download, size: 16, color: AppColors.gray600),
              const SizedBox(width: 4),
              Text('${photo.downloads}', style: AppTextStyles.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExifSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Camera Info', style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _exifRow(Icons.camera_alt_outlined, 'Camera',
                    _join(photo.exif!.make, photo.exif!.model)),
                _exifRow(Icons.timer_outlined, 'Shutter', photo.exif!.exposureTime),
                _exifRow(Icons.blur_on, 'Aperture', photo.exif!.aperture),
                _exifRow(Icons.adjust, 'ISO', photo.exif!.iso?.toString()),
                _exifRow(Icons.straighten, 'Focal', photo.exif!.focalLength),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _join(String? a, String? b) {
    if (a == null && b == null) return null;
    return [a, b].where((x) => x != null && x.isNotEmpty).join(' ');
  }

  Widget _exifRow(IconData icon, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.gray500),
          const SizedBox(width: 12),
          Text('$label  ', style: AppTextStyles.bodySmall),
          Expanded(
            child: Text(value, style: AppTextStyles.bodyMedium, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Location', style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.gray500),
              const SizedBox(width: 8),
              Text(photo.location!.displayName, style: AppTextStyles.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tags', style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: photo.tags.map((tag) {
              return ActionChip(
                label: Text(tag.title, style: AppTextStyles.bodySmall),
                onPressed: () {},
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPadding() {
    return const SliverToBoxAdapter(child: SizedBox(height: 32));
  }

  void _openFullScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenImage(photo: photo),
      ),
    );
  }
}

class _FullScreenImage extends StatelessWidget {
  const _FullScreenImage({required this.photo});

  final Photo photo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Hero(
          tag: '${photo.id}_full',
          child: InteractiveViewer(
            child: CachedNetworkImage(
              imageUrl: photo.urlFull,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.white)),
              errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white54),
            ),
          ),
        ),
      ),
    );
  }
}
