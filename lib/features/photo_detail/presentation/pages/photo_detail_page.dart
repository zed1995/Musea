import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:gal/gal.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/presentation/providers/photos_provider.dart';
import 'package:musea/features/profile/presentation/providers/profile_provider.dart';
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
    try {
      final repository = ref.read(photoRepositoryProvider);
      await repository.trackDownload(photo.id);
    } catch (_) {}

    try {
      final dio = Dio(BaseOptions());
      final response = await dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.data != null && context.mounted) {
        await Gal.putImageBytes(
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

class _PhotoDetailContent extends ConsumerWidget {
  const _PhotoDetailContent({
    required this.photo,
    required this.onDownload,
  });

  final Photo photo;
  final void Function(String url) onDownload;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _PhotoHero(photo: photo),
          SliverToBoxAdapter(child: _buildContent(context, ref)),
          // More from photographer
          SliverToBoxAdapter(
            child: _buildMoreFromPhotographer(context, ref),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildUserRow(context),
          const SizedBox(height: 16),
          _buildStatsRow(),
          if (_description != null) ...[
            const SizedBox(height: 16),
            _buildDescription(),
          ],
          if (photo.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildTags(),
          ],
          if (photo.exif != null) ...[
            const SizedBox(height: 20),
            _buildExifGrid(),
          ],
          const SizedBox(height: 20),
          _buildActionButtons(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Photo Hero ──

  Widget _buildUserRow(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.push('/profile/${photo.user.username}'),
          child: CircleAvatar(
            radius: 20,
            backgroundImage: CachedNetworkImageProvider(
              photo.user.profileImageMedium,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                photo.user.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF18181B),
                ),
              ),
              Text(
                '@${photo.user.username}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFA1A1AA),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF18181B),
            borderRadius: BorderRadius.circular(100),
          ),
          child: const Text(
            'Follow',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _statItem(Icons.favorite, _formatCount(photo.likes)),
        const SizedBox(width: 20),
        _statItem(Icons.visibility, _formatCount(photo.views ?? 0)),
        const SizedBox(width: 20),
        _statItem(Icons.download, _formatCount(photo.downloads)),
      ],
    );
  }

  Widget _statItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF71717A)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF3F3F46),
          ),
        ),
      ],
    );
  }

  String? get _description =>
      photo.description ?? photo.altDescription;

  Widget _buildDescription() {
    return Text(
      _description!,
      style: const TextStyle(
        fontSize: 14,
        height: 1.5,
        color: Color(0xFF52525B),
      ),
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: photo.tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            tag.title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF52525B),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── EXIF Grid ──

  Widget _buildExifGrid() {
    final exif = photo.exif!;
    final items = <_ExifItem>[];

    final camera = _join(exif.make, exif.model);
    if (camera != null) items.add(_ExifItem('Camera', camera));
    if (exif.aperture != null) items.add(_ExifItem('Aperture', exif.aperture!));
    if (exif.exposureTime != null) items.add(_ExifItem('Shutter', exif.exposureTime!));
    if (exif.iso != null) items.add(_ExifItem('ISO', exif.iso.toString()));
    if (exif.focalLength != null) items.add(_ExifItem('Focal', exif.focalLength!));

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Camera Info',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFFA1A1AA),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        _ExifGrid(items: items),
      ],
    );
  }

  String? _join(String? a, String? b) {
    if (a == null && b == null) return null;
    return [a, b].where((x) => x != null && x.isNotEmpty).join(' ');
  }

  // ── Action Buttons ──

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final option = await DownloadSheet.show(context, photo);
              if (option != null && context.mounted) {
                onDownload(option.url);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download, size: 20, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Download Free',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE4E4E7)),
            color: Colors.white,
          ),
          child: const Icon(Icons.favorite_border, size: 20, color: Color(0xFF3F3F46)),
        ),
      ],
    );
  }

  // ── More from Photographer ──

  Widget _buildMoreFromPhotographer(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'More from photographer',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF18181B),
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/profile/${photo.user.username}'),
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFA1A1AA),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Consumer(
            builder: (context, ref, _) {
              final photosAsync = ref.watch(userPhotosProvider(photo.user.username));
              return photosAsync.when(
                data: (photos) {
                  final displayPhotos = photos.take(10).toList();
                  if (displayPhotos.isEmpty) return const SizedBox.shrink();
                  return SizedBox(
                    height: 84,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: displayPhotos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final p = displayPhotos[index];
                        return GestureDetector(
                          onTap: () {
                            context.push('/photo/${p.id}');
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: p.urlSmall,
                              width: 84,
                              height: 84,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                width: 84,
                                height: 84,
                                color: AppColors.gray200,
                                child: const Icon(Icons.broken_image, size: 24),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const SizedBox(
                  height: 84,
                  child: Center(child: LoadingIndicator()),
                ),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),
        ],
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

// ── Photo Hero ──

class _PhotoHero extends StatelessWidget {
  const _PhotoHero({required this.photo});

  final Photo photo;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Stack(
        children: [
          Hero(
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
          // Gradient overlay top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _IconButton(
                      icon: Icons.arrow_back,
                      onTap: () => context.pop(),
                    ),
                    Row(
                      children: [
                        _IconButton(icon: Icons.bookmark_border, onTap: () {}),
                        const SizedBox(width: 8),
                        _IconButton(icon: Icons.ios_share, onTap: () {}),
                        const SizedBox(width: 8),
                        _IconButton(icon: Icons.more_vert, onTap: () {}),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openFullScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenImage(photo: photo),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// ── EXIF Grid ──

class _ExifItem {
  final String label;
  final String value;
  const _ExifItem(this.label, this.value);
}

class _ExifGrid extends StatelessWidget {
  const _ExifGrid({required this.items});

  final List<_ExifItem> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items.map((item) => _ExifCell(item)).toList(),
    );
  }
}

class _ExifCell extends StatelessWidget {
  const _ExifCell(this.item);

  final _ExifItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            item.label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFFA1A1AA),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            item.value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF52525B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Full Screen Image ──

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
              placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator(color: Colors.white)),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.broken_image, color: Colors.white54),
            ),
          ),
        ),
      ),
    );
  }
}
