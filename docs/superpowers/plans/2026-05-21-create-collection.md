# Create Collection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add "Create Collection" feature — `+` button triggers auth gate or create sheet, submits to Unsplash API, navigates to new collection detail page.

**Architecture:** Clean architecture layer addition: datasource → repository → provider → bottom sheet widget. The sheet manages its own loading/error state locally and calls the repository directly through the existing repository provider.

**Tech Stack:** Flutter, Riverpod, Dart, Dio, Mocktail (tests)

---

### Task 1: Update OAuth Scopes

**Files:**
- Modify: `lib/core/constants/api_constants.dart:19`

- [ ] **Step 1: Add `write_collections` to auth scopes**

```dart
// lib/core/constants/api_constants.dart line 19
static const List<String> authScopes = ['public', 'read_user', 'write_likes', 'write_collections'];
```

- [ ] **Step 2: Run existing auth test to verify scope formatting still works**

Run: `flutter test test/features/auth/data/repositories/auth_repository_impl_test.dart`
Expected: PASS (the test checks that scopes are space-separated)

- [ ] **Step 3: Commit**

```bash
git add lib/core/constants/api_constants.dart
git commit -m "feat: add write_collections OAuth scope for create collection"
```

---

### Task 2: Add createCollection to Data Source

**Files:**
- Modify: `lib/features/collections/data/datasources/collection_remote_datasource.dart`
- Test: `test/features/collections/data/datasources/collection_remote_datasource_test.dart`

- [ ] **Step 1: Write the failing datasource test**

Create `test/features/collections/data/datasources/collection_remote_datasource_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musea/core/network/dio_client.dart';
import 'package:musea/features/collections/data/datasources/collection_remote_datasource.dart';
import 'package:musea/features/collections/data/models/collection_model.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late MockDioClient dioClient;
  late CollectionRemoteDataSourceImpl dataSource;

  setUp(() {
    dioClient = MockDioClient();
    dataSource = CollectionRemoteDataSourceImpl(dioClient);
  });

  group('createCollection', () {
    test('sends POST with title, description, private and returns CollectionModel', () async {
      when(() => dioClient.post(
        '/collections',
        data: any(named: 'data'),
      )).thenAnswer((_) async => <String, dynamic>{
        'id': 'new-collection-1',
        'title': 'Test Collection',
        'description': 'A test description',
        'total_photos': 0,
      });

      final result = await dataSource.createCollection(
        title: 'Test Collection',
        description: 'A test description',
        private: true,
      );

      verify(() => dioClient.post(
        '/collections',
        data: {
          'title': 'Test Collection',
          'description': 'A test description',
          'private': true,
        },
      )).called(1);

      expect(result, isA<CollectionModel>());
      expect(result.title, 'Test Collection');
      expect(result.description, 'A test description');
      expect(result.isPrivate, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/collections/data/datasources/collection_remote_datasource_test.dart`
Expected: FAIL with "Method not found: 'createCollection'"

- [ ] **Step 3: Add `createCollection` to abstract data source**

```dart
// lib/features/collections/data/datasources/collection_remote_datasource.dart
// Add to abstract class:
Future<CollectionModel> createCollection({
  required String title,
  String? description,
  bool? private,
});
```

- [ ] **Step 4: Implement `createCollection` in data source impl**

```dart
// lib/features/collections/data/datasources/collection_remote_datasource.dart
// Add to CollectionRemoteDataSourceImpl:
@override
Future<CollectionModel> createCollection({
  required String title,
  String? description,
  bool? private,
}) async {
  final response = await _dioClient.post(
    ApiConstants.collections,
    data: {
      'title': title,
      if (description != null) 'description': description,
      if (private != null) 'private': private,
    },
  );
  return CollectionModel.fromJson(response);
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/collections/data/datasources/collection_remote_datasource_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/features/collections/data/datasources/collection_remote_datasource.dart test/features/collections/data/datasources/collection_remote_datasource_test.dart
git commit -m "feat: add createCollection to collection remote data source"
```

---

### Task 3: Add createCollection to Repository

**Files:**
- Modify: `lib/features/collections/domain/repositories/collection_repository.dart`
- Modify: `lib/features/collections/data/repositories/collection_repository_impl.dart`
- Test: `test/features/collections/data/repositories/collection_repository_impl_test.dart`

- [ ] **Step 1: Write the failing repository test**

Create `test/features/collections/data/repositories/collection_repository_impl_test.dart`:

```dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musea/core/errors/exceptions.dart';
import 'package:musea/core/errors/failures.dart';
import 'package:musea/features/collections/data/datasources/collection_remote_datasource.dart';
import 'package:musea/features/collections/data/models/collection_model.dart';
import 'package:musea/features/collections/data/repositories/collection_repository_impl.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';

class MockCollectionRemoteDataSource extends Mock
    implements CollectionRemoteDataSource {}

void main() {
  late MockCollectionRemoteDataSource mockDataSource;
  late CollectionRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockCollectionRemoteDataSource();
    repository = CollectionRepositoryImpl(remoteDataSource: mockDataSource);
  });

  group('createCollection', () {
    test('returns Right with Collection on successful creation', () async {
      final model = CollectionModel(
        id: 'new-1',
        title: 'Test',
        totalPhotos: 0,
      );

      when(() => mockDataSource.createCollection(
        title: any(named: 'title'),
        description: any(named: 'description'),
        private: any(named: 'private'),
      )).thenAnswer((_) async => model);

      final result = await repository.createCollection(
        title: 'Test',
        description: 'desc',
        private: true,
      );

      expect(result, isA<Right<Failure, Collection>>());
      expect(result.getOrElse(() => throw 'unexpected').title, 'Test');
    });

    test('returns Left with ServerFailure on ServerException', () async {
      when(() => mockDataSource.createCollection(
        title: any(named: 'title'),
        description: any(named: 'description'),
        private: any(named: 'private'),
      )).thenThrow(const ServerException(statusCode: 500, message: 'Server error'));

      final result = await repository.createCollection(
        title: 'Test',
      );

      expect(result, isA<Left<Failure, Collection>>());
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('returns Left with NetworkFailure on NetworkException', () async {
      when(() => mockDataSource.createCollection(
        title: any(named: 'title'),
        description: any(named: 'description'),
        private: any(named: 'private'),
      )).thenThrow(const NetworkException(message: 'No internet'));

      final result = await repository.createCollection(
        title: 'Test',
      );

      expect(result, isA<Left<Failure, Collection>>());
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/collections/data/repositories/collection_repository_impl_test.dart`
Expected: FAIL — "Method not found: 'createCollection'"

- [ ] **Step 3: Add `createCollection` to abstract repository**

```dart
// lib/features/collections/domain/repositories/collection_repository.dart
// Add to abstract class:
Future<Either<Failure, Collection>> createCollection({
  required String title,
  String? description,
  bool? private,
});
```

- [ ] **Step 4: Implement `createCollection` in repository impl**

```dart
// lib/features/collections/data/repositories/collection_repository_impl.dart
// Add to CollectionRepositoryImpl:
@override
Future<Either<Failure, Collection>> createCollection({
  required String title,
  String? description,
  bool? private,
}) async {
  try {
    final collection = await remoteDataSource.createCollection(
      title: title,
      description: description,
      private: private,
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
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/collections/data/repositories/collection_repository_impl_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/features/collections/domain/repositories/collection_repository.dart lib/features/collections/data/repositories/collection_repository_impl.dart test/features/collections/data/repositories/collection_repository_impl_test.dart
git commit -m "feat: add createCollection to collection repository"
```

---

### Task 4: Create Collection Bottom Sheet Widget

**Files:**
- Create: `lib/features/collections/presentation/widgets/create_collection_sheet.dart`
- Test: `test/features/collections/presentation/widgets/create_collection_sheet_test.dart`

- [ ] **Step 1: Write the failing widget test**

Create `test/features/collections/presentation/widgets/create_collection_sheet_test.dart`:

```dart
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musea/core/errors/failures.dart';
import 'package:musea/features/collections/data/repositories/collection_repository_impl.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/collections/domain/repositories/collection_repository.dart';
import 'package:musea/features/collections/presentation/providers/collections_provider.dart';

class MockCollectionRepository extends Mock implements CollectionRepository {}

void main() {
  late MockCollectionRepository mockRepository;

  setUp(() {
    mockRepository = MockCollectionRepository();
  });

  Widget buildTestApp() {
    return ProviderScope(
      overrides: [
        collectionRepositoryProvider.overrideWithValue(mockRepository),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Test host'),
          ),
        ),
      ),
    );
  }

  Future<void> showSheet(WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp());
    // Find the context to show the bottom sheet
    await tester.tap(find.text('Test host'));
    await tester.pumpAndSettle();
    final context = tester.element(find.text('Test host'));
    await showCreateCollectionSheet(context);
    await tester.pumpAndSettle();
  }

  testWidgets('sheet renders all form fields', (tester) async {
    await tester.pumpWidget(buildTestApp());

    // Stub the repository call (won't actually be called yet)
    when(() => mockRepository.createCollection(
      title: any(named: 'title'),
      description: any(named: 'description'),
      private: any(named: 'private'),
    )).thenAnswer((_) async => Right(
      Collection(id: 'new-1', title: 'Test', totalPhotos: 0),
    ));

    // Show the sheet
    final context = tester.element(find.text('Test host'));
    await showCreateCollectionSheet(context);
    await tester.pumpAndSettle();

    // Verify sheet elements
    expect(find.text('New collection'), findsOneWidget);
    expect(find.text('Collection Name'), findsOneWidget);
    expect(find.text('Description Optional'), findsOneWidget);
    expect(find.text('Visibility'), findsOneWidget);
    expect(find.text('Private collection'), findsOneWidget);
    expect(find.text('Public collection'), findsOneWidget);
    expect(find.text('Create collection'), findsOneWidget);
  });

  testWidgets('create button is disabled when title is empty', (tester) async {
    await tester.pumpWidget(buildTestApp());

    when(() => mockRepository.createCollection(
      title: any(named: 'title'),
      description: any(named: 'description'),
      private: any(named: 'private'),
    )).thenAnswer((_) async => Right(
      Collection(id: 'new-1', title: 'Test', totalPhotos: 0),
    ));

    final context = tester.element(find.text('Test host'));
    await showCreateCollectionSheet(context);
    await tester.pumpAndSettle();

    // Button should be disabled when title is empty
    final createButton = tester.widget<TextButton>(find.text('Create collection'));
    expect(createButton.enabled, isFalse);
  });

  testWidgets('typing title enables create button', (tester) async {
    await tester.pumpWidget(buildTestApp());

    when(() => mockRepository.createCollection(
      title: any(named: 'title'),
      description: any(named: 'description'),
      private: any(named: 'private'),
    )).thenAnswer((_) async => Right(
      Collection(id: 'new-1', title: 'Test', totalPhotos: 0),
    ));

    final context = tester.element(find.text('Test host'));
    await showCreateCollectionSheet(context);
    await tester.pumpAndSettle();

    // Type in the title field
    await tester.enterText(find.byType(TextFormField).first, 'My Collection');
    await tester.pumpAndSettle();

    // Button should now be enabled
    final createButton = tester.widget<TextButton>(find.text('Create collection'));
    expect(createButton.enabled, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/collections/presentation/widgets/create_collection_sheet_test.dart`
Expected: FAIL — "Method not found: 'showCreateCollectionSheet'"

- [ ] **Step 3: Create the create collection sheet widget**

```dart
// lib/features/collections/presentation/widgets/create_collection_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musea/features/collections/presentation/providers/collections_provider.dart';

Future<void> showCreateCollectionSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const _CreateCollectionSheet(),
  );
}

class _CreateCollectionSheet extends ConsumerStatefulWidget {
  const _CreateCollectionSheet();

  @override
  ConsumerState<_CreateCollectionSheet> createState() =>
      _CreateCollectionSheetState();
}

class _CreateCollectionSheetState extends ConsumerState<_CreateCollectionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isPrivate = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(16, 10, 16, bottomInset + 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pill indicator
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

              // Header
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
                        child: Text('✕', style: TextStyle(fontSize: 14, color: Color(0xFF71717A))),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Collection Name
              Text(
                'Collection Name',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                maxLength: 60,
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  counterStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[400]),
                ),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Description
              Text(
                'Description Optional',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                  color: Colors.grey[400],
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 14),

              // Visibility
              Text(
                'Visibility',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                  color: Colors.grey[400],
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

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(fontSize: 13, color: Color(0xFFB91C1C)),
                ),
              ],

              const SizedBox(height: 16),

              // Create button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _titleController.text.trim().isEmpty || _isSubmitting
                      ? null
                      : _handleCreate,
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
          ),
        ),
      ),
    );
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
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
            _errorMessage = failure.when(
              network: (message) => 'Network error: $message',
              server: (_, message) => 'Server error: $message',
              cache: (message) => 'Error: $message',
              notFound: (message) => 'Error: $message',
              unauthorized: (message) => 'Please sign in again to create collections.',
              rateLimit: (message) => 'Too many requests. Please try again later.',
              unknown: (message) => 'Error: $message',
            );
          });
        },
        (collection) {
          Navigator.of(context).pop();
          context.push('/collection/${collection.id}');
        },
      );
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString();
      });
    }
  }
}

class _VisibilityOption extends StatelessWidget {
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _VisibilityOption({
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF18181B) : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF18181B) : const Color(0xFFF1F1F3),
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
                      color: isSelected ? Colors.white : const Color(0xFF18181B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.3,
                      color: isSelected ? Colors.white70 : const Color(0xFF71717A),
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/collections/presentation/widgets/create_collection_sheet_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/collections/presentation/widgets/create_collection_sheet.dart test/features/collections/presentation/widgets/create_collection_sheet_test.dart
git commit -m "feat: add create collection bottom sheet widget"
```

---

### Task 5: Wire + Button in Collections Page

**Files:**
- Modify: `lib/features/collections/presentation/pages/collections_page.dart`
- Test: `test/features/collections/presentation/pages/collections_page_test.dart`

- [ ] **Step 1: Write failing test for + button behavior**

Update `test/features/collections/presentation/pages/collections_page_test.dart`:

```dart
// Replace the existing collection page test file entirely:
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:musea/features/auth/presentation/providers/auth_provider.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/collections/presentation/pages/collections_page.dart';
import 'package:musea/features/collections/presentation/providers/collections_provider.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';

/// A simple smoke test to verify the CollectionsPage renders without crashing.
void main() {
  testWidgets('CollectionsPage shows empty state when no collections',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          collectionsProvider(1).overrideWith(
            (ref) => <Collection>[],
          ),
        ],
        child: const MaterialApp(
          home: CollectionsPage(),
        ),
      ),
    );

    // Verify the empty state message renders
    expect(find.text('No collections'), findsOneWidget);
  });

  testWidgets('CollectionsPage uses the simplified prototype header',
      (tester) async {
    const user = User(
      id: 'user-1',
      username: 'curator',
      name: 'Curator',
      profileImageSmall: '',
      profileImageMedium: '',
      profileImageLarge: '',
      totalPhotos: 0,
      totalLikes: 0,
      totalCollections: 0,
    );

    final photo = Photo(
      id: 'photo-1',
      createdAt: DateTime(2024, 1, 1),
      width: 1200,
      height: 800,
      color: '#ABCDEF',
      urlRaw: '',
      urlFull: '',
      urlRegular: '',
      urlSmall: '',
      urlThumb: '',
      likes: 10,
      downloads: 5,
      user: user,
    );

    final collections = [
      Collection(
        id: 'collection-1',
        title: 'Travel Inspiration',
        totalPhotos: 24,
        coverPhoto: photo,
        previewPhotos: const [],
        user: user,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          collectionsProvider(1).overrideWith((ref) => collections),
        ],
        child: const MaterialApp(
          home: CollectionsPage(),
        ),
      ),
    );

    expect(find.text('Collections'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('+ button shows auth sheet when unauthenticated',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          collectionsProvider(1).overrideWith((ref) => <Collection>[]),
          authBootstrapSessionProvider.overrideWithValue(null),
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
        ],
        child: const MaterialApp(
          home: CollectionsPage(),
        ),
      ),
    );

    // Tap the + button
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Auth gate sheet should appear
    expect(find.text('Sign in to'), findsWidgets);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/collections/presentation/pages/collections_page_test.dart`
Expected: FAIL — tapping + button does nothing (no onPressed), so auth sheet doesn't appear

- [ ] **Step 3: Wire + button in collections page**

Modify `lib/features/collections/presentation/pages/collections_page.dart`:

```dart
// Replace the import section:
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/features/auth/presentation/providers/auth_provider.dart';
import 'package:musea/features/auth/presentation/widgets/auth_gate_sheet.dart';
import 'package:musea/features/collections/presentation/providers/collections_provider.dart';
import 'package:musea/features/collections/presentation/widgets/create_collection_sheet.dart';
import 'package:musea/shared/widgets/collection_card.dart';
import 'package:musea/shared/widgets/empty_state.dart';
import 'package:musea/shared/widgets/error_state.dart';
import 'package:musea/shared/widgets/loading_indicator.dart';
```

Make `CollectionsPage` a `ConsumerWidget` that watches auth state and wire the + button:

```dart
class CollectionsPage extends ConsumerWidget {
  const CollectionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionsAsync = ref.watch(collectionsProvider(1));
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      body: collectionsAsync.when(
        data: (collections) {
          if (collections.isEmpty) {
            return SafeArea(
              child: Column(
                children: [
                  _CollectionsHeader(
                    onAddPressed: () => _handleAddPressed(context, ref, authState),
                  ),
                  const Expanded(
                    child: EmptyState(
                      icon: Icons.collections_bookmark_outlined,
                      title: 'No collections',
                      subtitle: 'Check back later for curated collections',
                    ),
                  ),
                ],
              ),
            );
          }

          return SafeArea(
            child: Column(
              children: [
                _CollectionsHeader(
                  onAddPressed: () => _handleAddPressed(context, ref, authState),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => ref.invalidate(collectionsProvider),
                    child: CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: CollectionCard(collection: collections[index]),
                              ),
                              childCount: collections.length,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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

  void _handleAddPressed(
    BuildContext context,
    WidgetRef ref,
    AuthState authState,
  ) {
    if (authState.isAuthenticated) {
      showCreateCollectionSheet(context);
    } else {
      showAuthGateSheet(
        context,
        ref,
        title: 'Sign in to create collections',
        body: 'Save your favorite photos into custom collections and organize them your way.',
      );
    }
  }
}
```

Update `_CollectionsHeader` to accept and use the callback:

```dart
class _CollectionsHeader extends StatelessWidget {
  const _CollectionsHeader({required this.onAddPressed});

  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Collections',
              style: TextStyle(
                fontSize: 30,
                height: 1.1,
                fontWeight: FontWeight.w700,
                color: Color(0xFF18181B),
              ),
            ),
          ),
          GestureDetector(
            onTap: onAddPressed,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE5E5E5)),
              ),
              child: const Icon(Icons.add, size: 18, color: Color(0xFF18181B)),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/collections/presentation/pages/collections_page_test.dart`
Expected: PASS — + button now opens auth sheet when unauthenticated

- [ ] **Step 5: Run all tests to verify nothing broken**

Run: `flutter test`
Expected: All tests PASS

- [ ] **Step 6: Run flutter analyze**

Run: `flutter analyze`
Expected: No errors

- [ ] **Step 7: Commit**

```bash
git add lib/features/collections/presentation/pages/collections_page.dart test/features/collections/presentation/pages/collections_page_test.dart
git commit -m "feat: wire + button on collections page with auth gate and create sheet"
```

---

### Spec Coverage Check

| Spec Requirement | Task |
|---|---|
| Add `write_collections` OAuth scope | Task 1 |
| `createCollection` in remote datasource | Task 2 |
| `createCollection` in repository | Task 3 |
| Create collection bottom sheet UI | Task 4 |
| + button shows auth sheet when unauthenticated | Task 5 |
| + button shows create sheet when authenticated | Task 5 (create sheet), Task 4 (sheet widget) |
| Navigate to `/collection/{id}` on success | Task 4 |

No gaps — all spec requirements covered.
