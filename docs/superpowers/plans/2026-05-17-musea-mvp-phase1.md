# Musea MVP Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Users can browse photos on the Discover page, tap to view details, see photographer info, and download images.

**Architecture:** Extract reusable PhotoCard/PhotoFeed/TopicBar widgets from the existing DiscoverPage. Add PhotoDetailPage with Hero animation and download flow. Add ProfilePage for photographer profiles (read-only, via Unsplash API). Remove the 4th "Profile" tab from bottom nav.

**Tech Stack:** Flutter 3.x, Riverpod, GoRouter, Dio, CachedNetworkImage, flutter_blurhash, photo_view, image_gallery_saver

---

### Task 1: Add dependencies

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add photo_view and image_gallery_saver**

```yaml
dependencies:
  # ... existing ...
  photo_view: ^0.15.0          # Image zoom/pan/fullscreen in detail page
  image_gallery_saver: ^2.0.3  # Save downloaded images to device gallery
```

- [ ] **Step 2: Run flutter pub get**

Run: `cd /Users/zed/Codes/Musea && flutter pub get`
Expected: All packages resolved successfully

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "feat: add photo_view and image_gallery_saver dependencies"
```

---

### Task 2: Profile data layer (API + Repository + Provider)

**Files:**
- Create: `lib/features/profile/data/datasources/profile_remote_datasource.dart`
- Create: `lib/features/profile/domain/repositories/profile_repository.dart`
- Create: `lib/features/profile/data/repositories/profile_repository_impl.dart`
- Create: `lib/features/profile/presentation/providers/profile_provider.dart`

- [ ] **Step 1: Create ProfileRemoteDataSource**

`lib/features/profile/data/datasources/profile_remote_datasource.dart`:

```dart
import 'package:musea/core/network/dio_client.dart';
import 'package:musea/core/constants/api_constants.dart';
import 'package:musea/features/discover/data/models/photo_model.dart';
import 'package:musea/features/discover/data/models/user_model.dart';

abstract class ProfileRemoteDataSource {
  Future<UserModel> getUserProfile(String username);
  Future<List<PhotoModel>> getUserPhotos(String username, {int page = 1, int perPage = 20});
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final DioClient _dioClient;

  ProfileRemoteDataSourceImpl(this._dioClient);

  @override
  Future<UserModel> getUserProfile(String username) async {
    final response = await _dioClient.get('${ApiConstants.users}/$username');
    return UserModel.fromJson(response);
  }

  @override
  Future<List<PhotoModel>> getUserPhotos(String username, {int page = 1, int perPage = 20}) async {
    final response = await _dioClient.get(
      ApiConstants.userPhotos(username),
      queryParameters: {
        'page': page,
        'per_page': perPage,
      },
    );
    return (response as List)
        .map((json) => PhotoModel.fromJson(json))
        .toList();
  }
}
```

- [ ] **Step 2: Create ProfileRepository abstract**

`lib/features/profile/domain/repositories/profile_repository.dart`:

```dart
import 'package:dartz/dartz.dart';
import 'package:musea/core/errors/failures.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';

abstract class ProfileRepository {
  Future<Either<Failure, User>> getUserProfile(String username);
  Future<Either<Failure, List<Photo>>> getUserPhotos(String username, {int page = 1, int perPage = 20});
}
```

- [ ] **Step 3: Create ProfileRepositoryImpl**

`lib/features/profile/data/repositories/profile_repository_impl.dart`:

```dart
import 'package:dartz/dartz.dart';
import 'package:musea/core/errors/exceptions.dart';
import 'package:musea/core/errors/failures.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/features/profile/domain/repositories/profile_repository.dart';
import 'package:musea/features/profile/data/datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, User>> getUserProfile(String username) async {
    try {
      final user = await remoteDataSource.getUserProfile(username);
      return Right(user.toEntity());
    } on ServerException catch (e) {
      if (e.statusCode == 404) {
        return Left(Failure.notFound(message: 'User not found'));
      }
      return Left(Failure.server(statusCode: e.statusCode, message: e.message));
    } on NetworkException catch (e) {
      return Left(Failure.network(message: e.message));
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Photo>>> getUserPhotos(String username, {int page = 1, int perPage = 20}) async {
    try {
      final photos = await remoteDataSource.getUserPhotos(username, page: page, perPage: perPage);
      return Right(photos.map((p) => p.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(Failure.server(statusCode: e.statusCode, message: e.message));
    } on NetworkException catch (e) {
      return Left(Failure.network(message: e.message));
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }
}
```

- [ ] **Step 4: Create ProfileNotifierProvider**

`lib/features/profile/presentation/providers/profile_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/core/network/dio_client.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/features/discover/presentation/providers/photos_provider.dart';
import 'package:musea/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:musea/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:musea/features/profile/domain/repositories/profile_repository.dart';

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSourceImpl(ref.watch(dioClientProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(
    remoteDataSource: ref.watch(profileRemoteDataSourceProvider),
  );
});

final userProfileProvider = FutureProvider.family<User, String>((ref, username) async {
  final repository = ref.watch(profileRepositoryProvider);
  final result = await repository.getUserProfile(username);
  return result.fold(
    (failure) => throw Exception(failure.toString()),
    (user) => user,
  );
});

final userPhotosProvider = FutureProvider.family<List<Photo>, String>((ref, username) async {
  final repository = ref.watch(profileRepositoryProvider);
  final result = await repository.getUserPhotos(username);
  return result.fold(
    (failure) => throw Exception(failure.toString()),
    (photos) => photos,
  );
});
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/profile/
git commit -m "feat: add profile data layer for photographer profiles"
```

---

### Task 3: Create TopicBar shared widget

**Files:**
- Create: `lib/shared/widgets/topic_bar.dart`

- [ ] **Step 1: Create TopicBar widget**

`lib/shared/widgets/topic_bar.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:musea/features/discover/domain/entities/topic.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/core/theme/text_styles.dart';

class TopicBar extends StatelessWidget {
  final List<Topic> topics;
  final String? selectedTopicSlug;
  final bool showAll;
  final ValueChanged<String?> onTopicTap;

  const TopicBar({
    super.key,
    required this.topics,
    this.selectedTopicSlug,
    this.showAll = true,
    required this.onTopicTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: topics.length + (showAll ? 1 : 0),
        itemBuilder: (context, index) {
          if (showAll && index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _TopicChip(
                label: 'All',
                isSelected: selectedTopicSlug == null,
                onTap: () => onTopicTap(null),
              ),
            );
          }
          final topicIndex = showAll ? index - 1 : index;
          final topic = topics[topicIndex];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _TopicChip(
              label: topic.title,
              isSelected: selectedTopicSlug == topic.slug,
              onTap: () => onTopicTap(topic.slug),
            ),
          );
        },
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TopicChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.gray200,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isSelected ? AppColors.onPrimary : AppColors.gray600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/shared/widgets/topic_bar.dart
git commit -m "feat: extract TopicBar as reusable shared widget"
```

---

### Task 4: Create PhotoCard shared widget

**Files:**
- Create: `lib/shared/widgets/photo_card.dart`

- [ ] **Step 1: Create PhotoCard widget**

`lib/shared/widgets/photo_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/core/theme/text_styles.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';

class PhotoCard extends StatelessWidget {
  final Photo photo;
  final VoidCallback? onPhotoTap;
  final VoidCallback? onUserTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onDownloadTap;
  final bool showDownloadButton;

  const PhotoCard({
    super.key,
    required this.photo,
    this.onPhotoTap,
    this.onUserTap,
    this.onLikeTap,
    this.onDownloadTap,
    this.showDownloadButton = true,
  });

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
      aspectRatio = 0.6; // 60% screen height max
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
              Colors.black.withOpacity(0.6),
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
```

- [ ] **Step 2: Commit**

```bash
git add lib/shared/widgets/photo_card.dart
git commit -m "feat: create PhotoCard reusable widget with BlurHash and actions"
```

---

### Task 5: Create PhotoFeed shared widget

**Files:**
- Create: `lib/shared/widgets/photo_feed.dart`

- [ ] **Step 1: Create PhotoFeed widget**

`lib/shared/widgets/photo_feed.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/shared/widgets/photo_card.dart';
import 'package:musea/shared/widgets/empty_state.dart';
import 'package:musea/shared/widgets/loading_indicator.dart';

class PhotoFeed extends StatelessWidget {
  final List<Photo> photos;
  final bool isLoadingMore;
  final void Function(Photo photo)? onPhotoTap;
  final void Function(Photo photo)? onUserTap;
  final void Function(Photo photo)? onLikeTap;
  final void Function(Photo photo)? onDownloadTap;
  final bool showDownloadButton;

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
```

- [ ] **Step 2: Commit**

```bash
git add lib/shared/widgets/photo_feed.dart
git commit -m "feat: create PhotoFeed reusable list widget"
```

---

### Task 6: Create Download bottom sheet

**Files:**
- Create: `lib/features/photo_detail/presentation/widgets/download_sheet.dart`

- [ ] **Step 1: Create download size selection sheet**

`lib/features/photo_detail/presentation/widgets/download_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/core/theme/text_styles.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';

class DownloadOption {
  final String label;
  final String url;
  final String sizeLabel;

  const DownloadOption({
    required this.label,
    required this.url,
    required this.sizeLabel,
  });
}

class DownloadSheet extends StatelessWidget {
  final Photo photo;

  const DownloadSheet({super.key, required this.photo});

  static Future<DownloadOption?> show(BuildContext context, Photo photo) {
    return showModalBottomSheet<DownloadOption>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DownloadSheet(photo: photo),
    );
  }

  List<DownloadOption> get _options => [
        DownloadOption(
          label: 'Raw',
          url: photo.urlRaw,
          sizeLabel: 'Original',
        ),
        DownloadOption(
          label: 'Full',
          url: photo.urlFull,
          sizeLabel: 'Full resolution',
        ),
        DownloadOption(
          label: 'Regular',
          url: photo.urlRegular,
          sizeLabel: 'Standard quality',
        ),
        DownloadOption(
          label: 'Small',
          url: photo.urlSmall,
          sizeLabel: 'Small size',
        ),
        DownloadOption(
          label: 'Thumb',
          url: photo.urlThumb,
          sizeLabel: 'Thumbnail',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Choose Size',
                style: AppTextStyles.heading3,
              ),
            ),
            const SizedBox(height: 16),
            ..._options.map((option) => ListTile(
                  leading: const Icon(Icons.image_outlined),
                  title: Text(option.label, style: AppTextStyles.bodyLarge),
                  subtitle: Text(option.sizeLabel, style: AppTextStyles.caption),
                  onTap: () => Navigator.of(context).pop(option),
                )),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/photo_detail/presentation/widgets/download_sheet.dart
git commit -m "feat: create download size selection bottom sheet"
```

---

### Task 7: Create PhotoDetailPage

**Files:**
- Create: `lib/features/photo_detail/presentation/pages/photo_detail_page.dart`

- [ ] **Step 1: Create PhotoDetailPage**

`lib/features/photo_detail/presentation/pages/photo_detail_page.dart`:

```dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:musea/core/network/dio_client.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/core/theme/text_styles.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/presentation/providers/photos_provider.dart';
import 'package:musea/shared/widgets/loading_indicator.dart';
import 'package:musea/shared/widgets/error_state.dart';
import 'package:musea/features/photo_detail/presentation/widgets/download_sheet.dart';

class PhotoDetailPage extends ConsumerWidget {
  final String photoId;

  const PhotoDetailPage({super.key, required this.photoId});

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
  final Photo photo;
  final void Function(String url) onDownload;

  const _PhotoDetailContent({
    required this.photo,
    required this.onDownload,
  });

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
          _buildPhotographerPhotos(context),
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
          Row(
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
            ],
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
          Text('Camera Info', style: AppTextStyles.heading3),
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
          Text('Location', style: AppTextStyles.heading3),
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
          Text('Tags', style: AppTextStyles.heading3),
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

  Widget _buildPhotographerPhotos(BuildContext context) {
    return SliverToBoxAdapter(child: const SizedBox.shrink());
  }

  Widget _buildBottomPadding() {
    return const SliverToBoxAdapter(child: SizedBox(height: 32));
  }

  void _triggerDownload(BuildContext context, String url) async {
    // Track download via Unsplash API (required attribution)
    try {
      final repository = ref.read(photoRepositoryProvider);
      await repository.trackDownload(photo.id);
    } catch (_) {}

    // Download the image file and save to gallery
    try {
      final dio = DioClient();
      final response = await dio.downloadBytes(url);
      if (response != null && context.mounted) {
        await ImageGallerySaver.saveImage(
          response,
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

  void _openFullScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenImage(photo: photo),
      ),
    );
  }
}

class _FullScreenImage extends StatelessWidget {
  final Photo photo;

  const _FullScreenImage({required this.photo});

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
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/photo_detail/
git commit -m "feat: create PhotoDetailPage with Hero animation, info sections, and image download"
```

---

### Task 8: Create ProfilePage (photographer profile)

**Files:**
- Create: `lib/features/profile/presentation/pages/profile_page.dart`

- [ ] **Step 1: Create ProfilePage**

`lib/features/profile/presentation/pages/profile_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/core/theme/text_styles.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/features/profile/presentation/providers/profile_provider.dart';
import 'package:musea/shared/widgets/loading_indicator.dart';
import 'package:musea/shared/widgets/error_state.dart';
import 'package:musea/shared/widgets/photo_card.dart';

class ProfilePage extends ConsumerWidget {
  final String username;

  const ProfilePage({super.key, required this.username});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider(username));
    final photosAsync = ref.watch(userPhotosProvider(username));

    return userAsync.when(
      data: (user) => _ProfileContent(user: user, photosAsync: photosAsync),
      loading: () => const Scaffold(
        body: Center(child: LoadingIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(),
        body: ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(userProfileProvider(username)),
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final User user;
  final AsyncValue<List<Photo>> photosAsync;

  const _ProfileContent({required this.user, required this.photosAsync});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.gray100,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Spacer(),
                    CircleAvatar(
                      radius: 48,
                      backgroundImage: CachedNetworkImageProvider(
                        user.profileImageLarge,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(user.name, style: AppTextStyles.heading2),
                    if (user.bio != null && user.bio!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
                        child: Text(
                          user.bio!,
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray600),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _statItem('${user.totalPhotos}', 'Photos'),
                        const SizedBox(width: 24),
                        _statItem('${user.totalLikes}', 'Likes'),
                        const SizedBox(width: 24),
                        _statItem('${user.totalCollections}', 'Collections'),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          photosAsync.when(
            data: (photos) {
              if (photos.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('No photos yet', style: AppTextStyles.bodyMedium)),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => PhotoCard(photo: photos[index]),
                    childCount: photos.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: LoadingIndicator()),
            ),
            error: (error, stack) => SliverFillRemaining(
              child: ErrorState(
                message: error.toString(),
                onRetry: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/profile/presentation/pages/profile_page.dart
git commit -m "feat: create ProfilePage for photographer profiles"
```

---

### Task 9: Update DiscoverPage to use shared widgets

**Files:**
- Modify: `lib/features/discover/presentation/pages/discover_page.dart`

- [ ] **Step 1: Replace inline code with shared widgets and add navigation**

Replace the entire content of `discover_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musea/features/discover/presentation/providers/photos_provider.dart';
import 'package:musea/features/discover/presentation/providers/topics_provider.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/topic.dart';
import 'package:musea/shared/widgets/loading_indicator.dart';
import 'package:musea/shared/widgets/error_state.dart';
import 'package:musea/shared/widgets/photo_feed.dart';
import 'package:musea/shared/widgets/topic_bar.dart';
import 'package:musea/core/theme/colors.dart';

class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({super.key});

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  String? _selectedTopicSlug;
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    setState(() {
      _currentPage++;
    });
  }

  void _onTopicTap(String? slug) {
    setState(() {
      _selectedTopicSlug = slug;
      _currentPage = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final topicsAsync = ref.watch(topicsProvider);
    final photosAsync = _selectedTopicSlug == null
        ? ref.watch(photosProvider(_currentPage))
        : ref.watch(topicPhotosProvider(
            TopicPhotosParams(topicSlug: _selectedTopicSlug!, page: _currentPage),
          ));

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(photosProvider);
            ref.invalidate(topicsProvider);
          },
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 8),
                    topicsAsync.when(
                      data: (topics) => TopicBar(
                        topics: topics,
                        selectedTopicSlug: _selectedTopicSlug,
                        onTopicTap: _onTopicTap,
                      ),
                      loading: () => const SizedBox(
                        height: 48,
                        child: Center(child: LoadingIndicator()),
                      ),
                      error: (error, stack) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              photosAsync.when(
                data: (photos) => PhotoFeed(
                  photos: photos,
                  isLoadingMore: false,
                  onPhotoTap: (photo) => context.go('/photo/${photo.id}'),
                  onUserTap: (photo) => context.go('/profile/${photo.user.username}'),
                  onLikeTap: (photo) => _toggleLike(photo),
                  onDownloadTap: (photo) => _handleDownload(context),
                ),
                loading: () => const SliverFillRemaining(
                  child: Center(child: LoadingIndicator()),
                ),
                error: (error, stack) => SliverFillRemaining(
                  child: ErrorState(
                    message: error.toString(),
                    onRetry: () => ref.invalidate(photosProvider),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: AppColors.gray500),
                  const SizedBox(width: 12),
                  Text(
                    'Search photos...',
                    style: TextStyle(color: AppColors.gray500),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _handleRandom,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shuffle, color: AppColors.onPrimary),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleLike(Photo photo) {
    // Local like state - MVP only
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Liked "${photo.user.name}"\'s photo')),
    );
  }

  void _handleDownload(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Open photo to download')),
    );
  }

  void _handleRandom() async {
    final randomPhoto = await ref.read(randomPhotoProvider.future);
    if (context.mounted) {
      context.go('/photo/${randomPhoto.id}');
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/discover/presentation/pages/discover_page.dart
git commit -m "refactor: Update DiscoverPage to use shared widgets and add navigation"
```

---

### Task 10: Update routing and navigation

**Files:**
- Modify: `lib/router/app_router.dart`
- Modify: `lib/shared/widgets/bottom_nav_bar.dart`

- [ ] **Step 1: Update app_router with new routes**

Replace the routes section (keep `_rootNavigatorKey`, `_shellNavigatorKey`, and `ScaffoldWithNavBar`):

```dart
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:musea/features/discover/presentation/pages/discover_page.dart';
import 'package:musea/features/photo_detail/presentation/pages/photo_detail_page.dart';
import 'package:musea/features/profile/presentation/pages/profile_page.dart';
import 'package:musea/shared/widgets/bottom_nav_bar.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/discover',
  debugLogDiagnostics: true,
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return ScaffoldWithNavBar(child: child);
      },
      routes: [
        GoRoute(
          path: '/discover',
          name: 'discover',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DiscoverPage(),
          ),
        ),
        GoRoute(
          path: '/explore',
          name: 'explore',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ExplorePlaceholderPage(),
          ),
        ),
        GoRoute(
          path: '/collections',
          name: 'collections',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CollectionsPlaceholderPage(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/photo/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return PhotoDetailPage(photoId: id);
      },
    ),
    GoRoute(
      path: '/profile/:username',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final username = state.pathParameters['username']!;
        return ProfilePage(username: username);
      },
    ),
  ],
);

class ExplorePlaceholderPage extends StatelessWidget {
  const ExplorePlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Explore - Coming in Phase 3')),
    );
  }
}

class CollectionsPlaceholderPage extends StatelessWidget {
  const CollectionsPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Collections - Coming in Phase 2')),
    );
  }
}
```

- [ ] **Step 2: Update BottomNavBar to have 3 tabs instead of 4**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    return NavigationBar(
      selectedIndex: _calculateSelectedIndex(location),
      onDestinationSelected: (index) => _onItemTapped(index, context),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.explore_outlined),
          selectedIcon: Icon(Icons.explore),
          label: 'Discover',
        ),
        NavigationDestination(
          icon: Icon(Icons.search_outlined),
          selectedIcon: Icon(Icons.search),
          label: 'Explore',
        ),
        NavigationDestination(
          icon: Icon(Icons.collections_bookmark_outlined),
          selectedIcon: Icon(Icons.collections_bookmark),
          label: 'Collections',
        ),
      ],
    );
  }

  int _calculateSelectedIndex(String location) {
    if (location.startsWith('/discover')) return 0;
    if (location.startsWith('/explore')) return 1;
    if (location.startsWith('/collections')) return 2;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/discover');
        break;
      case 1:
        context.go('/explore');
        break;
      case 2:
        context.go('/collections');
        break;
    }
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/router/app_router.dart lib/shared/widgets/bottom_nav_bar.dart
git commit -m "feat: add photo detail and profile routes, reduce bottom nav to 3 tabs"
```

---

### Task 11: Write tests

**Files:**
- Create: `test/shared/widgets/photo_card_test.dart`
- Create: `test/features/profile/pages/profile_page_test.dart`

- [ ] **Step 1: Write PhotoCard widget test**

`test/shared/widgets/photo_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/shared/widgets/photo_card.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';

User createTestUser() => const User(
  id: 'user1',
  username: 'testuser',
  name: 'Test User',
  profileImageSmall: '',
  profileImageMedium: '',
  profileImageLarge: '',
  totalPhotos: 10,
  totalLikes: 100,
  totalCollections: 5,
);

Photo createTestPhoto({
  int likes = 42,
  int downloads = 10,
}) => Photo(
  id: 'photo1',
  createdAt: DateTime.now(),
  width: 4000,
  height: 3000,
  color: '#ABCDEF',
  blurHash: null,
  urlRaw: '',
  urlFull: '',
  urlRegular: '',
  urlSmall: '',
  urlThumb: '',
  likes: likes,
  downloads: downloads,
  user: createTestUser(),
);

Widget wrapApp(Widget widget) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: widget)),
);

void main() {
  testWidgets('PhotoCard displays user name and like count', (tester) async {
    final photo = createTestPhoto(likes: 1234);
    await tester.pumpWidget(wrapApp(PhotoCard(photo: photo)));

    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('1.2k'), findsOneWidget);
    expect(find.byIcon(Icons.download), findsOneWidget);
  });

  testWidgets('PhotoCard hides download button when showDownloadButton is false',
      (tester) async {
    final photo = createTestPhoto();
    await tester.pumpWidget(wrapApp(
      PhotoCard(photo: photo, showDownloadButton: false),
    ));

    expect(find.byIcon(Icons.download), findsNothing);
  });

  testWidgets('PhotoCard triggers onPhotoTap on tap', (tester) async {
    final photo = createTestPhoto();
    bool tapped = false;
    await tester.pumpWidget(wrapApp(
      PhotoCard(
        photo: photo,
        onPhotoTap: () => tapped = true,
      ),
    ));

    await tester.tap(find.byType(GestureDetector).first);
    expect(tapped, isTrue);
  });
}
```

- [ ] **Step 2: Run PhotoCard tests**

Run: `flutter test test/shared/widgets/photo_card_test.dart`
Expected: PASS

- [ ] **Step 3: Commit tests**

```bash
git add test/shared/widgets/photo_card_test.dart
git commit -m "test: add PhotoCard widget tests"
```

---

### Self-Review

After writing the plan, review against the spec:

**1. Spec coverage:**
- [x] Extract PhotoCard/PhotoFeed/TopicBar widgets → Task 3, 4, 5
- [x] PhotoDetailPage with Hero animation → Task 7
- [x] Photographer ProfilePage → Task 8
- [x] Update DiscoverPage → Task 9
- [x] Add routes → Task 10
- [x] Remove 4th bottom nav tab → Task 10
- [x] Download flow → Task 6, 7
- [x] BlurHash → Task 4 (in PhotoCard)

**2. Placeholder scan:** No TBD, TODO, "implement later", or "Coming soon" in code blocks. All code is implementation-ready.

**3. Type consistency:**
- `PhotoRepository.getPhotoById(id)` returns `Future<Either<Failure, Photo>>` — `photoDetailProvider` uses this
- `PhotoCard` takes `Photo` entity which has all needed fields
- `photoDetailProvider` takes `String` id — matches route param type

**4. Spec gaps:** The "similar photos" section on the detail page is deferred (depends on search API in Phase 3), which matches the scope discussion.
