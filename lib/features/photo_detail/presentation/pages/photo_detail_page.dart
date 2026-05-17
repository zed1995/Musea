import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/presentation/providers/photos_provider.dart';
import 'package:musea/features/photo_detail/presentation/widgets/download_sheet.dart';
import 'package:musea/features/profile/presentation/providers/profile_provider.dart';
import 'package:musea/shared/widgets/error_state.dart';
import 'package:musea/shared/widgets/loading_indicator.dart';

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
    Photo photo,
    String url,
    WidgetRef ref,
    BuildContext context,
  ) async {
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
          SliverToBoxAdapter(child: _PhotoHero(photo: photo)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _UserRow(photo: photo),
                  const SizedBox(height: 16),
                  _StatsStrip(photo: photo),
                  if (_description case final description?) ...[
                    const SizedBox(height: 16),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.55,
                        color: Color(0xFF52525B),
                      ),
                    ),
                  ],
                  if (photo.tags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: photo.tags
                          .map((tag) => _TagChip(label: tag.title))
                          .toList(),
                    ),
                  ],
                  if (_exifItems.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const _SectionDivider(),
                    const SizedBox(height: 18),
                    const Text(
                      'CAMERA INFO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF71717A),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ExifGrid(items: _exifItems),
                  ],
                  const SizedBox(height: 18),
                  _DownloadButton(
                    onTap: () async {
                      final option = await DownloadSheet.show(context, photo);
                      if (option != null && context.mounted) {
                        onDownload(option.url);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: _MoreFromPhotographer(photo: photo)),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  String? get _description => photo.description ?? photo.altDescription;

  List<_ExifItem> get _exifItems {
    final exif = photo.exif;
    if (exif == null) return const [];

    final items = <_ExifItem>[];
    final camera = _join(exif.make, exif.model);
    if (camera != null) {
      items.add(_ExifItem('Camera', camera));
    }
    if (exif.aperture != null) {
      items.add(_ExifItem('Aperture', exif.aperture!));
    }
    if (exif.exposureTime != null) {
      items.add(_ExifItem('Shutter', exif.exposureTime!));
    }
    if (exif.iso != null) {
      items.add(_ExifItem('ISO', exif.iso.toString()));
    }
    if (exif.focalLength != null) {
      items.add(_ExifItem('Focal', exif.focalLength!));
    }
    return items;
  }

  String? _join(String? a, String? b) {
    if (a == null && b == null) return null;
    return [a, b].where((x) => x != null && x.isNotEmpty).join(' ');
  }
}

class _PhotoHero extends StatelessWidget {
  const _PhotoHero({required this.photo});

  final Photo photo;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Hero(
          tag: photo.id,
          child: CachedNetworkImage(
            imageUrl: photo.urlRegular,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 320,
              color: Color(int.parse(photo.color.replaceFirst('#', '0xFF'))),
              child: const Center(child: LoadingIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              height: 320,
              color: AppColors.gray200,
              child: const Icon(Icons.broken_image, size: 48),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.34),
                  Colors.black.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.72, 1.0],
              ),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 42),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _HeroActionButton(
                  icon: Icons.arrow_back_ios_new,
                  onTap: () => context.pop(),
                ),
                Row(
                  children: const [
                    _HeroActionButton(icon: Icons.bookmark_border),
                    SizedBox(width: 8),
                    _HeroActionButton(icon: Icons.ios_share),
                    SizedBox(width: 8),
                    _HeroActionButton(icon: Icons.more_horiz),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  const _HeroActionButton({
    required this.icon,
    this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.photo});

  final Photo photo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.push('/profile/${photo.user.username}'),
          child: CircleAvatar(
            radius: 17,
            backgroundImage:
                CachedNetworkImageProvider(photo.user.profileImageMedium),
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
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Center(
            child: Text(
              'Follow',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.photo});

  final Photo photo;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFF1F1F1)),
          bottom: BorderSide(color: Color(0xFFF1F1F1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.favorite_border,
              label: _formatCount(photo.likes),
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: _StatItem(
              icon: Icons.remove_red_eye_outlined,
              label: _formatCount(photo.views ?? 0),
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: _StatItem(
              icon: Icons.download_outlined,
              label: _formatCount(photo.downloads),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF71717A)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF52525B),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 42,
      child: VerticalDivider(width: 1, thickness: 1, color: Color(0xFFF1F1F1)),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF555555),
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F5));
  }
}

class _ExifGrid extends StatelessWidget {
  const _ExifGrid({required this.items});

  final List<_ExifItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 42,
        crossAxisSpacing: 18,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFF4F4F5))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFA1A1AA),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  item.value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF27272A),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExifItem {
  const _ExifItem(this.label, this.value);

  final String label;
  final String value;
}

class _DownloadButton extends StatelessWidget {
  const _DownloadButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.download_outlined, size: 20, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Download Free',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreFromPhotographer extends ConsumerWidget {
  const _MoreFromPhotographer({required this.photo});

  final Photo photo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(userPhotosProvider(photo.user.username));

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
          photosAsync.when(
            data: (photos) {
              final displayPhotos =
                  photos.where((item) => item.id != photo.id).take(10).toList();
              if (displayPhotos.isEmpty) return const SizedBox.shrink();

              return SizedBox(
                height: 84,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: displayPhotos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final item = displayPhotos[index];
                    return GestureDetector(
                      onTap: () => context.push('/photo/${item.id}'),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: item.urlSmall,
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
          ),
        ],
      ),
    );
  }
}
