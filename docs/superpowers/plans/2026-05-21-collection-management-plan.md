# Collection Management Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement edit, remove photos, and delete collection management features with bottom sheets.

**Architecture:** Following existing feature-first clean architecture pattern. Three new API methods added to the datasource/repository layer. Four new UI widgets (Manage sheet, Edit sheet, Delete sheet, Remove Photos page). Owner check via `authControllerProvider`. Operation success triggers `ref.invalidate` on detail/photos providers to auto-refresh.

**Tech Stack:** Flutter, Riverpod, Dartz, Mocktail

---

### Task 1: API Constant + Datasource Layer

**Files:**
- Modify: `lib/core/constants/api_constants.dart`
- Modify: `lib/features/collections/data/datasources/collection_remote_datasource.dart`
- Test: `test/features/collections/data/datasources/collection_remote_datasource_test.dart`

- [ ] **Step 1: Add API constant for remove photo path**

In `lib/core/constants/api_constants.dart`, add after the `collectionAdd` helper:

```dart
static String collectionRemove(String collectionId) =>
    '$collections/$collectionId/remove';
```

- [ ] **Step 2: Write failing datasource tests**

Append to `test/features/collections/data/datasources/collection_remote_datasource_test.dart`:

```dart
group('updateCollection', () {
  test('sends PUT with title, description, private and returns CollectionModel', () async {
    when(
      () => dioClient.put(
        '/collections/col-1',
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async => <String, dynamic>{
      'id': 'col-1',
      'title': 'Updated Title',
      'description': 'Updated desc',
      'private': false,
      'total_photos': 5,
    });

    final result = await dataSource.updateCollection(
      'col-1',
      title: 'Updated Title',
      description: 'Updated desc',
      private: false,
    );

    verify(
      () => dioClient.put(
        '/collections/col-1',
        data: {
          'title': 'Updated Title',
          'description': 'Updated desc',
          'private': false,
        },
      ),
    ).called(1);

    expect(result, isA<CollectionModel>());
    expect(result.title, 'Updated Title');
  });

  test('sends PUT with partial fields when optional params omitted', () async {
    when(
      () => dioClient.put(
        '/collections/col-1',
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async => <String, dynamic>{
      'id': 'col-1',
      'title': 'Just Title',
      'total_photos': 3,
    });

    final result = await dataSource.updateCollection('col-1', title: 'Just Title');

    verify(
      () => dioClient.put(
        '/collections/col-1',
        data: {'title': 'Just Title'},
      ),
    ).called(1);

    expect(result.title, 'Just Title');
  });
});

group('deleteCollection', () {
  test('sends DELETE and succeeds', () async {
    when(
      () => dioClient.delete('/collections/col-1'),
    ).thenAnswer((_) async => null);

    await dataSource.deleteCollection('col-1');

    verify(() => dioClient.delete('/collections/col-1')).called(1);
  });
});

group('removePhotoFromCollection', () {
  test('sends DELETE to /collections/{id}/remove with photo_id', () async {
    when(
      () => dioClient.delete(
        '/collections/col-1/remove',
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async => null);

    await dataSource.removePhotoFromCollection(
      collectionId: 'col-1',
      photoId: 'photo-123',
    );

    verify(
      () => dioClient.delete(
        '/collections/col-1/remove',
        data: {'photo_id': 'photo-123'},
      ),
    ).called(1);
  });
});
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/features/collections/data/datasources/collection_remote_datasource_test.dart`
Expected: Fails with "method not found" errors

- [ ] **Step 4: Implement 3 new datasource methods**

In `lib/features/collections/data/datasources/collection_remote_datasource.dart`, add to abstract class:

```dart
Future<CollectionModel> updateCollection(
  String id, {
  String? title,
  String? description,
  bool? private,
});

Future<void> deleteCollection(String id);

Future<void> removePhotoFromCollection({
  required String collectionId,
  required String photoId,
});
```

Add implementations in `CollectionRemoteDataSourceImpl`:

```dart
@override
Future<CollectionModel> updateCollection(
  String id, {String? title, String? description, bool? private,
}) async {
  final response = await _dioClient.put(
    '${ApiConstants.collections}/$id',
    data: {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (private != null) 'private': private,
    },
  );
  return CollectionModel.fromJson(response);
}

@override
Future<void> deleteCollection(String id) async {
  await _dioClient.delete('${ApiConstants.collections}/$id');
}

@override
Future<void> removePhotoFromCollection({
  required String collectionId, required String photoId,
}) async {
  await _dioClient.delete(
    ApiConstants.collectionRemove(collectionId),
    data: {'photo_id': photoId},
  );
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/features/collections/data/datasources/collection_remote_datasource_test.dart`
Expected: All tests pass

---

### Task 2: Repository Layer

**Files:**
- Modify: `lib/features/collections/domain/repositories/collection_repository.dart`
- Modify: `lib/features/collections/data/repositories/collection_repository_impl.dart`
- Test: `test/features/collections/data/repositories/collection_repository_impl_test.dart`

- [ ] **Step 1: Write failing repository tests**

Append to `test/features/collections/data/repositories/collection_repository_impl_test.dart`:

```dart
group('updateCollection', () {
  test('returns Right with Collection on success', () async {
    final model = CollectionModel(
      id: 'col-1', title: 'Updated', description: 'New desc',
      isPrivate: false, totalPhotos: 5,
    );
    when(() => mockDataSource.updateCollection(
      any(), title: any(named: 'title'),
      description: any(named: 'description'), private: any(named: 'private'),
    )).thenAnswer((_) async => model);

    final result = await repository.updateCollection(
      'col-1', title: 'Updated', description: 'New desc', private: false,
    );
    expect(result, isA<Right<Failure, Collection>>());
    expect(result.getOrElse(() => throw 'unexpected').title, 'Updated');
  });

  test('returns Left with ServerFailure on exception', () async {
    when(() => mockDataSource.updateCollection(
      any(), title: any(named: 'title'),
      description: any(named: 'description'), private: any(named: 'private'),
    )).thenThrow(ServerException(statusCode: 500, message: 'Server error'));

    final result = await repository.updateCollection('col-1', title: 'Test');
    expect(result, isA<Left<Failure, Collection>>());
  });
});

group('deleteCollection', () {
  test('returns Right on success', () async {
    when(() => mockDataSource.deleteCollection(any()))
        .thenAnswer((_) async => null);
    final result = await repository.deleteCollection('col-1');
    expect(result, isA<Right<Failure, void>>());
  });

  test('returns Left on exception', () async {
    when(() => mockDataSource.deleteCollection(any()))
        .thenThrow(ServerException(statusCode: 500, message: 'Error'));
    final result = await repository.deleteCollection('col-1');
    expect(result, isA<Left<Failure, void>>());
  });
});

group('removePhotoFromCollection', () {
  test('returns Right on success', () async {
    when(() => mockDataSource.removePhotoFromCollection(
      collectionId: any(named: 'collectionId'),
      photoId: any(named: 'photoId'),
    )).thenAnswer((_) async => null);
    final result = await repository.removePhotoFromCollection(
      collectionId: 'col-1', photoId: 'photo-123',
    );
    expect(result, isA<Right<Failure, void>>());
  });

  test('returns Left on exception', () async {
    when(() => mockDataSource.removePhotoFromCollection(
      collectionId: any(named: 'collectionId'),
      photoId: any(named: 'photoId'),
    )).thenThrow(ServerException(statusCode: 500, message: 'Error'));
    final result = await repository.removePhotoFromCollection(
      collectionId: 'col-1', photoId: 'photo-123',
    );
    expect(result, isA<Left<Failure, void>>());
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/collections/data/repositories/collection_repository_impl_test.dart`
Expected: Fails with "method not found"

- [ ] **Step 3: Add 3 methods to abstract repository**

In `lib/features/collections/domain/repositories/collection_repository.dart`:

```dart
Future<Either<Failure, Collection>> updateCollection(
  String id, {
  String? title,
  String? description,
  bool? private,
});

Future<Either<Failure, void>> deleteCollection(String id);

Future<Either<Failure, void>> removePhotoFromCollection({
  required String collectionId,
  required String photoId,
});
```

- [ ] **Step 4: Implement in repository impl**

In `lib/features/collections/data/repositories/collection_repository_impl.dart`, add after `addPhotoToCollection`:

```dart
@override
Future<Either<Failure, Collection>> updateCollection(
  String id, {String? title, String? description, bool? private,
}) async {
  try {
    final collection = await remoteDataSource.updateCollection(
      id, title: title, description: description, private: private,
    );
    return Right(collection.toEntity());
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
Future<Either<Failure, void>> deleteCollection(String id) async {
  try {
    await remoteDataSource.deleteCollection(id);
    return const Right(null);
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
Future<Either<Failure, void>> removePhotoFromCollection({
  required String collectionId, required String photoId,
}) async {
  try {
    await remoteDataSource.removePhotoFromCollection(
      collectionId: collectionId, photoId: photoId,
    );
    return const Right(null);
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

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/features/collections/data/repositories/collection_repository_impl_test.dart`
Expected: All tests pass

---

### Task 3: Provider Mutations

**Files:**
- Modify: `lib/features/collections/presentation/providers/collections_provider.dart`
- Test: `test/features/collections/presentation/providers/collections_provider_test.dart`

- [ ] **Step 1: Write failing provider tests**

In `test/features/collections/presentation/providers/collections_provider_test.dart`, add the three new methods to `_FakeCollectionRepository`:

```dart
@override
Future<Either<Failure, Collection>> updateCollection(
  String id, {String? title, String? description, bool? private,
}) async {
  return Right(Collection(id: id, title: title ?? 'Updated', totalPhotos: 0));
}

@override
Future<Either<Failure, void>> deleteCollection(String id) async {
  return const Right(null);
}

@override
Future<Either<Failure, void>> removePhotoFromCollection({
  required String collectionId, required String photoId,
}) async {
  return const Right(null);
}
```

Then append these tests:

```dart
test('updateCollectionProvider returns updated collection', () async {
  final repository = _FakeCollectionRepository();
  final container = ProviderContainer(overrides: [
    collectionRepositoryProvider.overrideWithValue(repository),
  ]);
  addTearDown(container.dispose);

  final result = await container.read(
    updateCollectionProvider((
      id: 'col-1', title: 'New Title', description: 'Desc', private: false,
    )).future,
  );
  expect(result.title, 'New Title');
});

test('deleteCollectionProvider completes successfully', () async {
  final repository = _FakeCollectionRepository();
  final container = ProviderContainer(overrides: [
    collectionRepositoryProvider.overrideWithValue(repository),
  ]);
  addTearDown(container.dispose);

  await expectLater(
    container.read(deleteCollectionProvider('col-1').future), completes,
  );
});

test('removePhotoFromCollectionProvider completes successfully', () async {
  final repository = _FakeCollectionRepository();
  final container = ProviderContainer(overrides: [
    collectionRepositoryProvider.overrideWithValue(repository),
  ]);
  addTearDown(container.dispose);

  await expectLater(
    container.read(removePhotoFromCollectionProvider((
      collectionId: 'col-1', photoId: 'photo-123',
    )).future), completes,
  );
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/collections/presentation/providers/collections_provider_test.dart`
Expected: Fails with providers not found

- [ ] **Step 3: Add 3 mutation providers**

Append to `lib/features/collections/presentation/providers/collections_provider.dart`:

```dart
final updateCollectionProvider = FutureProvider.family<Collection, ({
  String id,
  String? title,
  String? description,
  bool? private,
})>((ref, params) async {
  final repository = ref.watch(collectionRepositoryProvider);
  final result = await repository.updateCollection(
    params.id,
    title: params.title,
    description: params.description,
    private: params.private,
  );
  return result.fold(
    (failure) => throw _mapFailureToException(failure),
    (collection) {
      ref.invalidate(collectionDetailProvider(params.id));
      return collection;
    },
  );
});

final deleteCollectionProvider = FutureProvider.family<void, String>((ref, id) async {
  final repository = ref.watch(collectionRepositoryProvider);
  final result = await repository.deleteCollection(id);
  return result.fold(
    (failure) => throw _mapFailureToException(failure),
    (_) {
      ref.invalidate(collectionsProvider(1));
      return;
    },
  );
});

final removePhotoFromCollectionProvider = FutureProvider.family<void, ({
  String collectionId,
  String photoId,
})>((ref, params) async {
  final repository = ref.watch(collectionRepositoryProvider);
  final result = await repository.removePhotoFromCollection(
    collectionId: params.collectionId,
    photoId: params.photoId,
  );
  return result.fold(
    (failure) => throw _mapFailureToException(failure),
    (_) {
      ref.invalidate(collectionDetailProvider(params.collectionId));
      ref.invalidate(collectionPhotosProvider(params.collectionId));
      return;
    },
  );
});
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/collections/presentation/providers/collections_provider_test.dart`
Expected: All tests pass

---

### Task 4: CollectionManageSheet Widget

**Files:**
- Create: `lib/features/collections/presentation/widgets/collection_manage_sheet.dart`
- Test: `test/features/collections/presentation/widgets/collection_manage_sheet_test.dart`

- [ ] **Step 1: Write failing widget test**

Create `test/features/collections/presentation/widgets/collection_manage_sheet_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/collections/presentation/widgets/collection_manage_sheet.dart';

void main() {
  Widget buildTestApp({VoidCallback? onEdit, VoidCallback? onRemovePhotos, VoidCallback? onDelete}) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showCollectionManageSheet(
              context,
              collection: Collection(id: 'col-1', title: 'Test', totalPhotos: 5),
              onEdit: onEdit ?? () {},
              onRemovePhotos: onRemovePhotos ?? () {},
              onDelete: onDelete ?? () {},
            ),
            child: const Text('Open Manage Sheet'),
          ),
        ),
      ),
    );
  }

  testWidgets('renders title, subtitle, and 3 menu items', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.tap(find.text('Open Manage Sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Manage collection'), findsOneWidget);
    expect(find.text('Edit details'), findsOneWidget);
    expect(find.text('Remove photos'), findsOneWidget);
    expect(find.text('Delete collection'), findsOneWidget);
  });

  testWidgets('tapping Edit details calls onEdit', (tester) async {
    var edited = false;
    await tester.pumpWidget(buildTestApp(onEdit: () => edited = true));
    await tester.tap(find.text('Open Manage Sheet'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit details'));
    await tester.pumpAndSettle();
    expect(edited, isTrue);
  });

  testWidgets('tapping Remove photos calls onRemovePhotos', (tester) async {
    var removed = false;
    await tester.pumpWidget(buildTestApp(onRemovePhotos: () => removed = true));
    await tester.tap(find.text('Open Manage Sheet'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Remove photos'));
    await tester.pumpAndSettle();
    expect(removed, isTrue);
  });

  testWidgets('tapping Delete collection calls onDelete', (tester) async {
    var deleted = false;
    await tester.pumpWidget(buildTestApp(onDelete: () => deleted = true));
    await tester.tap(find.text('Open Manage Sheet'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete collection'));
    await tester.pumpAndSettle();
    expect(deleted, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/collections/presentation/widgets/collection_manage_sheet_test.dart`
Expected: Import error

- [ ] **Step 3: Create the Manage sheet widget**

Create `lib/features/collections/presentation/widgets/collection_manage_sheet.dart` with:
- `showCollectionManageSheet()` function — calls `showModalBottomSheet` with 28px top radius
- `CollectionManageSheet` StatelessWidget — drag handle pill, title "Manage collection", subtitle, close (x) button, 3 menu rows (Edit details / Remove photos / Delete collection), each with icon in colored circle, title, subtitle, chevron-right
- Delete row uses red colors, others use dark/olive backgrounds
- Each menu row dismisses the sheet then calls its callback

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/collections/presentation/widgets/collection_manage_sheet_test.dart`
Expected: All tests pass

---

### Task 5: CollectionEditSheet Widget

**Files:**
- Create: `lib/features/collections/presentation/widgets/collection_edit_sheet.dart`
- Test: `test/features/collections/presentation/widgets/collection_edit_sheet_test.dart`

- [ ] **Step 1: Write failing widget test**

Create `test/features/collections/presentation/widgets/collection_edit_sheet_test.dart`:

```dart
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/collections/domain/repositories/collection_repository.dart';
import 'package:musea/features/collections/presentation/providers/collections_provider.dart';
import 'package:musea/features/collections/presentation/widgets/collection_edit_sheet.dart';

class MockCollectionRepository extends Mock implements CollectionRepository {}

void main() {
  late MockCollectionRepository mockRepository;

  setUp(() {
    mockRepository = MockCollectionRepository();
  });

  Future<void> showSheet(WidgetTester tester, {Collection? collection}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          collectionRepositoryProvider.overrideWithValue(mockRepository),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showCollectionEditSheet(context,
                  collection: collection ?? Collection(id: 'col-1', title: 'Test', totalPhotos: 5),
                ),
                child: const Text('Open Edit Sheet'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open Edit Sheet'));
    await tester.pumpAndSettle();
  }

  testWidgets('renders title and pre-populated fields', (tester) async {
    await showSheet(tester, collection: Collection(
      id: 'col-1', title: 'Kyoto Research',
      description: 'Street glow', totalPhotos: 5,
    ));
    expect(find.text('Edit collection'), findsOneWidget);
    expect(find.text('Kyoto Research'), findsOneWidget);
    expect(find.text('Street glow'), findsOneWidget);
    expect(find.text('Public'), findsOneWidget);
    expect(find.text('Private'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);
  });

  testWidgets('save calls repository with current values', (tester) async {
    when(() => mockRepository.updateCollection(
      any(), title: any(named: 'title'),
      description: any(named: 'description'), private: any(named: 'private'),
    )).thenAnswer((_) async => Right(Collection(id: 'col-1', title: 'Updated', totalPhotos: 5)));

    await showSheet(tester, collection: Collection(
      id: 'col-1', title: 'Old Title', totalPhotos: 5,
    ));
    await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
    await tester.pumpAndSettle();

    verify(() => mockRepository.updateCollection('col-1', title: 'Old Title', description: null, private: null)).called(1);
  });

  testWidgets('making changes and saving passes new values', (tester) async {
    when(() => mockRepository.updateCollection(
      any(), title: any(named: 'title'),
      description: any(named: 'description'), private: any(named: 'private'),
    )).thenAnswer((_) async => Right(Collection(id: 'col-1', title: 'New Name', totalPhotos: 5)));

    await showSheet(tester, collection: Collection(
      id: 'col-1', title: 'Old Title', totalPhotos: 5,
    ));

    await tester.enterText(find.byType(TextFormField).first, 'New Name');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Private'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
    await tester.pumpAndSettle();

    verify(() => mockRepository.updateCollection('col-1', title: 'New Name', description: null, private: true)).called(1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/collections/presentation/widgets/collection_edit_sheet_test.dart`
Expected: Import error

- [ ] **Step 3: Create the Edit sheet widget**

Create `lib/features/collections/presentation/widgets/collection_edit_sheet.dart` with:
- `showCollectionEditSheet()` — `isScrollControlled: true` modal bottom sheet
- `CollectionEditSheet` ConsumerStatefulWidget — name text field (60 char limit), description text field (multiline), visibility toggle (Public/Private), Save button
- On save: reads `updateCollectionProvider`, shows loading state, dismisses on success, snackbar on error
- Pre-populated from collection parameter

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/collections/presentation/widgets/collection_edit_sheet_test.dart`
Expected: All tests pass

---

### Task 6: CollectionDeleteSheet Widget

**Files:**
- Create: `lib/features/collections/presentation/widgets/collection_delete_sheet.dart`
- Test: `test/features/collections/presentation/widgets/collection_delete_sheet_test.dart`

- [ ] **Step 1: Write failing widget test**

Create `test/features/collections/presentation/widgets/collection_delete_sheet_test.dart`:

```dart
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/collections/domain/repositories/collection_repository.dart';
import 'package:musea/features/collections/presentation/providers/collections_provider.dart';
import 'package:musea/features/collections/presentation/widgets/collection_delete_sheet.dart';

class MockCollectionRepository extends Mock implements CollectionRepository {}

void main() {
  late MockCollectionRepository mockRepository;

  setUp(() {
    mockRepository = MockCollectionRepository();
  });

  Future<void> showSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          collectionRepositoryProvider.overrideWithValue(mockRepository),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showCollectionDeleteSheet(context,
                  collection: Collection(id: 'col-1', title: 'Kyoto Research', totalPhotos: 5),
                ),
                child: const Text('Open Delete Sheet'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open Delete Sheet'));
    await tester.pumpAndSettle();
  }

  testWidgets('renders title and warning', (tester) async {
    await showSheet(tester);
    expect(find.text('Delete collection?'), findsOneWidget);
  });

  testWidgets('delete button disabled until correct name typed', (tester) async {
    when(() => mockRepository.deleteCollection(any())).thenAnswer((_) async => const Right(null));
    await showSheet(tester);

    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Delete collection')).enabled, isFalse);

    await tester.enterText(find.byType(TextFormField), 'Kyoto Research');
    await tester.pumpAndSettle();

    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Delete collection')).enabled, isTrue);
  });

  testWidgets('wrong name keeps button disabled', (tester) async {
    await showSheet(tester);
    await tester.enterText(find.byType(TextFormField), 'Wrong Name');
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Delete collection')).enabled, isFalse);
  });

  testWidgets('tapping delete calls repository', (tester) async {
    when(() => mockRepository.deleteCollection(any())).thenAnswer((_) async => const Right(null));
    await showSheet(tester);
    await tester.enterText(find.byType(TextFormField), 'Kyoto Research');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete collection'));
    await tester.pumpAndSettle();
    verify(() => mockRepository.deleteCollection('col-1')).called(1);
  });

  testWidgets('tapping cancel dismisses sheet', (tester) async {
    await showSheet(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Delete collection?'), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/collections/presentation/widgets/collection_delete_sheet_test.dart`
Expected: Import error

- [ ] **Step 3: Create the Delete sheet widget**

Create `lib/features/collections/presentation/widgets/collection_delete_sheet.dart` with:
- `showCollectionDeleteSheet()` — `isScrollControlled: true` modal bottom sheet
- `CollectionDeleteSheet` ConsumerStatefulWidget — red title, danger note box, confirmation text field (must match collection title), red delete button (disabled until match), cancel button
- On delete: calls `deleteCollectionProvider`, pops sheet then detail page, snackbar on error

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/collections/presentation/widgets/collection_delete_sheet_test.dart`
Expected: All tests pass

---

### Task 7: CollectionRemovePhotosPage

**Files:**
- Create: `lib/features/collections/presentation/pages/collection_remove_photos_page.dart`
- Modify: `lib/router/app_router.dart` — add route
- Test: `test/features/collections/presentation/pages/collection_remove_photos_page_test.dart`

- [ ] **Step 1: Write failing widget test**

Create `test/features/collections/presentation/pages/collection_remove_photos_page_test.dart`:

```dart
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musea/features/collections/domain/repositories/collection_repository.dart';
import 'package:musea/features/collections/presentation/providers/collections_provider.dart';
import 'package:musea/features/collections/presentation/pages/collection_remove_photos_page.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';

class MockCollectionRepository extends Mock implements CollectionRepository {}

Photo _photo(String id) => Photo(
  id: id, createdAt: DateTime(2024), width: 800, height: 800,
  color: '#fff',
  urlRaw: 'https://ex.com/$id.jpg', urlFull: 'https://ex.com/$id.jpg',
  urlRegular: 'https://ex.com/$id.jpg', urlSmall: 'https://ex.com/$id.jpg',
  urlThumb: 'https://ex.com/$id.jpg', likes: 0, altDescription: id,
  user: const User(id: 'u1', username: 'u', name: 'U',
    profileImageSmall: '', profileImageMedium: '', profileImageLarge: '',
    totalPhotos: 0, totalLikes: 0, totalCollections: 0,
  ),
);

void main() {
  late MockCollectionRepository mockRepository;

  setUp(() { mockRepository = MockCollectionRepository(); });

  Widget buildApp(List<Photo> photos) => ProviderScope(
    overrides: [collectionRepositoryProvider.overrideWithValue(mockRepository)],
    child: MaterialApp(
      home: CollectionRemovePhotosPage(
        collectionId: 'col-1', collectionTitle: 'Test', photos: photos,
      ),
    ),
  );

  testWidgets('renders batch mode header', (tester) async {
    await tester.pumpWidget(buildApp([_photo('p1')]));
    expect(find.text('Batch Mode'), findsOneWidget);
    expect(find.text('Remove photos'), findsOneWidget);
  });

  testWidgets('selecting photos updates count', (tester) async {
    await tester.pumpWidget(buildApp([_photo('p1'), _photo('p2'), _photo('p3')]));
    expect(find.text('0 selected'), findsOneWidget);

    await tester.tap(find.byType(GridTile).first);
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);
  });

  testWidgets('done button resets selection', (tester) async {
    await tester.pumpWidget(buildApp([_photo('p1'), _photo('p2')]));
    await tester.tap(find.byType(GridTile).first);
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('0 selected'), findsOneWidget);
  });

  testWidgets('remove button calls repository for each selected photo', (tester) async {
    when(() => mockRepository.removePhotoFromCollection(
      collectionId: any(named: 'collectionId'), photoId: any(named: 'photoId'),
    )).thenAnswer((_) async => const Right(null));

    final photos = [_photo('p1'), _photo('p2'), _photo('p3')];
    await tester.pumpWidget(buildApp(photos));

    // Select all 3
    for (int i = 0; i < 3; i++) {
      await tester.tap(find.byType(GridTile).at(i));
      await tester.pumpAndSettle();
    }
    expect(find.text('3 selected'), findsOneWidget);
    expect(find.text('Remove 3 photos'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Remove 3 photos'));
    await tester.pumpAndSettle();

    verify(() => mockRepository.removePhotoFromCollection(collectionId: 'col-1', photoId: 'p1')).called(1);
    verify(() => mockRepository.removePhotoFromCollection(collectionId: 'col-1', photoId: 'p2')).called(1);
    verify(() => mockRepository.removePhotoFromCollection(collectionId: 'col-1', photoId: 'p3')).called(1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/collections/presentation/pages/collection_remove_photos_page_test.dart`
Expected: Import error

- [ ] **Step 3: Create the Remove Photos page**

Create `lib/features/collections/presentation/pages/collection_remove_photos_page.dart` with:
- `CollectionRemovePhotosPage` ConsumerStatefulWidget — takes `collectionId`, `collectionTitle`, `photos` List
- AppBar with "REMOVE PHOTOS" eyebrow + Done button (clears selection)
- Info card: "Batch Mode" / "Remove photos" title / description text
- Selection count row
- 2-column photo grid with select chips (circle→checkmark on tap)
- Selected state: 22% black overlay + white inset shadow
- Bottom bar (shown only when selection > 0): summary text + Remove N photos button
- Remove loop: calls `removePhotoFromCollectionProvider` for each, pops on success, snackbar on error
- Loading state: CircularProgressIndicator in button while removing

- [ ] **Step 4: Add route in app_router.dart**

In `lib/router/app_router.dart`:
- Import: `import 'package:musea/features/collections/presentation/pages/collection_remove_photos_page.dart';`
- Import: `import 'package:musea/features/discover/domain/entities/photo.dart';`
- Add route after `/collection/:id`:

```dart
GoRoute(
  path: '/collection/:id/remove',
  parentNavigatorKey: _rootNavigatorKey,
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    final extra = state.extra as Map<String, dynamic>? ?? {};
    return CollectionRemovePhotosPage(
      collectionId: id,
      collectionTitle: extra['title'] as String? ?? '',
      photos: (extra['photos'] as List<Photo>?) ?? [],
    );
  },
),
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/features/collections/presentation/pages/collection_remove_photos_page_test.dart`
Expected: All tests pass

---

### Task 8: Update CollectionDetailPage

**Files:**
- Modify: `lib/features/collections/presentation/pages/collection_detail_page.dart`
- Test: `test/features/collections/presentation/pages/collection_detail_page_test.dart`

- [ ] **Step 1: Write failing widget test updates**

Append these tests to `test/features/collections/presentation/pages/collection_detail_page_test.dart`:

```dart
import 'package:musea/features/auth/presentation/providers/auth_provider.dart';
import 'package:musea/features/auth/domain/entities/auth_session.dart';
import 'package:musea/features/auth/domain/entities/auth_user.dart';

// Collection builder that includes user
Collection _buildOwnedCollection({required String userId}) => Collection(
  id: 'col-1', title: 'Test', totalPhotos: 10,
  user: User(id: userId, username: 'u', name: 'U',
    profileImageSmall: '', profileImageMedium: '', profileImageLarge: '',
    totalPhotos: 0, totalLikes: 0, totalCollections: 0,
  ),
);

testWidgets('owner sees manage button in topbar', (tester) async {
  final session = AuthSession(
    accessToken: 't', tokenType: 'bearer', scope: 'public', createdAt: 0,
    lastProfileRefreshAt: DateTime(2024),
    user: AuthUser(id: 'owner-1', username: 'u', displayName: 'U',
      profileImageMedium: '', totalPhotos: 0, totalLikes: 0, totalCollections: 0,
    ),
  );

  when(() => mockRepository.getCollection(any())).thenAnswer(
    (_) async => Right(_buildOwnedCollection(userId: 'owner-1')),
  );

  await tester.pumpWidget(
    ProviderScope(overrides: [
      collectionRepositoryProvider.overrideWithValue(mockRepository),
      authControllerProvider.overrideWithValue(AuthState(session: session)),
    ], child: const MaterialApp(home: CollectionDetailPage(collectionId: 'col-1'))),
  );
  await tester.pumpAndSettle();

  expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
});

testWidgets('non-owner does not see manage button', (tester) async {
  final session = AuthSession(
    accessToken: 't', tokenType: 'bearer', scope: 'public', createdAt: 0,
    lastProfileRefreshAt: DateTime(2024),
    user: AuthUser(id: 'other', username: 'o', displayName: 'O',
      profileImageMedium: '', totalPhotos: 0, totalLikes: 0, totalCollections: 0,
    ),
  );

  when(() => mockRepository.getCollection(any())).thenAnswer(
    (_) async => Right(_buildOwnedCollection(userId: 'owner-1')),
  );

  await tester.pumpWidget(
    ProviderScope(overrides: [
      collectionRepositoryProvider.overrideWithValue(mockRepository),
      authControllerProvider.overrideWithValue(AuthState(session: session)),
    ], child: const MaterialApp(home: CollectionDetailPage(collectionId: 'col-1'))),
  );
  await tester.pumpAndSettle();

  expect(find.byIcon(Icons.grid_view_rounded), findsNothing);
});

testWidgets('unauthenticated user does not see manage button', (tester) async {
  when(() => mockRepository.getCollection(any())).thenAnswer(
    (_) async => Right(_buildOwnedCollection(userId: 'owner-1')),
  );

  await tester.pumpWidget(
    ProviderScope(overrides: [
      collectionRepositoryProvider.overrideWithValue(mockRepository),
      authControllerProvider.overrideWithValue(const AuthState()),
    ], child: const MaterialApp(home: CollectionDetailPage(collectionId: 'col-1'))),
  );
  await tester.pumpAndSettle();

  expect(find.byIcon(Icons.grid_view_rounded), findsNothing);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/collections/presentation/pages/collection_detail_page_test.dart`
Expected: The current test file may compile or fail based on existing test structure. New test methods will fail because `grid_view_rounded` icon doesn't exist as manage button yet and bookmark button still exists.

- [ ] **Step 3: Update collection detail page**

In `lib/features/collections/presentation/pages/collection_detail_page.dart`:

**Imports to add (top of file):**
```dart
import 'package:musea/features/auth/presentation/providers/auth_provider.dart';
import 'package:musea/features/collections/presentation/widgets/collection_manage_sheet.dart';
import 'package:musea/features/collections/presentation/pages/collection_remove_photos_page.dart';
import 'package:musea/features/collections/presentation/widgets/collection_edit_sheet.dart';
import 'package:musea/features/collections/presentation/widgets/collection_delete_sheet.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
```

**Add `isOwner` parameter to `_CollectionDetailContent`**:
```dart
this.isOwner = false,
```

**In `CollectionDetailPage.build()`** — get auth state and pass `isOwner`:
```dart
final authState = ref.watch(authControllerProvider);
final isOwner = authState.isAuthenticated &&
    authState.session?.user.id == resolvedCollection?.user?.id;
```

Pass `isOwner` to `_CollectionDetailContent`.

**In the topbar** — replace the bookmark button (`Icons.bookmark_border_rounded`) with:
```dart
if (isOwner) ...[
  _GlassActionButton(
    icon: Icons.grid_view_rounded,
    onPressed: () => _showManageSheet(context),
  ),
  const SizedBox(width: 8),
],
```

**Add manage sheet handler to `_CollectionDetailContent`:**
```dart
void _showManageSheet(BuildContext context) {
  final photosList = photosAsync.valueOrNull ?? [];
  showCollectionManageSheet(
    context,
    collection: collection,
    onEdit: () => showCollectionEditSheet(context, collection: collection),
    onRemovePhotos: () => context.push(
      '/collection/${collection.id}/remove',
      extra: {'title': collection.title, 'photos': photosList},
    ),
    onDelete: () => showCollectionDeleteSheet(context, collection: collection),
  );
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/collections/presentation/pages/collection_detail_page_test.dart`
Expected: All tests pass

---

### Task 9: Final Verification

- [ ] **Step 1: Run all tests**

Run: `flutter test`
Expected: All tests pass

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze`
Expected: No errors
