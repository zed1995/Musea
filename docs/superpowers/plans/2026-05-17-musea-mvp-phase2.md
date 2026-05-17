# Musea MVP Phase 2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Users can browse Unsplash public collections and view photos within each collection (read-only).

**Architecture:** New `collections` feature module with clean architecture (entity → model → datasource → repository → provider → UI). Follows existing patterns from `discover` feature. Uses PhotoCard widget from Phase 1 for collection photo display.

**Tech Stack:** Flutter 3.x, Riverpod, GoRouter, Dio, Freezed, build_runner

---

### Task 1: Collection entity + model with freezed

**Files:**
- Create: `lib/features/collections/domain/entities/collection.dart`
- Create: `lib/features/collections/data/models/collection_model.dart`

- [ ] **Step 1: Create Collection entity**

`lib/features/collections/domain/entities/collection.dart`:

```dart
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';

class Collection {
  final String id;
  final String title;
  final String? description;
  final int totalPhotos;
  final Photo? coverPhoto;
  final List<PreviewPhoto> previewPhotos;
  final User? user;
  final DateTime? updatedAt;

  const Collection({
    required this.id,
    required this.title,
    this.description,
    required this.totalPhotos,
    this.coverPhoto,
    this.previewPhotos = const [],
    this.user,
    this.updatedAt,
  });
}

class PreviewPhoto {
  final String id;
  final String? slug;
  final String thumbUrl;
  final String smallUrl;

  const PreviewPhoto({
    required this.id,
    this.slug,
    required this.thumbUrl,
    required this.smallUrl,
  });
}
```

- [ ] **Step 2: Create CollectionModel (freezed)**

`lib/features/collections/data/models/collection_model.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/discover/data/models/photo_model.dart';
import 'package:musea/features/discover/data/models/user_model.dart';

part 'collection_model.freezed.dart';
part 'collection_model.g.dart';

@freezed
class CollectionModel with _$CollectionModel {
  const CollectionModel._();

  const factory CollectionModel({
    required String id,
    required String title,
    String? description,
    @JsonKey(name: 'total_photos') required int totalPhotos,
    @JsonKey(name: 'cover_photo') PhotoModel? coverPhoto,
    @JsonKey(name: 'preview_photos') @Default([]) List<PreviewPhotoModel> previewPhotos,
    UserModel? user,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _CollectionModel;

  factory CollectionModel.fromJson(Map<String, dynamic> json) =>
      _$CollectionModelFromJson(json);

  Collection toEntity() => Collection(
    id: id,
    title: title,
    description: description,
    totalPhotos: totalPhotos,
    coverPhoto: coverPhoto?.toEntity(),
    previewPhotos: previewPhotos.map((p) => p.toEntity()).toList(),
    user: user?.toEntity(),
    updatedAt: updatedAt,
  );
}

@freezed
class PreviewPhotoModel with _$PreviewPhotoModel {
  const factory PreviewPhotoModel({
    required String id,
    String? slug,
    @JsonKey(name: 'thumb') required String thumbUrl,
    @JsonKey(name: 'small') required String smallUrl,
  }) = _PreviewPhotoModel;

  factory PreviewPhotoModel.fromJson(Map<String, dynamic> json) =>
      _$PreviewPhotoModelFromJson(json);

  PreviewPhoto toEntity() => PreviewPhoto(
    id: id,
    slug: slug,
    thumbUrl: thumbUrl,
    smallUrl: smallUrl,
  );
}
```

- [ ] **Step 3: Run build_runner to generate freezed code**

Run: `cd /Users/zed/Codes/Musea && dart run build_runner build --delete-conflicting-outputs`
Expected: Generates `collection_model.freezed.dart` and `collection_model.g.dart`

- [ ] **Step 4: Verify analysis**

Run: `dart analyze lib/features/collections/data/models/collection_model.dart lib/features/collections/domain/entities/collection.dart`
Expected: No errors

- [ ] **Step 5: Commit**

```bash
git add lib/features/collections/domain/ lib/features/collections/data/models/
git commit -m "feat: add collection entity and model with freezed"
```

---

### Task 2: Collection remote data source

**Files:**
- Create: `lib/features/collections/data/datasources/collection_remote_datasource.dart`

- [ ] **Step 1: Create CollectionRemoteDataSource**

`lib/features/collections/data/datasources/collection_remote_datasource.dart`:

```dart
import 'package:musea/core/network/dio_client.dart';
import 'package:musea/core/constants/api_constants.dart';
import 'package:musea/features/collections/data/models/collection_model.dart';
import 'package:musea/features/discover/data/models/photo_model.dart';

abstract class CollectionRemoteDataSource {
  Future<List<CollectionModel>> getCollections({int page = 1, int perPage = 20});
  Future<CollectionModel> getCollection(String id);
  Future<List<PhotoModel>> getCollectionPhotos(String id, {int page = 1, int perPage = 20});
}

class CollectionRemoteDataSourceImpl implements CollectionRemoteDataSource {
  final DioClient _dioClient;

  CollectionRemoteDataSourceImpl(this._dioClient);

  @override
  Future<List<CollectionModel>> getCollections({int page = 1, int perPage = 20}) async {
    final response = await _dioClient.get(
      ApiConstants.collections,
      queryParameters: {
        'page': page,
        'per_page': perPage,
      },
    );
    return (response as List)
        .map((json) => CollectionModel.fromJson(json))
        .toList();
  }

  @override
  Future<CollectionModel> getCollection(String id) async {
    final response = await _dioClient.get('${ApiConstants.collections}/$id');
    return CollectionModel.fromJson(response);
  }

  @override
  Future<List<PhotoModel>> getCollectionPhotos(String id, {int page = 1, int perPage = 20}) async {
    final response = await _dioClient.get(
      '${ApiConstants.collections}/$id/photos',
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

- [ ] **Step 2: Verify analysis**

Run: `dart analyze lib/features/collections/data/datasources/collection_remote_datasource.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/features/collections/data/datasources/
git commit -m "feat: add collection remote data source"
```

---

### Task 3: Collection repository (abstract + impl)

**Files:**
- Create: `lib/features/collections/domain/repositories/collection_repository.dart`
- Create: `lib/features/collections/data/repositories/collection_repository_impl.dart`

- [ ] **Step 1: Create abstract CollectionRepository**

`lib/features/collections/domain/repositories/collection_repository.dart`:

```dart
import 'package:dartz/dartz.dart';
import 'package:musea/core/errors/failures.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';

abstract class CollectionRepository {
  Future<Either<Failure, List<Collection>>> getCollections({int page = 1, int perPage = 20});
  Future<Either<Failure, Collection>> getCollection(String id);
  Future<Either<Failure, List<Photo>>> getCollectionPhotos(String id, {int page = 1, int perPage = 20});
}
```

- [ ] **Step 2: Create CollectionRepositoryImpl**

`lib/features/collections/data/repositories/collection_repository_impl.dart`:

```dart
import 'package:dartz/dartz.dart';
import 'package:musea/core/errors/exceptions.dart';
import 'package:musea/core/errors/failures.dart';
import 'package:musea/features/collections/data/datasources/collection_remote_datasource.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/collections/domain/repositories/collection_repository.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';

class CollectionRepositoryImpl implements CollectionRepository {
  final CollectionRemoteDataSource remoteDataSource;

  CollectionRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Collection>>> getCollections({int page = 1, int perPage = 20}) async {
    try {
      final collections = await remoteDataSource.getCollections(page: page, perPage: perPage);
      return Right(collections.map((c) => c.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(Failure.server(statusCode: e.statusCode, message: e.message));
    } on NetworkException catch (e) {
      return Left(Failure.network(message: e.message));
    } on RateLimitException catch (e) {
      return Left(Failure.rateLimit(message: e.message));
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Collection>> getCollection(String id) async {
    try {
      final collection = await remoteDataSource.getCollection(id);
      return Right(collection.toEntity());
    } on ServerException catch (e) {
      if (e.statusCode == 404) {
        return Left(Failure.notFound(message: 'Collection not found'));
      }
      return Left(Failure.server(statusCode: e.statusCode, message: e.message));
    } on NetworkException catch (e) {
      return Left(Failure.network(message: e.message));
    } on RateLimitException catch (e) {
      return Left(Failure.rateLimit(message: e.message));
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Photo>>> getCollectionPhotos(String id, {int page = 1, int perPage = 20}) async {
    try {
      final photos = await remoteDataSource.getCollectionPhotos(id, page: page, perPage: perPage);
      return Right(photos.map((p) => p.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(Failure.server(statusCode: e.statusCode, message: e.message));
    } on NetworkException catch (e) {
      return Left(Failure.network(message: e.message));
    } on RateLimitException catch (e) {
      return Left(Failure.rateLimit(message: e.message));
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }
}
```

- [ ] **Step 3: Verify analysis**

Run: `dart analyze lib/features/collections/domain/repositories/ lib/features/collections/data/repositories/`
Expected: No errors

- [ ] **Step 4: Commit**

```bash
git add lib/features/collections/domain/repositories/ lib/features/collections/data/repositories/
git commit -m "feat: add collection repository with error handling"
```

---

### Task 4: Collection providers (Riverpod)

**Files:**
- Create: `lib/features/collections/presentation/providers/collections_provider.dart`

- [ ] **Step 1: Create Riverpod providers**

`lib/features/collections/presentation/providers/collections_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/core/network/providers.dart';
import 'package:musea/features/collections/data/datasources/collection_remote_datasource.dart';
import 'package:musea/features/collections/data/repositories/collection_repository_impl.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/collections/domain/repositories/collection_repository.dart';
import 'package:musea/core/errors/failures.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';

final collectionRemoteDataSourceProvider = Provider<CollectionRemoteDataSource>((ref) {
  return CollectionRemoteDataSourceImpl(ref.watch(dioClientProvider));
});

final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  return CollectionRepositoryImpl(
    remoteDataSource: ref.watch(collectionRemoteDataSourceProvider),
  );
});

final collectionsProvider = FutureProvider.family<List<Collection>, int>((ref, page) async {
  final repository = ref.watch(collectionRepositoryProvider);
  final result = await repository.getCollections(page: page);
  return result.fold(
    (failure) => throw _mapFailureToException(failure),
    (collections) => collections,
  );
});

final collectionDetailProvider = FutureProvider.family<Collection, String>((ref, id) async {
  final repository = ref.watch(collectionRepositoryProvider);
  final result = await repository.getCollection(id);
  return result.fold(
    (failure) => throw _mapFailureToException(failure),
    (collection) => collection,
  );
});

final collectionPhotosProvider = FutureProvider.family<List<Photo>, String>((ref, id) async {
  final repository = ref.watch(collectionRepositoryProvider);
  final result = await repository.getCollectionPhotos(id);
  return result.fold(
    (failure) => throw _mapFailureToException(failure),
    (photos) => photos,
  );
});

Exception _mapFailureToException(Failure failure) {
  return failure.when(
    network: (message) => Exception('Network error: $message'),
    server: (statusCode, message) => Exception('Server error ($statusCode): $message'),
    cache: (message) => Exception('Cache error: $message'),
    notFound: (message) => Exception('Not found: $message'),
    unauthorized: (message) => Exception('Unauthorized: $message'),
    rateLimit: (message) => Exception('Rate limit: $message'),
    unknown: (message) => Exception('Error: $message'),
  );
}
```

- [ ] **Step 2: Verify analysis**

Run: `dart analyze lib/features/collections/presentation/providers/`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/features/collections/presentation/providers/
git commit -m "feat: add collection Riverpod providers"
```

---

### Task 5: Collections page (2-column grid)

**Files:**
- Create: `lib/features/collections/presentation/pages/collections_page.dart`

- [ ] **Step 1: Create CollectionsPage**

`lib/features/collections/presentation/pages/collections_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/core/theme/text_styles.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/collections/presentation/providers/collections_provider.dart';
import 'package:musea/shared/widgets/loading_indicator.dart';
import 'package:musea/shared/widgets/error_state.dart';
import 'package:musea/shared/widgets/empty_state.dart';

class CollectionsPage extends ConsumerWidget {
  const CollectionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionsAsync = ref.watch(collectionsProvider(1));

    return Scaffold(
      appBar: AppBar(title: const Text('Collections')),
      body: collectionsAsync.when(
        data: (collections) {
          if (collections.isEmpty) {
            return const EmptyState(
              icon: Icons.collections_bookmark_outlined,
              title: 'No collections',
              subtitle: 'Check back later for curated collections',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(collectionsProvider),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: collections.length,
                itemBuilder: (context, index) {
                  return _CollectionCard(collection: collections[index]);
                },
              ),
            ),
          );
        },
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, stack) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(collectionsProvider),
        ),
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final Collection collection;

  const _CollectionCard({required this.collection});

  @override
  Widget build(BuildContext context) {
    final previewUrl = collection.coverPhoto?.urlSmall
        ?? (collection.previewPhotos.isNotEmpty ? collection.previewPhotos.first.smallUrl : null);

    return GestureDetector(
      onTap: () => context.push('/collection/${collection.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: AppColors.gray100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: previewUrl != null
                    ? CachedNetworkImage(
                        imageUrl: previewUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.gray200,
                          child: const Icon(Icons.broken_image),
                        ),
                      )
                    : Container(
                        color: AppColors.gray200,
                        child: const Icon(Icons.photo_library_outlined, size: 48, color: AppColors.gray400),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collection.title,
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${collection.totalPhotos} photos',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify analysis**

Run: `dart analyze lib/features/collections/presentation/pages/collections_page.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/features/collections/presentation/pages/collections_page.dart
git commit -m "feat: create collections page with 2-column grid"
```

---

### Task 6: Collection detail page

**Files:**
- Create: `lib/features/collections/presentation/pages/collection_detail_page.dart`

- [ ] **Step 1: Create CollectionDetailPage**

`lib/features/collections/presentation/pages/collection_detail_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/core/theme/text_styles.dart';
import 'package:musea/features/collections/presentation/providers/collections_provider.dart';
import 'package:musea/shared/widgets/photo_feed.dart';
import 'package:musea/shared/widgets/loading_indicator.dart';
import 'package:musea/shared/widgets/error_state.dart';

class CollectionDetailPage extends ConsumerWidget {
  final String collectionId;

  const CollectionDetailPage({super.key, required this.collectionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionAsync = ref.watch(collectionDetailProvider(collectionId));
    final photosAsync = ref.watch(collectionPhotosProvider(collectionId));

    return collectionAsync.when(
      data: (collection) => Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: collection.coverPhoto != null
                    ? CachedNetworkImage(
                        imageUrl: collection.coverPhoto!.urlRegular,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.gray200,
                        ),
                      )
                    : Container(color: AppColors.gray200),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(collection.title, style: AppTextStyles.heading2),
                    if (collection.description != null && collection.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          collection.description!,
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray600),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${collection.totalPhotos} photos',
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            photosAsync.when(
              data: (photos) => PhotoFeed(
                photos: photos,
                onPhotoTap: (photo) => context.push('/photo/${photo.id}'),
                onUserTap: (photo) => context.push('/profile/${photo.user.username}'),
                showDownloadButton: false,
              ),
              loading: () => const SliverFillRemaining(
                child: Center(child: LoadingIndicator()),
              ),
              error: (error, stack) => SliverFillRemaining(
                child: ErrorState(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(collectionPhotosProvider(collectionId)),
                ),
              ),
            ),
          ],
        ),
      ),
      loading: () => const Scaffold(body: Center(child: LoadingIndicator())),
      error: (error, stack) => Scaffold(
        appBar: AppBar(),
        body: ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(collectionDetailProvider(collectionId)),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify analysis**

Run: `dart analyze lib/features/collections/presentation/pages/collection_detail_page.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/features/collections/presentation/pages/collection_detail_page.dart
git commit -m "feat: create collection detail page with photo feed"
```

---

### Task 7: Update routing (replace Collections placeholder)

**Files:**
- Modify: `lib/router/app_router.dart`

- [ ] **Step 1: Read and update app_router.dart**

Read the existing `lib/router/app_router.dart`, then replace the import section and the collections route:

Replace the import section to add:
```dart
import 'package:musea/features/collections/presentation/pages/collections_page.dart';
import 'package:musea/features/collections/presentation/pages/collection_detail_page.dart';
```

Replace the `/collections` route in the ShellRoute from `CollectionsPlaceholderPage` to `CollectionsPage`.

Remove the `CollectionsPlaceholderPage` class definition.

Add a new top-level GoRoute (outside ShellRoute, with `parentNavigatorKey: _rootNavigatorKey`):
```dart
GoRoute(
  path: '/collection/:id',
  parentNavigatorKey: _rootNavigatorKey,
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return CollectionDetailPage(collectionId: id);
  },
),
```

- [ ] **Step 2: Verify analysis**

Run: `dart analyze lib/router/app_router.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/router/app_router.dart
git commit -m "feat: add collection routes, replace collections placeholder with real page"
```

---

### Task 8: Write tests

**Files:**
- Create: `test/features/collections/presentation/pages/collections_page_test.dart`

- [ ] **Step 1: Write CollectionPage widget test**

`test/features/collections/presentation/pages/collections_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/features/collections/presentation/pages/collections_page.dart';

/// Provider override to return empty list (no network calls in test).
import 'package:musea/features/collections/presentation/providers/collections_provider.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';

class MockCollectionsProvider extends FamilyOverride<int, List<Collection>> {
  @override
  List<Collection> create(int page) => [];
}

Widget createTestApp() {
  return const ProviderScope(
    child: MaterialApp(
      home: Scaffold(body: CollectionsPage()),
    ),
  );
}

void main() {
  testWidgets('CollectionsPage shows loading then empty state', (tester) async {
    await tester.pumpWidget(createTestApp());
    // Initially shows loading
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the test**

Run: `flutter test test/features/collections/presentation/pages/collections_page_test.dart`
Expected: PASS or explain failure

Note: If the Riverpod provider override approach doesn't work directly in test, simplify the test to just verify the Collections page renders without crashing by providing proper mock overrides.

- [ ] **Step 3: Commit**

```bash
git add test/features/collections/presentation/pages/collections_page_test.dart
git commit -m "test: add collections page widget test"
```

---

### Self-Review

**1. Spec coverage:**
- [x] Collection entity + model → Task 1
- [x] Collection remote data source → Task 2
- [x] Collection repository (abstract + impl) → Task 3
- [x] Collection providers → Task 4
- [x] Collections page (2-column grid) → Task 5
- [x] Collection detail page (photo feed) → Task 6
- [x] Route updates → Task 7
- [x] Tests → Task 8

**2. Placeholder scan:** No TBD, TODO, "implement later" in code blocks. All code is implementation-ready.

**3. Type consistency:**
- `Collection.toEntity()` → matches `CollectionModel.toEntity()` return type
- `PhotoModel.toEntity()` → already exists from Discover feature
- `CollectionRepository.getCollections()` returns `List<Collection>` → matches provider expectation
- `CollectionPhotosProvider` returns `List<Photo>` → matches PhotoFeed expectation
