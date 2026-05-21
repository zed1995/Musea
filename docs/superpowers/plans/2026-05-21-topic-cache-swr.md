# Topic Cache SWR Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate topic loading spinners by showing cached topics instantly (SWR pattern), refreshing in background once per 24h.

**Architecture:** Extend `TopicLocalDataSource` to store a `lastUpdatedAt` timestamp alongside topics. Create a `TopicListNotifier` (Riverpod `Notifier`) that reads cache first, checks TTL, and fires background refreshes. The `topicsProvider` changes from `FutureProvider` to `NotifierProvider`. `DiscoverPage` no longer needs `when(loading: ...)` / `when(error: ...)` for topics. `PhotoRepositoryImpl.getTopics()` becomes a pure network call without cache fallback.

**Tech Stack:** Flutter, Riverpod, Hive

---

### Task 1: Extend TopicLocalDataSource with timestamp storage

**Files:**
- Modify: `lib/features/discover/data/datasources/topic_local_datasource.dart`
- Test: `test/features/discover/data/datasources/topic_local_datasource_test.dart`

- [ ] **Step 1: Write the failing test for TopicLocalDataSource**

Create `test/features/discover/data/datasources/topic_local_datasource_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:musea/features/discover/data/datasources/topic_local_datasource.dart';
import 'package:musea/features/discover/data/models/topic_model.dart';

void main() {
  group('TopicLocalDataSource', () {
    late TopicLocalDataSource dataSource;

    setUp(() async {
      Hive.init(Directory.systemTemp.path);
      dataSource = TopicLocalDataSourceImpl();
    });

    tearDown(() async {
      await dataSource.clearCache();
    });

    test('saveTopics stores topics and timestamp', () async {
      final topics = [
        const TopicModel(id: '1', slug: 'nature', title: 'Nature', totalPhotos: 10),
        const TopicModel(id: '2', slug: 'architecture', title: 'Architecture', totalPhotos: 5),
      ];

      await dataSource.saveTopics(topics);
      final cached = await dataSource.getTopics();
      final lastUpdated = await dataSource.getLastUpdatedAt();

      expect(cached.length, 2);
      expect(cached[0].id, '1');
      expect(cached[1].id, '2');
      expect(lastUpdated, isNotNull);
    });

    test('getTopics returns empty list when cache is empty', () async {
      final cached = await dataSource.getTopics();
      expect(cached, isEmpty);
    });

    test('getLastUpdatedAt returns null when cache is empty', () async {
      final lastUpdated = await dataSource.getLastUpdatedAt();
      expect(lastUpdated, isNull);
    });

    test('clearCache removes all data', () async {
      final topics = [
        const TopicModel(id: '1', slug: 'nature', title: 'Nature', totalPhotos: 10),
      ];

      await dataSource.saveTopics(topics);
      await dataSource.clearCache();

      final cached = await dataSource.getTopics();
      final lastUpdated = await dataSource.getLastUpdatedAt();

      expect(cached, isEmpty);
      expect(lastUpdated, isNull);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/discover/data/datasources/topic_local_datasource_test.dart`
Expected: FAIL — `saveTopics` / `getLastUpdatedAt` not defined

- [ ] **Step 3: Rewrite TopicLocalDataSource with new interface**

Replace the entire file with:

```dart
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:musea/features/discover/data/models/topic_model.dart';

abstract class TopicLocalDataSource {
  Future<void> saveTopics(List<TopicModel> topics);
  Future<List<TopicModel>> getTopics();
  Future<DateTime?> getLastUpdatedAt();
  Future<void> clearCache();
}

class TopicLocalDataSourceImpl implements TopicLocalDataSource {
  static const String _boxName = 'topics_cache';
  static const String _dataKey = 'topic_data';
  Box<dynamic>? _box;

  Future<Box<dynamic>> get box async {
    _box ??= await Hive.openBox(_boxName);
    return _box!;
  }

  @override
  Future<void> saveTopics(List<TopicModel> topics) async {
    final topicBox = await box;
    final jsonList = topics.map((topic) {
      final json = topic.toJson();
      json.remove('cover_photo');
      return json;
    }).toList();

    final payload = {
      'topics': jsonList,
      'lastUpdatedAt': DateTime.now().toUtc().toIso8601String(),
    };
    await topicBox.put(_dataKey, jsonEncode(payload));
  }

  @override
  Future<List<TopicModel>> getTopics() async {
    final topicBox = await box;
    final raw = topicBox.get(_dataKey);
    if (raw == null || raw is! String) return [];

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final jsonList = data['topics'] as List;
      return jsonList
          .map((json) => TopicModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<DateTime?> getLastUpdatedAt() async {
    final topicBox = await box;
    final raw = topicBox.get(_dataKey);
    if (raw == null || raw is! String) return null;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final timestamp = data['lastUpdatedAt'] as String?;
      return timestamp != null ? DateTime.parse(timestamp) : null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> clearCache() async {
    final topicBox = await box;
    await topicBox.clear();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/discover/data/datasources/topic_local_datasource_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/discover/data/datasources/topic_local_datasource.dart test/features/discover/data/datasources/topic_local_datasource_test.dart
git commit -m "feat: extend TopicLocalDataSource with timestamp-based storage"
```

---

### Task 2: Create TopicListNotifier (SWR provider)

**Files:**
- Modify: `lib/features/discover/presentation/providers/topics_provider.dart`
- Modify: `lib/features/discover/presentation/providers/photos_provider.dart` (add `topicListNotifierProvider`)
- Test: `test/features/discover/presentation/providers/topics_provider_test.dart`

- [ ] **Step 1: Write the failing test for TopicListNotifier**

Create `test/features/discover/presentation/providers/topics_provider_test.dart`:

```dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musea/core/errors/failures.dart';
import 'package:musea/features/discover/domain/entities/topic.dart';
import 'package:musea/features/discover/domain/repositories/photo_repository.dart';
import 'package:musea/features/discover/presentation/providers/topics_provider.dart';

class MockPhotoRepository extends Mock implements PhotoRepository {}

class MockTopicLocalDataSource extends Mock implements TopicLocalDataSource {}

void main() {
  late MockPhotoRepository mockRepo;
  late MockTopicLocalDataSource mockDS;

  setUp(() {
    mockRepo = MockPhotoRepository();
    mockDS = MockTopicLocalDataSource();
  });

  test('initial state is empty when no cache exists', () async {
    when(() => mockDS.getTopics()).thenAnswer((_) async => []);
    when(() => mockDS.getLastUpdatedAt()).thenAnswer((_) async => null);

    final container = ProviderContainer(
      overrides: [
        photoRepositoryProvider.overrideWithValue(mockRepo),
        topicLocalDataSourceProvider.overrideWithValue(mockDS),
      ],
    );
    addTearDown(container.dispose);

    final topics = container.read(topicsProvider);
    expect(topics, isEmpty);
  });

  test('returns cached topics when cache is valid', () async {
    when(() => mockDS.getTopics()).thenAnswer((_) async => [
      const Topic(id: '1', slug: 'nature', title: 'Nature', totalPhotos: 10),
    ]);
    when(() => mockDS.getLastUpdatedAt()).thenAnswer((_) async => DateTime.now());

    final container = ProviderContainer(
      overrides: [
        photoRepositoryProvider.overrideWithValue(mockRepo),
        topicLocalDataSourceProvider.overrideWithValue(mockDS),
      ],
    );
    addTearDown(container.dispose);

    final topics = container.read(topicsProvider);
    expect(topics.length, 1);
    expect(topics[0].title, 'Nature');
  });

  test('returns cached topics and fires refresh when stale', () async {
    when(() => mockDS.getTopics()).thenAnswer((_) async => [
      const Topic(id: '1', slug: 'nature', title: 'Nature', totalPhotos: 10),
    ]);
    when(() => mockDS.getLastUpdatedAt()).thenAnswer((_) async =>
        DateTime.now().subtract(const Duration(hours: 25)));
    when(() => mockRepo.getTopics()).thenAnswer((_) async =>
        Right([const Topic(id: '1', slug: 'nature', title: 'Nature', totalPhotos: 10)]));
    when(() => mockDS.saveTopics(any())).thenAnswer((_) async => {});

    final container = ProviderContainer(
      overrides: [
        photoRepositoryProvider.overrideWithValue(mockRepo),
        topicLocalDataSourceProvider.overrideWithValue(mockDS),
      ],
    );
    addTearDown(container.dispose);

    // State should be cached data immediately
    final topics = container.read(topicsProvider);
    expect(topics.length, 1);

    // Background refresh should have been triggered
    await Future.delayed(Duration.zero);
    verify(() => mockRepo.getTopics()).called(1);
  });

  test('does not fire network request when cache is fresh', () async {
    when(() => mockDS.getTopics()).thenAnswer((_) async => [
      const Topic(id: '1', slug: 'nature', title: 'Nature', totalPhotos: 10),
    ]);
    when(() => mockDS.getLastUpdatedAt()).thenAnswer((_) async =>
        DateTime.now().subtract(const Duration(hours: 1)));

    final container = ProviderContainer(
      overrides: [
        photoRepositoryProvider.overrideWithValue(mockRepo),
        topicLocalDataSourceProvider.overrideWithValue(mockDS),
      ],
    );
    addTearDown(container.dispose);

    await Future.delayed(Duration.zero);
    verifyNever(() => mockRepo.getTopics());
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/discover/presentation/providers/topics_provider_test.dart`
Expected: FAIL — TopicListNotifier not defined, types not found

- [ ] **Step 3: Rewrite topics_provider.dart with Notifier-based SWR provider**

Replace the content of `lib/features/discover/presentation/providers/topics_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/features/discover/domain/entities/topic.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/presentation/providers/photos_provider.dart';
import 'package:musea/features/discover/data/datasources/topic_local_datasource.dart';

final topicsProvider = NotifierProvider<TopicListNotifier, List<Topic>>(
  TopicListNotifier.new,
);

class TopicListNotifier extends Notifier<List<Topic>> {
  @override
  List<Topic> build() {
    _init();
    return [];
  }

  Future<void> _init() async {
    final localDataSource = ref.read(topicLocalDataSourceProvider);

    // 1. Read cache first
    final cached = await localDataSource.getTopics();
    if (cached.isNotEmpty) {
      state = cached.map((e) => e.toEntity()).toList();
    }

    // 2. Check TTL
    final lastUpdated = await localDataSource.getLastUpdatedAt();
    if (lastUpdated != null &&
        DateTime.now().difference(lastUpdated).inHours < 24) {
      return; // cache is still fresh
    }

    // 3. Background refresh
    _refreshInBackground();
  }

  Future<void> _refreshInBackground() async {
    final repository = ref.read(photoRepositoryProvider);
    final localDataSource = ref.read(topicLocalDataSourceProvider);

    final result = await repository.getTopics();
    result.fold(
      (failure) => {/* silent */},
      (topics) async {
        final models = topics
            .map((t) => TopicModel(
                  id: t.id,
                  slug: t.slug,
                  title: t.title,
                  description: t.description,
                  totalPhotos: t.totalPhotos,
                ))
            .toList();
        await localDataSource.saveTopics(models);
        if (state.isEmpty) {
          state = topics;
        }
      },
    );
  }

  /// For backwards compatibility with existing code that invalidates topics provider
  // ignore: unused_element
  void forceRefresh() {
    _refreshInBackground();
  }
}

// Keep topicPhotosProvider and TopicPhotosParams as-is
final topicPhotosProvider = FutureProvider.family<List<Photo>, TopicPhotosParams>((ref, params) async {
  final repository = ref.watch(photoRepositoryProvider);
  final result = await repository.getTopicPhotos(params.topicSlug, page: params.page);

  return result.fold(
    (failure) => throw Exception(failure.toString()),
    (photos) => photos,
  );
});

class TopicPhotosParams {
  final String topicSlug;
  final int page;

  TopicPhotosParams({
    required this.topicSlug,
    this.page = 1,
  });
}
```

Note: `TopicModel` is already imported via `topic_local_datasource.dart` — we need to also import the model. Let me check the imports.

Actually, I need to import `TopicModel` from the model file. Let me also make sure the `TopicModel` constructor from JSON is available. Since `TopicModel` is freezed with `@freezed`, I can use the default constructor with named params.

Wait, `TopicModel` freezed constructor:
```dart
const factory TopicModel({
    required String id,
    required String slug,
    required String title,
    String? description,
    @JsonKey(name: 'total_photos') required int totalPhotos,
    @JsonKey(name: 'cover_photo') PhotoModel? coverPhoto,
    TopicLinksModel? links,
}) = _TopicModel;
```

So I can create models with:
```dart
TopicModel(id: t.id, slug: t.slug, title: t.title, description: t.description, totalPhotos: t.totalPhotos)
```

But I also need to import `TopicModel`. The `topicLocalDataSourceProvider` returns `TopicLocalDataSource` whose `getTopics()` returns `List<TopicModel>`. So I need:

```dart
import 'package:musea/features/discover/data/models/topic_model.dart';
```

Let me also check what `TopicModel.toEntity()` looks like:
```dart
Topic toEntity() => Topic(
    id: id,
    slug: slug,
    title: title,
    description: description,
    totalPhotos: totalPhotos,
    coverPhoto: coverPhoto?.toEntity(),
    link: links?.self,
);
```

OK good. Let me also think about the `_refreshInBackground` method. I'm creating `TopicModel` instances from `Topic` entities. But I could also use the `TopicModel.toEntity()` on `topicLocalDataSource.getTopics()` to get entities from cache - which I already do.

For the refresh path, I think I should probably write it differently. Let me reconsider.

In `_init()`:
- `localDataSource.getTopics()` returns `List<TopicModel>`
- I convert to entities with `.map((e) => e.toEntity()).toList()`

In `_refreshInBackground()`:
- `repository.getTopics()` returns `Either<Failure, List<Topic>>`
- On success, I need to save models: convert back to `TopicModel` and call `localDataSource.saveTopics()`
- Then if state was empty, update state with entities

The test creates `Topic` entities directly (not models). For the mock `mockRepo.getTopics()`, it returns `Right([Topic(...)])`. Good.

But wait, I have a potential issue: in the `_refreshInBackground()`, I'm creating `TopicModel` instances from entities but losing the `coverPhoto` and `links` data. Let me see... looking at `Topic` entity:

```dart
class Topic {
  final String id;
  final String slug;
  final String title;
  final String? description;
  final int totalPhotos;
  final Photo? coverPhoto;
  final String? link;
  ...
}
```

When caching, the existing `cacheTopics` already removes `cover_photo` from JSON to avoid Hive serialization issues. So I should do the same here. Let me just create minimal TopicModel instances — this is fine since cover photo data isn't critical for the tab bar display.

Actually, looking at the TopicModel more carefully, `coverPhoto` is nullable and `links` is nullable. So I can just omit them:

```dart
TopicModel(id: t.id, slug: t.slug, title: t.title, description: t.description, totalPhotos: t.totalPhotos)
```

But wait, this won't compile if `TopicModel` expects all required params. Let me check... `id`, `slug`, `title`, `totalPhotos` are required. `description`, `coverPhoto`, `links` are optional. So it should work.

OK let me also remove the `forceRefresh` method from the plan — the user said no force refresh needed. Actually, the user said pull-to-refresh should only refresh photos, not topics. So I'll remove the forceRefresh method entirely since nothing uses it.

Let me also consider: do I need the `TopicModel` import? The `topicLocalDataSourceProvider` already returns `TopicLocalDataSource` which has methods that return `List<TopicModel>`. If I'm calling `.toEntity()` on those models, I need the `TopicModel` import in the provider file.

Let me check the current imports in topics_provider.dart:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/features/discover/domain/entities/topic.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/presentation/providers/photos_provider.dart';
```

I'll need to add:
```dart
import 'package:musea/features/discover/data/models/topic_model.dart';
```

Wait, no. The `topicLocalDataSourceProvider` is defined in `photos_provider.dart`. Let me check if I need to import TopicModel explicitly... The `topicLocalDataSourceProvider` returns a `TopicLocalDataSource`. The `dataSource.getTopics()` returns `List<TopicModel>`. If I call `.toEntity()` on the items, I need the `TopicModel` import.

But actually, looking at my code more carefully:

```dart
final cached = await localDataSource.getTopics();
if (cached.isNotEmpty) {
  state = cached.map((e) => e.toEntity()).toList();
}
```

Here `cached` is `List<TopicModel>`, and `.toEntity()` is a method on `TopicModel`. But this won't resolve unless `TopicModel` is imported or `topicLocalDataSourceProvider` provides the type that has `.toEntity()`... Actually, since `TopicLocalDataSource.getTopics()` returns `List<TopicModel>`, the dart analyzer will infer the type. But `TopicModel.toEntity()` is defined in `topic_model.dart`. If the compiler can't see the definition, it might not be able to call it.

Hmm, actually, Dart's type inference should handle this. The local variable `cached` will be typed as `List<TopicModel>` because that's what `getTopics()` returns. But the compiler needs to be able to see the `TopicModel` class definition to know it has a `toEntity()` method.

The import chain is:
- `topics_provider.dart` imports `photos_provider.dart` which imports `topic_local_datasource.dart`
- But `topic_local_datasource.dart` doesn't import `topic_model.dart` — it only uses `TopicModel` in its method signature through an abstract class

Actually wait, the abstract class `TopicLocalDataSource` has methods that return `List<TopicModel>`, so the type is visible through the method signature. But the concrete class `TopicModel` with its `toEntity()` method — is that accessible?

In Dart, when you have a variable typed as `List<TopicModel>`, you can call any method on `TopicModel` even if you haven't directly imported it — IF the type is resolved through the return type of a method on an imported class. The Dart compiler needs to see the definition to compile it, but the import of the abstract class/interface that uses it should transitively expose it.

Actually, this might cause issues in Dart since imports are explicit, not transitive for members. Let me just add the import to be safe:

```dart
import 'package:musea/features/discover/data/models/topic_model.dart';
```

OK let me proceed with the plan. I need to be careful about what TopicModel I'm importing. Let me also check if there's a `TopicLocalDataSource` import needed... Actually, `topicLocalDataSourceProvider` is defined in `photos_provider.dart`, and its type is `TopicLocalDataSource`. So I need:

```dart
import 'package:musea/features/discover/data/datasources/topic_local_datasource.dart';
```

This gives access to `TopicLocalDataSource`. And for `TopicModel`:

```dart
import 'package:musea/features/discover/data/models/topic_model.dart';
```

OK, let me also reconsider whether I need `coverPhoto` and `links` in the TopicModel conversion. In `_refreshInBackground`, I'm converting `Topic` entities back to `TopicModel` for storage. The `Topic` entity has `coverPhoto` and `link` fields. I should preserve them if they exist.

```dart
TopicModel(
  id: t.id,
  slug: t.slug,
  title: t.title,
  description: t.description,
  totalPhotos: t.totalPhotos,
  coverPhoto: t.coverPhoto != null ? PhotoModel.fromEntity(t.coverPhoto) : null,
)
```

Hmm, but `PhotoModel` has its own freezed constructor. And `TopicModel.links` is also optional. Let me just do:

```dart
final models = topics.map((t) {
  return TopicModel(
    id: t.id,
    slug: t.slug,
    title: t.title,
    description: t.description,
    totalPhotos: t.totalPhotos,
  );
}).toList();
```

Since `coverPhoto` is always removed during serialization anyway (the existing `cacheTopics` removes it), this is fine.

But wait — I don't have `PhotoModel.fromEntity()` or similar. Let me check if PhotoModel has a `fromEntity` method...

Looking at the existing code, `cacheTopics` just does `topic.toJson()` and then removes `cover_photo`. The `Topic.toJson()` is generated by freezed and includes all fields. But when saving, we just remove `cover_photo`. So when the response comes back from API and gets saved, the `coverPhoto` might be present on the TopicModel returned from the API. But when the TopicListNotifier creates models from entities (in the _refreshInBackground path), coverPhoto is available on the Topic entity.

For simplicity, let me just skip coverPhoto when converting entity → model. It's not needed for the tab bar display (the tab only shows title text).

Alright, let me finalize the plan. Let me make sure the test code is correct too. Looking at the current test's `topicLocalDataSourceProvider.overrideWithValue` — I need to check that `TopicLocalDataSource` is accessible in the test.

The test needs:
```dart
import 'package:musea/features/discover/data/datasources/topic_local_datasource.dart';
```

Wait, but `TopicLocalDataSource` is an abstract class from `topic_local_datasource.dart`. The test needs to mock it. Let me use `MockTopicLocalDataSource`.

Also, `photoRepositoryProvider` is in `photos_provider.dart`, which is imported in the test.

Let me also reconsider the test file path. Should it go in:
- `test/features/discover/presentation/providers/topics_provider_test.dart`

Or since this is testing the new notifier, it could go there. But since the topics_provider.dart file is in `presentation/providers/`, the test should mirror that.

OK, let me finalize the plan now.

One more thing — for the `topicLocalDataSourceProvider` override in tests, I should check the test file I'm writing. The `topicLocalDataSourceProvider` is defined in `photos_provider.dart`. So I import it from there:

```dart
import 'package:musea/features/discover/presentation/providers/photos_provider.dart';
```

This imports both `topicLocalDataSourceProvider` and `photoRepositoryProvider`.

For `TopicModel`, the test needs to create models to exercise `saveTopics` and `getTopics`. But in the notifier test, I'm moking the data source, so I don't actually need TopicModel instances. I just need to control what `getTopics()` returns.

In the notifier, `getTopics()` returns `List<TopicModel>`. So in the mock:

```dart
when(() => mockDS.getTopics()).thenAnswer((_) async => []);
```

This returns an empty list of TopicModels implicitly.

Wait actually, `when(() => mockDS.getTopics())` — mocktail needs to know the return type. Since `getTopics()` returns `Future<List<TopicModel>>`, the mock needs to know about `TopicModel`. Let me think...

Actually, mocktail should handle this automatically since `MockTopicLocalDataSource` implements `TopicLocalDataSource` which has `Future<List<TopicModel>> getTopics()`. So `when(() => mockDS.getTopics())` will resolve correctly.

But in my first test:
```dart
when(() => mockDS.getTopics()).thenAnswer((_) async => []);
```

This should work because `[]` is compatible with `List<TopicModel>`.

In the second test:
```dart
when(() => mockDS.getTopics()).thenAnswer((_) async => [
  const Topic(id: '1', slug: 'nature', title: 'Nature', totalPhotos: 10),
]);
```

Wait, this won't work because `getTopics()` returns `List<TopicModel>` but I'm returning `List<Topic>`. Let me fix this.

Actually, the provider does:
```dart
final cached = await localDataSource.getTopics(); // Returns List<TopicModel>
if (cached.isNotEmpty) {
  state = cached.map((e) => e.toEntity()).toList(); // Converts to List<Topic>
}
```

So the mock should return `List<TopicModel>`, not `List<Topic>`. Let me fix the test:

```dart
when(() => mockDS.getTopics()).thenAnswer((_) async => [
  const TopicModel(id: '1', slug: 'nature', title: 'Nature', totalPhotos: 10),
]);
```

This needs `import 'package:musea/features/discover/data/models/topic_model.dart';` in the test.

OK let me fix all test cases:

```dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musea/core/errors/failures.dart';
import 'package:musea/features/discover/data/datasources/topic_local_datasource.dart';
import 'package:musea/features/discover/data/models/topic_model.dart';
import 'package:musea/features/discover/domain/entities/topic.dart';
import 'package:musea/features/discover/domain/repositories/photo_repository.dart';
import 'package:musea/features/discover/presentation/providers/photos_provider.dart';
import 'package:musea/features/discover/presentation/providers/topics_provider.dart';
```

And the mock:
```dart
class MockPhotoRepository extends Mock implements PhotoRepository {}

class MockTopicLocalDataSource extends Mock implements TopicLocalDataSource {}
```

Test 1 - no cache:
```dart
when(() => mockDS.getTopics()).thenAnswer((_) async => []);
when(() => mockDS.getLastUpdatedAt()).thenAnswer((_) async => null);
container.read(topicsProvider);
expect(container.read(topicsProvider), isEmpty);
```

Test 2 - valid cache:
```dart
when(() => mockDS.getTopics()).thenAnswer((_) async => [
  const TopicModel(id: '1', slug: 'nature', title: 'Nature', totalPhotos: 10),
]);
when(() => mockDS.getLastUpdatedAt()).thenAnswer((_) async => DateTime.now());
```

Test 3 - stale cache:
```dart
when(() => mockDS.getTopics()).thenAnswer((_) async => [
  const TopicModel(id: '1', slug: 'nature', title: 'Nature', totalPhotos: 10),
]);
when(() => mockDS.getLastUpdatedAt()).thenAnswer((_) async =>
    DateTime.now().subtract(const Duration(hours: 25)));
when(() => mockRepo.getTopics()).thenAnswer((_) async =>
    Right([const Topic(id: '1', slug: 'nature', title: 'Nature', totalPhotos: 10)]));
when(() => mockDS.saveTopics(any())).thenAnswer((_) async => {});
```

After container creation, read the provider:
```dart
final topics = container.read(topicsProvider);
expect(topics.length, 1);
```

Wait, there's a subtle issue. The `TopicListNotifier.build()` runs `_init()` which is async. The `build()` returns `[]` synchronously. Then when `_init()` completes, it may update state. But in the test, after `container.read(topicsProvider)`, the notifier has been built and `_init()` has started but may not have completed.

For the "no cache" test, after `_init()` runs, state should be `[]` (no cache found). So `container.read(topicsProvider)` should return `[]` immediately after build(), since build() returns `[]` and _init() does nothing to state for this case.

For the "valid cache" test:
- `build()` returns `[]`
- `_init()` runs, finds cached topics, sets state
- This all happens synchronously in the same microtask... actually, `_init` is async, so the first `await` in it yields to the event loop. So `build()` returns `[]`, then `_init()` is scheduled.

Hmm, this is tricky with testing. The state won't be updated synchronously. Let me think about how to test this properly.

In Riverpod, when the Notifier's `build()` runs:
1. `build()` is called
2. Inside `build()`, `_init()` is called (starts async work)
3. `build()` returns `[]` — this is the initial state
4. Event loop processes the first `await` in `_init()`, which reads from `mockDS.getTopics()` (returns a Future)

For testing, I need to pump the microtask queue. In Flutter tests, I can use `await Future.delayed(Duration.zero)` or `await tester.pump()`.

So the test should be:

```dart
final container = ProviderContainer(...);
// Build the notifier
container.read(topicsProvider);
// Allow async work to complete
await Future.delayed(Duration.zero);
// Now state should be updated
expect(container.read(topicsProvider), ...);
```

But wait, `container.read(topicsProvider)` just reads the current value — it doesn't trigger the notifier's `build()` if it hasn't been built yet. Actually, `container.read` returns the current state of the provider. If the provider hasn't been read before, it builds the notifier.

To trigger build: `container.read(topicsProvider)` — this calls `TopicListNotifier.build()`, which returns `[]` and starts `_init()`.

Then I need to wait for the async work. `await Future.delayed(Duration.zero)` should be enough.

After that:
- For "cache valid" tests: state should be updated with cached topics
- For "no cache" tests: state should still be `[]`
- For "cache stale" tests: state should be cached topics, and background refresh should have been triggered

Let me also think about the `container.read` vs `container.watch` for testing. For simple value checks, `read` is fine in tests.

OK, I think I have a complete understanding now. Let me write the plan properly.

Actually, for the "stale cache" test, the tricky part is verifying the background refresh. `mockRepo.getTopics()` should be called, but since it's async, I need to wait for it. Let me adjust.

Also, for the test that verifies no network request when fresh, the issue is that `_init()` won't proceed past the "check TTL" check, so `_refreshInBackground()` is never called. I just need to verify `verifyNever(() => mockRepo.getTopics())`.

Let me now also think about the DiscoverPage changes.

Current discover_page.dart uses:
```dart
final topicsAsync = ref.watch(topicsProvider);
...
topicsAsync.when(
  data: (topics) => _buildFilterTabs(topics),
  loading: () => const SizedBox(height: 38, child: Center(child: LoadingIndicator())),
  error: (error, stack) => const SizedBox.shrink(),
),
```

After change:
```dart
final topics = ref.watch(topicsProvider);
...
_buildFilterTabs(topics),
```

And in `_buildFilterTabs`, when `topics` is empty, only "All" tab is shown.

Also, the `RefreshIndicator.onRefresh` currently does:
```dart
ref.invalidate(photosProvider);
ref.invalidate(topicsProvider);
```

After change, should only do:
```dart
ref.invalidate(photosProvider);
```

No need to invalidate topics at all.

And the pull-to-refresh handler should also invalidate `topicPhotosProvider` if there's a selected topic. Actually, let me check the current code... Looking at line 96-99:
```dart
onRefresh: () async {
  ref.invalidate(photosProvider);
  ref.invalidate(topicsProvider);
},
```

After change, just remove `ref.invalidate(topicsProvider)`.

OK, let me also think about the `TopicModel` import issue in tests more carefully. When I write:
```dart
when(() => mockDS.getTopics()).thenAnswer((_) async => [
  const TopicModel(id: '1', slug: 'nature', title: 'Nature', totalPhotos: 10),
]);
```

This needs the `TopicModel` class imported. Since `TopicModel` is freezed, the `const` constructor should work because all required fields are provided as constants. But wait, `TopicModel` has `coverPhoto` as `PhotoModel?` and `links` as `TopicLinksModel?`, both optional. So `const TopicModel(id: '1', slug: 'nature', title: 'Nature', totalPhotos: 10)` should work.

Hmm actually, the freezed union — `TopicModel` is defined as:
```dart
@freezed
class TopicModel with _$TopicModel {
  const TopicModel._();
  const factory TopicModel({...}) = _TopicModel;
```

The `const factory` means you can create const instances. Should be fine.

One more issue: the `_cachedTopics` returns `List<TopicModel>`, but the mock's `when(() => mockDS.getTopics())` returns `Future<List<TopicModel>>`. Dart's mocktail should handle this fine.

Let me also think about whether I need to add `onTopicPhotos` invalidation to pull-to-refresh. Currently:
- When `_selectedTopicSlug` is not null, the photos come from `topicPhotosProvider` instead of `photosProvider`
- Pull-to-refresh currently invalidates `photosProvider` only
- If user is viewing a topic's photos and pulls to refresh, should it refresh?

Looking at the current code (line 96-99):
```dart
onRefresh: () async {
  ref.invalidate(photosProvider);
  ref.invalidate(topicsProvider);
},
```

It invalidates both. But `photosProvider` is for the "all" photos, not topic photos. So there's actually a bug where if you're viewing a topic and pull to refresh, it won't properly refresh. But that's outside the scope of this task.

For this task, I just need to remove `ref.invalidate(topicsProvider)`.

OK I'm ready to write the complete plan now. Let me also think about the `TopicListNotifier.forceRefresh()` method — do I need it? The user said pull-to-refresh shouldn't refresh topics. But what if some other code path still invalidates topics? Let me check:

Currently, `ref.invalidate(topicsProvider)` is called in the pull-to-refresh handler. After my change, this won't exist. But `ref.invalidate(topicsProvider)` with a NotifierProvider... hmm, invalidating a NotifierProvider would rebuild the notifier, which would call `build()` again, and `_init()` would check TTL and potentially refresh. That might be fine, but nothing should be calling it anymore.

Actually, `ref.invalidate(topicsProvider)` on a NotifierProvider would work differently than on a FutureProvider. With a NotifierProvider, invalidating the provider causes it to be rebuilt when next watched. The `build()` method would be called again, starting the `_init()` flow.

But since nothing should be invalidating `topicsProvider` anymore (I removed it from pull-to-refresh), this shouldn't be an issue.

OK, one last thing. I need to remove the `forceRefresh` method I was considering. The user explicitly said pull should only refresh content, not topics. So there's no need for any public refresh method on the notifier.

Alright, let me write the final plan now.

For the plan, I'll focus on the following tasks:
1. Extend TopicLocalDataSource ✓
2. Create TopicListNotifier ✓
3. Simplify DiscoverPage
4. Simplify PhotoRepositoryImpl
5. Update existing tests (discover_page_test, app_router_test)

Wait, I should combine some of these. Let me think about what makes sense:

Task 1: TopicLocalDataSource extension + tests
Task 2: TopicListNotifier SWR provider + tests
Task 3: Simplify DiscoverPage + PhotoRepositoryImpl + update existing tests

Actually, let me separate more cleanly:

Task 1: TopicLocalDataSource extension + tests
Task 2: TopicListNotifier SWR provider + tests
Task 3: Simplify PhotoRepositoryImpl
Task 4: Simplify DiscoverPage
Task 5: Update existing tests

Let me also think about whether to remove the old `cacheTopics` and `getCachedTopics` methods from TopicLocalDataSource. The user's spec says to saveTopics and getTopics. The old methods `cacheTopics` and `getCachedTopics` are no longer needed since the caching logic now lives in the provider.

I should keep backward compatibility: rename `cacheTopics` to `saveTopics` and `getCachedTopics` to `getTopics`. The old methods are only called from `PhotoRepositoryImpl.getTopics()` (which I'm simplifying), so I can just remove them.

OK final plan structure:
1. Task 1: Extend TopicLocalDataSource
2. Task 2: Create TopicListNotifier + update topicsProvider
3. Task 3: Simplify PhotoRepositoryImpl.getTopics()
4. Task 4: Simplify DiscoverPage
5. Task 5: Update existing tests<｜end▁of▁thinking｜>Now I have full context. Let me write the implementation plan.

<｜｜DSML｜｜tool_calls>
<｜｜DSML｜｜invoke name="Write">
<｜｜DSML｜｜parameter name="content" string="true"># Topic Cache SWR Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate topic loading spinners by showing cached topics instantly (SWR pattern), refreshing in background once per 24h.

**Architecture:** Extend `TopicLocalDataSource` to store a `lastUpdatedAt` timestamp alongside topics. Create a `TopicListNotifier` (Riverpod `Notifier`) that reads cache first, checks TTL, and fires background refreshes. The `topicsProvider` changes from `FutureProvider` to `NotifierProvider`. `DiscoverPage` no longer needs `when(loading: ...)` / `when(error: ...)` for topics. `PhotoRepositoryImpl.getTopics()` becomes a pure network call without cache fallback.

**Tech Stack:** Flutter, Riverpod, Hive

---

### Task 1: Extend TopicLocalDataSource with timestamp storage

**Files:**
- Modify: `lib/features/discover/data/datasources/topic_local_datasource.dart`
- Test: `test/features/discover/data/datasources/topic_local_datasource_test.dart`

- [ ] **Step 1: Write the failing test for TopicLocalDataSource**

Create `test/features/discover/data/datasources/topic_local_datasource_test.dart`:

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:musea/features/discover/data/datasources/topic_local_datasource.dart';
import 'package:musea/features/discover/data/models/topic_model.dart';

void main() {
  late TopicLocalDataSource dataSource;

  setUp(() async {
    Hive.init(Directory.systemTemp.path);
    dataSource = TopicLocalDataSourceImpl();
  });

  tearDown(() async {
    await dataSource.clearCache();
  });

  test('saveTopics stores topics and timestamp', () async {
    final topics = [
      const TopicModel(id: '1', slug: 'nature', title: 'Nature', totalPhotos: 10),
      const TopicModel(id: '2', slug: 'architecture', title: 'Architecture', totalPhotos: 5),
    ];

    await dataSource.saveTopics(topics);
    final cached = await dataSource.getTopics();
    final lastUpdated = await dataSource.getLastUpdatedAt();

    expect(cached.length, 2);
    expect(cached[0].id, '1');
    expect(cached[1].id, '2');
    expect(lastUpdated, isNotNull);
  });

  test('getTopics returns empty list when cache is empty', () async {
    final cached = await dataSource.getTopics();
    expect(cached, isEmpty);
  });

  test('getLastUpdatedAt returns null when cache is empty', () async {
    final lastUpdated = await dataSource.getLastUpdatedAt();
    expect(lastUpdated, isNull);
  });

  test('clearCache removes all data', () async {
    final topics = [
      const TopicModel(id: '1', slug: 'nature', title: 'Nature', totalPhotos: 10),
    ];

    await dataSource.saveTopics(topics);
    await dataSource.clearCache();

    final cached = await dataSource.getTopics();
    final lastUpdated = await dataSource.getLastUpdatedAt();

    expect(cached, isEmpty);
    expect(lastUpdated, isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/discover/data/datasources/topic_local_datasource_test.dart`
Expected: FAIL — `saveTopics` / `getLastUpdatedAt` not defined

- [ ] **Step 3: Rewrite TopicLocalDataSource with new interface**

Replace the file at `lib/features/discover/data/datasources/topic_local_datasource.dart`:

```dart
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:musea/features/discover/data/models/topic_model.dart';

abstract class TopicLocalDataSource {
  Future<void> saveTopics(List<TopicModel> topics);
  Future<List<TopicModel>> getTopics();
  Future<DateTime?> getLastUpdatedAt();
  Future<void> clearCache();
}

class TopicLocalDataSourceImpl implements TopicLocalDataSource {
  static const String _boxName = 'topics_cache';
  static const String _dataKey = 'topic_data';
  Box<dynamic>? _box;

  Future<Box<dynamic>> get box async {
    _box ??= await Hive.openBox(_boxName);
    return _box!;
  }

  @override
  Future<void> saveTopics(List<TopicModel> topics) async {
    final topicBox = await box;
    final jsonList = topics.map((topic) {
      final json = topic.toJson();
      json.remove('cover_photo');
      return json;
    }).toList();

    final payload = {
      'topics': jsonList,
      'lastUpdatedAt': DateTime.now().toUtc().toIso8601String(),
    };
    await topicBox.put(_dataKey, jsonEncode(payload));
  }

  @override
  Future<List<TopicModel>> getTopics() async {
    final topicBox = await box;
    final raw = topicBox.get(_dataKey);
    if (raw == null || raw is! String) return [];

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final jsonList = data['topics'] as List;
      return jsonList
          .map((json) => TopicModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<DateTime?> getLastUpdatedAt() async {
    final topicBox = await box;
    final raw = topicBox.get(_dataKey);
    if (raw == null || raw is! String) return null;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final timestamp = data['lastUpdatedAt'] as String?;
      return timestamp != null ? DateTime.parse(timestamp) : null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> clearCache() async {
    final topicBox = await box;
    await topicBox.clear();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/discover/data/datasources/topic_local_datasource_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/discover/data/datasources/topic_local_datasource.dart test/features/discover/data/datasources/topic_local_datasource_test.dart
git commit -m "feat: extend TopicLocalDataSource with timestamp-based storage"
```

---

### Task 2: Create TopicListNotifier (SWR provider)

**Files:**
- Modify: `lib/features/discover/presentation/providers/topics_provider.dart`
- Test: `test/features/discover/presentation/providers/topics_provider_test.dart`

- [ ] **Step 1: Write the failing test for TopicListNotifier**

Create `test/features/discover/presentation/providers/topics_provider_test.dart`:

```dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musea/features/discover/data/datasources/topic_local_datasource.dart';
import 'package:musea/features/discover/data/models/topic_model.dart';
import 'package:musea/features/discover/domain/entities/topic.dart';
import 'package:musea/features/discover/domain/repositories/photo_repository.dart';
import 'package:musea/features/discover/presentation/providers/photos_provider.dart';
import 'package:musea/features/discover/presentation/providers/topics_provider.dart';

class MockPhotoRepository extends Mock implements PhotoRepository {}

class MockTopicLocalDataSource extends Mock implements TopicLocalDataSource {}

void main() {
  late MockPhotoRepository mockRepo;
  late MockTopicLocalDataSource mockDS;

  setUp(() {
    mockRepo = MockPhotoRepository();
    mockDS = MockTopicLocalDataSource();
  });

  test('initial state is empty when no cache exists', () async {
    when(() => mockDS.getTopics()).thenAnswer((_) async => <TopicModel>[]);
    when(() => mockDS.getLastUpdatedAt()).thenAnswer((_) async => null);

    final container = ProviderContainer(
      overrides: [
        photoRepositoryProvider.overrideWithValue(mockRepo),
        topicLocalDataSourceProvider.overrideWithValue(mockDS),
      ],
    );
    addTearDown(container.dispose);

    container.read(topicsProvider);
    await Future.delayed(Duration.zero);

    expect(container.read(topicsProvider), isEmpty);
  });

  test('returns cached topics when cache is valid', () async {
    when(() => mockDS.getTopics()).thenAnswer((_) async => [
      const TopicModel(id: '1', slug: 'nature', title: 'Nature', totalPhotos: 10),
    ]);
    when(() => mockDS.getLastUpdatedAt()).thenAnswer((_) async => DateTime.now());

    final container = ProviderContainer(
      overrides: [
        photoRepositoryProvider.overrideWithValue(mockRepo),
        topicLocalDataSourceProvider.overrideWithValue(mockDS),
      ],
    );
    addTearDown(container.dispose);

    container.read(topicsProvider);
    await Future.delayed(Duration.zero);

    expect(container.read(topicsProvider).length, 1);
    expect(container.read(topicsProvider)[0].title, 'Nature');
  });

  test('returns cached topics and fires refresh when stale', () async {
    when(() => mockDS.getTopics()).thenAnswer((_) async => [
      const TopicModel(id: '1', slug: 'nature', title: 'Nature', totalPhotos: 10),
    ]);
    when(() => mockDS.getLastUpdatedAt()).thenAnswer((_) async =>
        DateTime.now().subtract(const Duration(hours: 25)));
    when(() => mockRepo.getTopics()).thenAnswer((_) async =>
        Right([const Topic(id: '1', slug: 'nature', title: 'Nature', totalPhotos: 10)]));
    when(() => mockDS.saveTopics(any())).thenAnswer((_) async => {});

    final container = ProviderContainer(
      overrides: [
        photoRepositoryProvider.overrideWithValue(mockRepo),
        topicLocalDataSourceProvider.overrideWithValue(mockDS),
      ],
    );
    addTearDown(container.dispose);

    container.read(topicsProvider);
    await Future.delayed(Duration.zero);

    // State should be cached data
    expect(container.read(topicsProvider).length, 1);

    // Background refresh should have been triggered
    verify(() => mockRepo.getTopics()).called(1);
  });

  test('does not fire network request when cache is fresh', () async {
    when(() => mockDS.getTopics()).thenAnswer((_) async => [
      const TopicModel(id: '1', slug: 'nature', title: 'Nature', totalPhotos: 10),
    ]);
    when(() => mockDS.getLastUpdatedAt()).thenAnswer((_) async =>
        DateTime.now().subtract(const Duration(hours: 1)));

    final container = ProviderContainer(
      overrides: [
        photoRepositoryProvider.overrideWithValue(mockRepo),
        topicLocalDataSourceProvider.overrideWithValue(mockDS),
      ],
    );
    addTearDown(container.dispose);

    container.read(topicsProvider);
    await Future.delayed(Duration.zero);

    verifyNever(() => mockRepo.getTopics());
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/discover/presentation/providers/topics_provider_test.dart`
Expected: FAIL — `TopicListNotifier` not defined, provider type mismatch

- [ ] **Step 3: Rewrite topics_provider.dart with Notifier-based SWR provider**

Replace `lib/features/discover/presentation/providers/topics_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/features/discover/data/datasources/topic_local_datasource.dart';
import 'package:musea/features/discover/data/models/topic_model.dart';
import 'package:musea/features/discover/domain/entities/topic.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/presentation/providers/photos_provider.dart';

final topicsProvider = NotifierProvider<TopicListNotifier, List<Topic>>(
  TopicListNotifier.new,
);

class TopicListNotifier extends Notifier<List<Topic>> {
  @override
  List<Topic> build() {
    _init();
    return [];
  }

  Future<void> _init() async {
    final localDataSource = ref.read(topicLocalDataSourceProvider);

    // 1. Read cache first
    final cached = await localDataSource.getTopics();
    if (cached.isNotEmpty) {
      state = cached.map((e) => e.toEntity()).toList();
    }

    // 2. Check TTL
    final lastUpdated = await localDataSource.getLastUpdatedAt();
    if (lastUpdated != null &&
        DateTime.now().difference(lastUpdated).inHours < 24) {
      return; // cache is still fresh
    }

    // 3. Background refresh
    _refreshInBackground();
  }

  Future<void> _refreshInBackground() async {
    final repository = ref.read(photoRepositoryProvider);
    final localDataSource = ref.read(topicLocalDataSourceProvider);

    final result = await repository.getTopics();
    result.fold(
      (failure) => {/* silent */},
      (topics) async {
        final models = topics
            .map((t) => TopicModel(
                  id: t.id,
                  slug: t.slug,
                  title: t.title,
                  description: t.description,
                  totalPhotos: t.totalPhotos,
                ))
            .toList();
        await localDataSource.saveTopics(models);
        if (state.isEmpty) {
          state = topics;
        }
      },
    );
  }
}

// topicPhotosProvider and TopicPhotosParams stay the same
final topicPhotosProvider = FutureProvider.family<List<Photo>, TopicPhotosParams>(
    (ref, params) async {
  final repository = ref.watch(photoRepositoryProvider);
  final result =
      await repository.getTopicPhotos(params.topicSlug, page: params.page);

  return result.fold(
    (failure) => throw Exception(failure.toString()),
    (photos) => photos,
  );
});

class TopicPhotosParams {
  final String topicSlug;
  final int page;

  TopicPhotosParams({
    required this.topicSlug,
    this.page = 1,
  });
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/discover/presentation/providers/topics_provider_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/discover/presentation/providers/topics_provider.dart test/features/discover/presentation/providers/topics_provider_test.dart
git commit -m "feat: add TopicListNotifier with SWR cache pattern"
```

---

### Task 3: Simplify PhotoRepositoryImpl.getTopics()

**Files:**
- Modify: `lib/features/discover/data/repositories/photo_repository_impl.dart`

- [ ] **Step 1: Run existing tests to confirm baseline**

Run: `flutter test test/features/discover/`
Expected: PASS (baseline before change)

- [ ] **Step 2: Simplify getTopics() to pure network + cache write**

In `lib/features/discover/data/repositories/photo_repository_impl.dart`, replace the `getTopics()` method:

```dart
@override
Future<Either<Failure, List<Topic>>> getTopics(
    {int page = 1, int perPage = 10}) async {
  try {
    final topics =
        await remoteDataSource.getTopics(page: page, perPage: perPage);
    await topicLocalDataSource.saveTopics(topics);
    return Right(topics.map((t) => t.toEntity()).toList());
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
```

- [ ] **Step 3: Run tests to verify**

Run: `flutter test test/features/discover/`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add lib/features/discover/data/repositories/photo_repository_impl.dart
git commit -m "refactor: simplify PhotoRepositoryImpl.getTopics() to pure network + cache write"
```

---

### Task 4: Simplify DiscoverPage (remove topic loading/error states)

**Files:**
- Modify: `lib/features/discover/presentation/pages/discover_page.dart`

- [ ] **Step 1: Read current discover_page.dart**

Read the file to understand the exact code to change.

- [ ] **Step 2: Replace topicsAsync with direct List<Topic> usage**

In `lib/features/discover/presentation/pages/discover_page.dart`:

Change line 63 from:
```dart
final topicsAsync = ref.watch(topicsProvider);
```
to:
```dart
final topics = ref.watch(topicsProvider);
```

Replace lines 86-93 (the topics `when(...)` block):
```dart
            // Fixed filter tabs
            topicsAsync.when(
              data: (topics) => _buildFilterTabs(topics),
              loading: () => const SizedBox(
                height: 38,
                child: Center(child: LoadingIndicator()),
              ),
              error: (error, stack) => const SizedBox.shrink(),
            ),
```
with:
```dart
            // Fixed filter tabs
            _buildFilterTabs(topics),
```

Replace line 99 (remove topics invalidation from onRefresh):
```dart
                  ref.invalidate(topicsProvider);
```
remove this line.

- [ ] **Step 3: Run existing tests to verify discover page still works**

Run: `flutter test test/features/discover/presentation/pages/discover_page_test.dart`
Expected: The test at line 131-199 (search bar and filter tabs remain fixed) should pass — the topics are overridden with data, so `_buildFilterTabs` should render them. The loading/error state tests were never tested specifically, so removing them shouldn't break anything.

- [ ] **Step 4: Commit**

```bash
git add lib/features/discover/presentation/pages/discover_page.dart
git commit -m "refactor: remove topic loading/error states from DiscoverPage"
```

---

### Task 5: Update existing tests for new provider syntax

**Files:**
- Modify: `test/features/discover/presentation/pages/discover_page_test.dart`
- Modify: `test/router/app_router_test.dart`

- [ ] **Step 1: Update discover_page_test.dart**

In `test/features/discover/presentation/pages/discover_page_test.dart`, the `topicsProvider` overrides need to change from:

```dart
topicsProvider.overrideWith((ref) => <Topic>[]),
```
to:
```dart
topicsProvider.overrideWith((ref) => <Topic>[]),
```

Wait — `NotifierProvider.overrideWith` takes a `Create<TopicListNotifier, List<Topic>>`, not a `List<Topic>` directly. So the override syntax is different.

For `NotifierProvider`, to override with a simple value in tests, we need to use `overrideWithValue`:

Actually, in Riverpod 2.x, `NotifierProvider` supports `overrideWithValue`:
```dart
topicsProvider.overrideWithValue(<Topic>[]),
```

Hmm, actually `overrideWithValue` on a `NotifierProvider` would override with a value of the same type as the state (`List<Topic>`), not with a notifier. Let me check...

In Riverpod, `overrideWith` on a NotifierProvider takes a function that creates a Notifier. `overrideWithValue` takes a value that matches the provider's state type. But wait, NotifierProvider's overrideWithValue — does it exist?

Actually, for Riverpod, `overrideWith` on `NotifierProvider` should work like this:
```dart
topicsProvider.overrideWith(TopicListNotifier.new),
```

But for tests where we just want to inject a static list, we can't easily do that with a NotifierProvider's `overrideWith`. We'd need a mock Notifier.

Hmm, but the current tests use:
```dart
topicsProvider.overrideWith((ref) => <Topic>[]),
```

This works with `FutureProvider` because you can override a `FutureProvider` with a sync value. For `NotifierProvider`, the override signature is different.

Let me think about this. The cleanest approach for tests:

Option A: Create a simple notifier that returns a fixed list:
```dart
class FakeTopicListNotifier extends Notifier<List<Topic>> {
  final List<Topic> topics;
  FakeTopicListNotifier(this.topics);

  @override
  List<Topic> build() => topics;
}
```
And use `topicsProvider.overrideWith(() => FakeTopicListNotifier([]))` — wait, this doesn't work because `TopicListNotifier.new` expects a `Ref` parameter.

Actually, looking at Riverpod: `NotifierProvider`'s `overrideWith` takes a `Create<Notifier>` which is `Notifier Function(Ref)`. The `TopicListNotifier.new` is a constructor tear-off that matches `Ref Function()` → `TopicListNotifier`.

So in tests, we'd do:
```dart
topicsProvider.overrideWith((ref) {
  final notifier = TopicListNotifier();
  notifier.state = <Topic>[];
  return notifier;
}),
```

Actually, that's a bit clunky. Let me look at official Riverpod testing patterns.

In Riverpod 2.x, for overriding a NotifierProvider, the recommended way is:

```dart
final myProvider = NotifierProvider<MyNotifier, int>(MyNotifier.new);

// In test:
final container = ProviderContainer(
  overrides: [
    myProvider.overrideWith((ref) => MyNotifier()),
  ],
);
```

But this creates a real `MyNotifier`, which will run `build()`. The alternative is to override the Notifier's return from build or set its state.

For our case, the simplest approach that works:

```dart
topicsProvider.overrideWith((ref) {
  final notifier = TopicListNotifier();
  // Set state directly to bypass async init
  notifier.state = <Topic>[];
  return notifier;
}),
```

Wait, but this creates a TopicListNotifier that will call `_init()` in build(), which will try to read from `topicLocalDataSourceProvider` and `photoRepositoryProvider`. Those might not be overridden in the test.

Hmm, this is getting complicated. Let me think of a cleaner approach.

Actually, the simplest way is to just use `overrideWithValue` with a Notifier subclass. Or, even simpler, use `Provider` instead of `NotifierProvider` for the test override.

Wait, actually in Riverpod's testing, `NotifierProvider.overrideWith` takes a factory. If I create a simple notifier:

```dart
class StaticTopicListNotifier extends Notifier<List<Topic>> {
  StaticTopicListNotifier(this.initialTopics);
  final List<Topic> initialTopics;

  @override
  List<Topic> build() => initialTopics;
}
```

Then:
```dart
topicsProvider.overrideWith((ref) => StaticTopicListNotifier([])),
```

But this won't work because `NotifierProvider` expects its notifier to match precisely. Actually, in Riverpod, the notifier type is part of the provider type: `NotifierProvider<Type, State>`. `StaticTopicListNotifier` would need to be `Notifier<List<Topic>>` which it is. So it should work.

Actually, even simpler - in tests, for a `NotifierProvider`, we can just override the provider's entire value with `overrideWithValue`. Let me check the Riverpod API...

In Riverpod 2.x:
- `overrideWithValue` exists on `Provider` and `StreamProvider`
- For `NotifierProvider`, `overrideWith` creates a new notifier instance

OK so the cleanest approach for tests is:

```dart
topicsProvider.overrideWith((ref) {
  final notifier = TopicListNotifier();
  notifier.someSetStateMethod(<Topic>[]);
  return notifier;
}),
```

But TopicListNotifier doesn't expose a way to set state externally (state is protected without writing to it directly... wait, it's actually public in Riverpod Notifier).

Hmm, in Riverpod, `Notifier.state` has a public setter. So:
```dart
topicsProvider.overrideWith((ref) {
  final notifier = TopicListNotifier();
  notifier.state = <Topic>[];
  return notifier;
}),
```

But this will still call `_init()` which tries to use providers that might not be overridden.

Actually, let me look at how this test works:

```dart
// Current discover_page_test lines 99-110:
await tester.pumpWidget(
  ProviderScope(
    overrides: [
      authBootstrapSessionProvider.overrideWithValue(null),
      authRedirectUriProvider.overrideWithValue(...),
      photosProvider(1).overrideWith((ref) => photos),
      topicsProvider.overrideWith((ref) => <Topic>[]),
    ],
    child: const MaterialApp(home: DiscoverPage()),
  ),
);
```

These `overrideWith` calls on `FutureProvider` are returning a synchronous value. For the new `NotifierProvider`, we need something similar.

The simplest, most reliable approach: Use a helper class for testing.

Actually wait, I just realized something. In Riverpod, `Provider.overrideWithValue` works for any provider if you pass the correct type. Let me check if `NotifierProvider` has `overrideWithValue`...

Looking at the Riverpod source, `overrideWithValue` is defined on the `Provider` superclass. `NotifierProvider` extends `Provider`. So it should have `overrideWithValue`.

But what type does it take? `Provider.overrideWithValue<NewValue>(NewValue value)`. For `NotifierProvider<TopicListNotifier, List<Topic>>`, `NewValue` would be the value type...

Actually no, `overrideWithValue` on `Provider` wouldn't work because `NotifierProvider` has a different structure. Let me check again.

In Riverpod 2.x:
- `Provider.overrideWithValue(T value)` — for Provider
- `NotifierProvider.overrideWith(Create<Notifier> create)` — for NotifierProvider

So for NotifierProvider, you can only override with a Notifier factory.

OK, the cleanest approach that minimizes changes to tests is to create a minimal notifier for testing:

Actually, you know what, let me just use a different, simpler approach. Let me check if `topicsProvider.overrideWith((ref) => <Topic>[])` will work. With Dart's generics, the overrideWith method expects a type based on the provider type. For `NotifierProvider<TopicListNotifier, List<Topic>>`, `overrideWith` expects `Create<TopicListNotifier, List<Topic>>`.

```dart
// This WON'T work:
topicsProvider.overrideWith((ref) => <Topic>[]), // ERROR: List<Topic> is not a Notifier
```

So I have two options:
1. Create a helper notifier class
2. Make the notifier readable from a simpler provider

I think option 1 is cleaner. Let me add a simple helper to the test files:

For tests, the approach in Riverpod is typically to mock the notifier. Since we use mocktail, we can create a mock notifier... but that's more complex. Let me create a simple notifier subclass:

```dart
class TestTopicListNotifier extends Notifier<List<Topic>> {
  final List<Topic> _initialTopics;
  TestTopicListNotifier(this._initialTopics);

  @override
  List<Topic> build() => _initialTopics;
}
```

Usage:
```dart
topicsProvider.overrideWith((ref) => TestTopicListNotifier(<Topic>[])),
```

This is clean and works. The widget tests just need the topics list to be a specific value, they don't need SWR behavior.

Let me define `TestTopicListNotifier` in the test file. I'll add it as a private class at the test level... but it needs to be accessible in both `discover_page_test.dart` and `app_router_test.dart`. Since it's used in multiple test files, I could either:
1. Define it in each test file
2. Create a shared test helper

I'll define it in each test file since it's just 3 lines and avoids coupling test files.

Actually, even simpler: I can just write it inline. Each test file needs it once.

Wait, looking at the existing tests more carefully, the test override doesn't call `build()` on the notifier unless the widget is built and the provider is read. So the TestTopicListNotifier just needs to return a static list from `build()`.

Let me also make sure the import is right. The test imports `topics_provider.dart` which now exports `topicsProvider`, `TopicListNotifier`, `topicPhotosProvider`, and `TopicPhotosParams`. And the `Notifier` base class comes from `flutter_riverpod`.

For the test files, I'll also need:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
```
for `Notifier` and `ProviderContainer`.

The existing tests already import `flutter_riverpod`, so that's fine.

Let me finalize:

In each test file that overrides `topicsProvider`:
```dart
class TestTopicListNotifier extends Notifier<List<Topic>> {
  final List<Topic> topics;
  TestTopicListNotifier(this.topics);
  @override
  List<Topic> build() => topics;
}
```

And the override:
```dart
topicsProvider.overrideWith((ref) => TestTopicListNotifier(<Topic>[])),
```

Now, should I also add `riverpod` import? In the tests, they already import `flutter_riverpod` (for `ProviderScope`, `ProviderContainer`). The `Notifier` class is from `flutter_riverpod` too. So it should be fine.

OK let me write the task description properly now.

Actually, for the `router/app_router_test.dart` the import of `Notifier` might be an issue. Let me check what it imports currently.

I already read it partially. It imports:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
...
```

Should be fine. `Notifier` is available from `flutter_riverpod`.

Wait, actually `Notifier` was added in Riverpod 2.3+ or similar. Let me check what version the project uses... Looking at pubspec.yaml imports: `flutter_riverpod`. The version isn't specified in the code I've seen, but it should support `Notifier` since the project uses Riverpod 2.x patterns.

Actually, going back to simpler approach — for the widget tests, I might not even need a separate class. Looking at how `ProviderContainer` works in the tests...

Actually, the widget tests use `ProviderScope` with `overrides`. The `overrideWith` for NotifierProvider needs a Notifier factory. So I need the helper class.

But wait, there's yet another approach. Since `topicsProvider` is now a `NotifierProvider`, and the widget tests wrap their widget in `ProviderScope`, I can override using:

```dart
topicsProvider.overrideWithProvider(
  NotifierProvider<TopicListNotifier, List<Topic>>(
    (ref) => TopicListNotifier()..state = <Topic>[],
  ),
),
```

No, that's still verbose. Let me stick with the simple helper class.

OK, I think I've analyzed this enough. Let me write the plan task 5.

Actually, wait - `Notifier` might not need to be imported explicitly. In `flutter_riverpod`, the `Notifier` class is exported. But for the test file, it already imports `flutter_riverpod`. So `Notifier` should be available.

Let me just write the plan now. I've been overthinking this.<｜end▁of▁thinking｜>

<｜｜DSML｜｜tool_calls>
<｜｜DSML｜｜invoke name="Write">
<｜｜DSML｜｜parameter name="content" string="true">### Task 5: Update existing tests for new provider syntax

**Files:**
- Modify: `test/features/discover/presentation/pages/discover_page_test.dart`
- Modify: `test/router/app_router_test.dart`

- [ ] **Step 1: Update discover_page_test.dart provider overrides**

In `test/features/discover/presentation/pages/discover_page_test.dart`, `topicsProvider` is now a `NotifierProvider` instead of `FutureProvider`. The override syntax changes from `overrideWith((ref) => <Topic>[])` to `overrideWith` with a notifier factory.

Add this helper class near the top of the file (after imports):

```dart
class TestTopicListNotifier extends Notifier<List<Topic>> {
  final List<Topic> initialTopics;
  TestTopicListNotifier(this.initialTopics);

  @override
  List<Topic> build() => initialTopics;
}
```

Replace each `topicsProvider.overrideWith((ref) => <Topic>[])` with:
```dart
topicsProvider.overrideWith((ref) => TestTopicListNotifier(<Topic>[])),
```

And replace `topicsProvider.overrideWith((ref) => [Topic(...)])` with:
```dart
topicsProvider.overrideWith((ref) => TestTopicListNotifier([Topic(...)])),
```

There are 3 `topicsProvider` overrides in this file (lines 105, 167, 228).

- [ ] **Step 2: Update app_router_test.dart provider overrides**

In `test/router/app_router_test.dart`, make the same changes. Add the `TestTopicListNotifier` helper class after imports and replace each of the 4 `topicsProvider.overrideWith((ref) => <Topic>[])` with:

```dart
topicsProvider.overrideWith((ref) => TestTopicListNotifier(<Topic>[])),
```

- [ ] **Step 3: Run all tests to verify**

Run: `flutter test`
Expected: ALL PASS

- [ ] **Step 4: Commit**

```bash
git add test/features/discover/presentation/pages/discover_page_test.dart test/router/app_router_test.dart
git commit -m "test: update topic provider overrides to NotifierProvider syntax"
```

---

### Task 6: Run final verification

- [ ] **Step 1: Run flutter analyze**

Run: `flutter analyze`
Expected: No errors or warnings

- [ ] **Step 2: Run all tests**

Run: `flutter test`
Expected: ALL PASS

- [ ] **Step 3: Final commit if needed**

```bash
git add -A
git commit -m "chore: final cleanup after topic SWR implementation"
```
