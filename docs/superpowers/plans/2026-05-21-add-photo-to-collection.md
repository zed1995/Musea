# Add Photo to Collection — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow authenticated users to save photos to Unsplash collections from the Discover photo feed and Photo Detail page.

**Architecture:** Add one API method (`addPhotoToCollection`) to the existing collection data layer, create a new `SaveToCollectionSheet` bottom sheet widget with inline select/create views, and wire the bookmark buttons on both Discover and Photo Detail pages through the auth gate then to this sheet.

**Tech Stack:** Flutter, Riverpod, Dartz (Either), Mocktail (tests)

---

### Task 1: API Layer — Add `addPhotoToCollection`

**Files:**
- Modify: `lib/core/constants/api_constants.dart`
- Modify: `lib/features/collections/data/datasources/collection_remote_datasource.dart`
- Modify: `lib/features/collections/domain/repositories/collection_repository.dart`
- Modify: `lib/features/collections/data/repositories/collection_repository_impl.dart`
- Test: `test/features/collections/data/datasources/collection_remote_datasource_test.dart`
- Test: `test/features/collections/data/repositories/collection_repository_impl_test.dart`

- [ ] **Step 1: Add test for DataSource.addPhotoToCollection**

Add after the `createCollection` group in `collection_remote_datasource_test.dart`:

```dart
group('addPhotoToCollection', () {
  test('sends POST to /collections/{id}/add with photo_id', () async {
    when(
      () => dioClient.post(
        '/collections/col-1/add',
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async => <String, dynamic>{'id': 'col-1'});

    await dataSource.addPhotoToCollection(
      collectionId: 'col-1',
      photoId: 'photo-123',
    );

    verify(
      () => dioClient.post(
        '/collections/col-1/add',
        data: {'photo_id': 'photo-123'},
      ),
    ).called(1);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/collections/data/datasources/collection_remote_datasource_test.dart --name "sends POST to /collections"`
Expected: FAIL — method not found on `CollectionRemoteDataSource`

- [ ] **Step 3: Add `ApiConstants.collectionAdd` helper**

In `lib/core/constants/api_constants.dart`, add after the existing helpers (line ~71):

```dart
static String collectionAdd(String collectionId) =>
    '$collections/$collectionId/add';
```

- [ ] **Step 4: Add abstract method to DataSource + implement**

In `lib/features/collections/data/datasources/collection_remote_datasource.dart`:

Add to abstract class `CollectionRemoteDataSource`:
```dart
Future<void> addPhotoToCollection({
  required String collectionId,
  required String photoId,
});
```

Add to `CollectionRemoteDataSourceImpl`:
```dart
@override
Future<void> addPhotoToCollection({
  required String collectionId,
  required String photoId,
}) async {
  await _dioClient.post(
    ApiConstants.collectionAdd(collectionId),
    data: {'photo_id': photoId},
  );
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/collections/data/datasources/collection_remote_datasource_test.dart --name "sends POST to /collections"`
Expected: PASS

- [ ] **Step 6: Add test for Repository.addPhotoToCollection**

Add after the `createCollection` group in `collection_repository_impl_test.dart`:

```dart
group('addPhotoToCollection', () {
  test('returns Right<void> on success', () async {
    when(
      () => mockDataSource.addPhotoToCollection(
        collectionId: any(named: 'collectionId'),
        photoId: any(named: 'photoId'),
      ),
    ).thenAnswer((_) async {});

    final result = await repository.addPhotoToCollection(
      collectionId: 'col-1',
      photoId: 'photo-123',
    );

    expect(result, isA<Right<Failure, void>>());
  });

  test('returns Left with ServerFailure on ServerException', () async {
    when(
      () => mockDataSource.addPhotoToCollection(
        collectionId: any(named: 'collectionId'),
        photoId: any(named: 'photoId'),
      ),
    ).thenThrow(ServerException(statusCode: 500, message: 'Server error'));

    final result = await repository.addPhotoToCollection(
      collectionId: 'col-1',
      photoId: 'photo-123',
    );

    expect(result, isA<Left<Failure, void>>());
    result.fold(
      (failure) => expect(failure, isA<ServerFailure>()),
      (_) => fail('Expected Left'),
    );
  });

  test('returns Left with NetworkFailure on NetworkException', () async {
    when(
      () => mockDataSource.addPhotoToCollection(
        collectionId: any(named: 'collectionId'),
        photoId: any(named: 'photoId'),
      ),
    ).thenThrow(NetworkException(message: 'No internet'));

    final result = await repository.addPhotoToCollection(
      collectionId: 'col-1',
      photoId: 'photo-123',
    );

    expect(result, isA<Left<Failure, void>>());
    result.fold(
      (failure) => expect(failure, isA<NetworkFailure>()),
      (_) => fail('Expected Left'),
    );
  });
});
```

- [ ] **Step 7: Run tests to verify they fail**

Run: `flutter test test/features/collections/data/repositories/collection_repository_impl_test.dart --name "addPhotoToCollection"`
Expected: FAIL — method not found

- [ ] **Step 8: Add abstract method to Repository + implement**

In `lib/features/collections/domain/repositories/collection_repository.dart`, add:

```dart
Future<Either<Failure, void>> addPhotoToCollection({
  required String collectionId,
  required String photoId,
});
```

In `lib/features/collections/data/repositories/collection_repository_impl.dart`, add:

```dart
@override
Future<Either<Failure, void>> addPhotoToCollection({
  required String collectionId,
  required String photoId,
}) async {
  try {
    await remoteDataSource.addPhotoToCollection(
      collectionId: collectionId,
      photoId: photoId,
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

- [ ] **Step 9: Run tests to verify they pass**

Run: `flutter test test/features/collections/data/repositories/collection_repository_impl_test.dart --name "addPhotoToCollection"`
Expected: PASS

- [ ] **Step 10: Commit**

```bash
git add lib/core/constants/api_constants.dart \
  lib/features/collections/data/datasources/collection_remote_datasource.dart \
  lib/features/collections/domain/repositories/collection_repository.dart \
  lib/features/collections/data/repositories/collection_repository_impl.dart \
  test/features/collections/data/datasources/collection_remote_datasource_test.dart \
  test/features/collections/data/repositories/collection_repository_impl_test.dart
git commit -m "feat: add addPhotoToCollection to collection data layer"
```

---

### Task 2: Create `SaveToCollectionSheet` widget

**Files:**
- Create: `lib/features/collections/presentation/widgets/save_to_collection_sheet.dart`
- Test: `test/features/collections/presentation/widgets/save_to_collection_sheet_test.dart`

- [ ] **Step 1: Write widget test for SaveToCollectionSheet**

Create `test/features/collections/presentation/widgets/save_to_collection_sheet_test.dart`:

```dart
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/collections/domain/repositories/collection_repository.dart';
import 'package:musea/features/collections/presentation/providers/collections_provider.dart';
import 'package:musea/features/collections/presentation/widgets/save_to_collection_sheet.dart';

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
        child: const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('Test host')),
          ),
        ),
      ),
    );

    final context = tester.element(find.text('Test host'));
    showSaveToCollectionSheet(context, photoId: 'photo-123');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('sheet shows select view with collections on load',
      (tester) async {
    when(
      () => mockRepository.getCollections(
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer(
      (_) async => Right([
        Collection(
          id: 'col-1',
          title: 'Test Collection',
          totalPhotos: 5,
          isPrivate: true,
        ),
      ]),
    );

    await showSheet(tester);

    expect(find.text('Select collection'), findsOneWidget);
    expect(find.text('Test Collection'), findsOneWidget);
    expect(find.text('5 photos'), findsOneWidget);
    expect(find.text('Create new collection'), findsOneWidget);
  });

  testWidgets('tapping create new collection switches to create view',
      (tester) async {
    when(
      () => mockRepository.getCollections(
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => Right(<Collection>[]));

    await showSheet(tester);

    await tester.tap(find.text('Create new collection'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('New collection'), findsOneWidget);
    expect(find.text('Back to collections'), findsOneWidget);
  });

  testWidgets('selecting a collection calls addPhotoToCollection',
      (tester) async {
    when(
      () => mockRepository.getCollections(
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer(
      (_) async => Right([
        Collection(
          id: 'col-1',
          title: 'Test Collection',
          totalPhotos: 5,
          isPrivate: true,
        ),
      ]),
    );

    when(
      () => mockRepository.addPhotoToCollection(
        collectionId: any(named: 'collectionId'),
        photoId: any(named: 'photoId'),
      ),
    ).thenAnswer((_) async => const Right(null));

    await showSheet(tester);

    await tester.tap(find.text('Test Collection'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    verify(
      () => mockRepository.addPhotoToCollection(
        collectionId: 'col-1',
        photoId: 'photo-123',
      ),
    ).called(1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/collections/presentation/widgets/save_to_collection_sheet_test.dart`
Expected: FAIL — import error "Target not found"

- [ ] **Step 3: Implement `SaveToCollectionSheet` widget**

Create `lib/features/collections/presentation/widgets/save_to_collection_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/collections/presentation/providers/collections_provider.dart';

Future<void> showSaveToCollectionSheet(
  BuildContext context, {
  required String photoId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _SaveToCollectionSheet(photoId: photoId),
  );
}

class _SaveToCollectionSheet extends ConsumerStatefulWidget {
  const _SaveToCollectionSheet({required this.photoId});

  final String photoId;

  @override
  ConsumerState<_SaveToCollectionSheet> createState() =>
      _SaveToCollectionSheetState();
}

class _SaveToCollectionSheetState
    extends ConsumerState<_SaveToCollectionSheet> {
  bool _isCreateMode = false;
  List<Collection> _collections = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Create form
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isPrivate = true;
  bool _isSubmitting = false;
  String? _createErrorMessage;

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCollections() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(collectionRepositoryProvider);
      final result = await repository.getCollections(page: 1, perPage: 50);
      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _errorMessage = failure.when(
              network: (m) => 'Network error: $m',
              server: (_, m) => 'Server error: $m',
              cache: (m) => 'Error: $m',
              notFound: (m) => 'Error: $m',
              unauthorized: (_) => 'Please sign in again.',
              rateLimit: (_) => 'Too many requests.',
              unknown: (m) => 'Error: $m',
            );
          });
        },
        (collections) {
          setState(() {
            _isLoading = false;
            _collections = collections;
          });
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _addPhotoToCollection(Collection collection) async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(collectionRepositoryProvider);
      final result = await repository.addPhotoToCollection(
        collectionId: collection.id,
        photoId: widget.photoId,
      );

      result.fold(
        (failure) {
          setState(() {
            _isSubmitting = false;
            _errorMessage = failure.when(
              network: (m) => 'Network error: $m',
              server: (code, m) => code == 409
                  ? 'Photo already in this collection.'
                  : 'Server error: $m',
              cache: (m) => 'Error: $m',
              notFound: (m) => 'Error: $m',
              unauthorized: (_) => 'Please sign in again.',
              rateLimit: (_) => 'Too many requests.',
              unknown: (m) => 'Error: $m',
            );
          });
        },
        (_) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved to ${collection.title}'),
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'View',
                onPressed: () =>
                    context.push('/collection/${collection.id}'),
              ),
            ),
          );
        },
      );
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _handleCreateCollection() async {
    setState(() {
      _isSubmitting = true;
      _createErrorMessage = null;
    });

    try {
      final repository = ref.read(collectionRepositoryProvider);
      final result = await repository.createCollection(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        private: _isPrivate,
      );

      result.fold(
        (failure) {
          setState(() {
            _isSubmitting = false;
            _createErrorMessage = failure.when(
              network: (m) => 'Network error: $m',
              server: (_, m) => 'Server error: $m',
              cache: (m) => 'Error: $m',
              notFound: (m) => 'Error: $m',
              unauthorized: (_) => 'Please sign in again.',
              rateLimit: (_) => 'Too many requests.',
              unknown: (m) => 'Error: $m',
            );
          });
        },
        (collection) {
          setState(() {
            _isCreateMode = false;
            _isSubmitting = false;
            _collections.insert(0, collection);
            _titleController.clear();
            _descriptionController.clear();
            _isPrivate = true;
          });
        },
      );
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _createErrorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          16,
          10,
          16,
          MediaQuery.viewPaddingOf(context).bottom + 8,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4D4D8),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isCreateMode) _buildCreateView() else _buildSelectView(),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select collection',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.15,
                      color: Color(0xFF09090B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Save this photo to one of your collections.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    '✕',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF71717A),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => setState(() => _isCreateMode = true),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFECECF0)),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181B),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create new collection',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF18181B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'No perfect fit yet? Make a new one.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'MY COLLECTIONS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
                color: Colors.grey[400],
              ),
            ),
            Text(
              '${_collections.length} collections',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_errorMessage != null)
          _ErrorRetry(message: _errorMessage!, onRetry: _loadCollections)
        else if (_collections.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No collections yet.',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _collections.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final collection = _collections[index];
                return _CollectionItem(
                  collection: collection,
                  onTap: _isSubmitting
                      ? null
                      : () => _addPhotoToCollection(collection),
                );
              },
            ),
          ),
        if (!_isLoading && _errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
          ),
        ],
      ],
    );
  }

  Widget _buildCreateView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _isCreateMode = false),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.arrow_back_ios, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  'Back to collections',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'New collection',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                      color: Color(0xFF18181B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Name it, add an optional note, and choose visibility.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    '✕',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF71717A),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Collection Name',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
            color: Color(0xFFA1A1AA),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _titleController,
          maxLength: 60,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Enter a name',
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE7E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE7E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF18181B)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            counterStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[400],
            ),
          ),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 14),
        const Text(
          'Description Optional',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
            color: Color(0xFFA1A1AA),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Add a description...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE7E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE7E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF18181B)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 14),
        const Text(
          'Visibility',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
            color: Color(0xFFA1A1AA),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _VisibilityOption(
                label: 'Private collection',
                description: 'Only you can see it.',
                isSelected: _isPrivate,
                onTap: () => setState(() => _isPrivate = true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _VisibilityOption(
                label: 'Public collection',
                description: 'Visible on your profile.',
                isSelected: !_isPrivate,
                onTap: () => setState(() => _isPrivate = false),
              ),
            ),
          ],
        ),
        if (_createErrorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _createErrorMessage!,
            style: const TextStyle(fontSize: 13, color: Color(0xFFB91C1C)),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _titleController.text.trim().isEmpty || _isSubmitting
                ? null
                : _handleCreateCollection,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF18181B),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Create collection',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _CollectionItem extends StatelessWidget {
  const _CollectionItem({
    required this.collection,
    this.onTap,
  });

  final Collection collection;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFF0F0F0)),
          color: Colors.white.withValues(alpha: 0.94),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFF4F4F5),
              ),
              child: collection.coverPhoto != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        collection.coverPhoto!.urlSmall,
                        fit: BoxFit.cover,
                        width: 54,
                        height: 54,
                        errorBuilder: (_, __, ___) => const SizedBox(),
                      ),
                    )
                  : const SizedBox(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collection.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF18181B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${collection.totalPhotos} photos',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF71717A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (collection.isPrivate)
              Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Center(
                  child: Text(
                    'Private',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF52525B),
                    ),
                  ),
                ),
              ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }
}

class _VisibilityOption extends StatelessWidget {
  const _VisibilityOption({
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF18181B)
              : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF18181B)
                : const Color(0xFFF1F1F3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.white : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Colors.white : const Color(0xFFA1A1AA),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF18181B),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF18181B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.3,
                      color: isSelected
                          ? Colors.white70
                          : const Color(0xFF71717A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 32, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/collections/presentation/widgets/save_to_collection_sheet_test.dart`
Expected: PASS

If tests fail due to `pumpAndSettle` timing with progress indicators, replace `pumpAndSettle` with `pump()` + `pump(const Duration(milliseconds: 100))`.

- [ ] **Step 5: Commit**

```bash
git add lib/features/collections/presentation/widgets/save_to_collection_sheet.dart \
  test/features/collections/presentation/widgets/save_to_collection_sheet_test.dart
git commit -m "feat: add SaveToCollectionSheet widget with select and create views"
```

---

### Task 3: Connect Discover Page Bookmark

**Files:**
- Modify: `lib/features/discover/presentation/pages/discover_page.dart`

- [ ] **Step 1: Run existing discover page tests to confirm baseline**

Run: `flutter test test/features/discover/presentation/pages/discover_page_test.dart`
Expected: PASS

- [ ] **Step 2: Replace `onBookmarkTap` handler**

In `lib/features/discover/presentation/pages/discover_page.dart`:

1. Add import at top:
```dart
import 'package:musea/features/collections/presentation/widgets/save_to_collection_sheet.dart';
```

2. Replace the `onBookmarkTap` line (currently line 137):
```dart
// Before:
onBookmarkTap: (photo) => _handleDownload(context),
// After:
onBookmarkTap: (photo) => _handleBookmark(photo),
```

3. Replace `_handleDownload` method with `_handleBookmark`:
```dart
Future<void> _handleBookmark(Photo photo) async {
  final authState = ref.read(authControllerProvider);
  if (!authState.isAuthenticated) {
    await showAuthGateSheet(
      context,
      ref,
      title: 'Sign in to save photos',
      body:
          'Build collections of what inspires you and keep them in sync with your Unsplash account.',
    );
  }
  if (!mounted) return;
  showSaveToCollectionSheet(context, photoId: photo.id);
}
```

4. Remove the unused `_handleDownload` method.

- [ ] **Step 3: Run tests to verify discover page still works**

Run: `flutter test test/features/discover/presentation/pages/discover_page_test.dart`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add lib/features/discover/presentation/pages/discover_page.dart
git commit -m "feat: connect discover page bookmark button to save-to-collection sheet"
```

---

### Task 4: Connect Photo Detail Page Bookmark

**Files:**
- Modify: `lib/features/photo_detail/presentation/pages/photo_detail_page.dart`

- [ ] **Step 1: Run existing photo detail page tests**

Run: `flutter test test/features/photo_detail/presentation/pages/photo_detail_page_test.dart`
Expected: PASS

- [ ] **Step 2: Add `onBookmarkTap` to `_PhotoHero` and wire the button**

In `lib/features/photo_detail/presentation/pages/photo_detail_page.dart`:

1. Add import at top with other imports:
```dart
import 'package:musea/features/collections/presentation/widgets/save_to_collection_sheet.dart';
```

2. In the `_PhotoHero` widget class declaration, add `onBookmarkTap` callback:
```dart
class _PhotoHero extends StatefulWidget {
  const _PhotoHero({
    required this.photo,
    this.onTap,
    this.onBookmarkTap,
  });

  final Photo photo;
  final VoidCallback? onTap;
  final VoidCallback? onBookmarkTap;
```

3. In `_PhotoHero.build`, wire the bookmark `_HeroActionButton`:
```dart
// Before (around line 389):
const Row(
  children: [
    _HeroActionButton(icon: Icons.bookmark_border),
    ...
  ],
),

// After:
Row(
  children: [
    _HeroActionButton(
      icon: Icons.bookmark_border,
      onTap: widget.onBookmarkTap,
    ),
    ...
  ],
),
```

Note: Remove the `const` keyword from the `Row` since `onTap` is now dynamic.

4. In `_PhotoDetailContent.build`, pass `onBookmarkTap` to `_PhotoHero`:
```dart
_PhotoHero(
  photo: heroPhoto,
  onTap: onHeroTap,
  onBookmarkTap: () => _handleBookmark(ref, photo),
),
```

5. Add the `_handleBookmark` method to `_PhotoDetailContent`:
```dart
void _handleBookmark(WidgetRef ref, Photo photo) {
  final authState = ref.read(authControllerProvider);
  if (!authState.isAuthenticated) {
    showAuthGateSheet(
      context,
      ref,
      title: 'Sign in to save photos',
      body:
          'Build collections of what inspires you and keep them in sync with your Unsplash account.',
    );
  }
  showSaveToCollectionSheet(context, photoId: photo.id);
}
```

- [ ] **Step 3: Run tests to verify photo detail page still works**

Run: `flutter test test/features/photo_detail/presentation/pages/photo_detail_page_test.dart`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add lib/features/photo_detail/presentation/pages/photo_detail_page.dart
git commit -m "feat: connect photo detail page bookmark button to save-to-collection sheet"
```

---

### Task 5: Final Verification

- [ ] **Step 1: Run all tests**

```bash
flutter test
```

Expected: All tests pass. If any fail, fix and re-run.

- [ ] **Step 2: Run flutter analyze**

```bash
flutter analyze
```

Expected: No issues. Fix any warnings or errors.

---
