# Follow Feature Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire the existing static "Follow" pill in Photo Detail and add a new one to Profile Page to live follow / unfollow via the Unsplash API, with optimistic UI and an auth-gate for unauthenticated taps.

**Architecture:** New `lib/features/follow/` module owns an RPC data source, a repository that returns `Either<Failure, User>`, and a Riverpod family `AsyncNotifier` controller with a sealed `FollowState` machine. A reusable `FollowButton` widget reads the controller state, drives the UI (pill / spinner / checked), and dispatches the auth gate for unauthenticated taps. No new entities — the follow status already lives on the existing `User.followedByUser` field.

**Tech Stack:** Flutter, Riverpod (`AsyncNotifier.family`), DioClient, dartz `Either`, freezed-free sealed classes, mocktail, `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-06-20-follow-feature-design.md`

---

## File Structure

Files to create:

- `lib/features/follow/data/datasources/follow_remote_datasource.dart` — RPC data source (POST/DELETE `/users/:username/follow`)
- `lib/features/follow/data/repositories/follow_repository_impl.dart` — wraps data source in `Either<Failure, User>`
- `lib/features/follow/domain/repositories/follow_repository.dart` — interface
- `lib/features/follow/presentation/controllers/follow_controller.dart` — `FamilyAsyncNotifier<FollowState, String>` state machine
- `lib/features/follow/presentation/providers/follow_providers.dart` — Riverpod providers wiring data source → repository → controller
- `lib/features/follow/presentation/widgets/follow_button.dart` — `ConsumerWidget` consumed by Photo Detail and Profile Page
- `test/features/follow/data/datasources/follow_remote_datasource_test.dart`
- `test/features/follow/data/repositories/follow_repository_impl_test.dart`
- `test/features/follow/presentation/controllers/follow_controller_test.dart`
- `test/features/follow/presentation/widgets/follow_button_test.dart`

Files to modify:

- `lib/core/constants/api_constants.dart` — add `userFollow(String username)` helper
- `lib/features/discover/domain/entities/user.dart` — add `copyWith`
- `lib/features/photo_detail/presentation/pages/photo_detail_page.dart` — replace static `Container` Follow pill with `FollowButton`
- `lib/features/profile/presentation/pages/profile_page.dart` — add `FollowButton` to the hero region
- `lib/l10n/app_en.arb` and `lib/l10n/app_zh.arb` — add `follow`, `following`, `followUpdateFailed`, `followSignInTitle`, `followSignInBody`
- `test/features/discover/data/models/photo_model_test.dart` (if present) and any other test that constructs `User` literally and depends on the field order — likely no changes
- `test/features/photo_detail/presentation/pages/photo_detail_page_test.dart` — assert the button is present
- `test/features/profile/presentation/pages/profile_page_test.dart` — assert the button renders / hides based on the viewed user

---

## Task 1: Add `userFollow(String)` API helper

**Files:**
- Modify: `lib/core/constants/api_constants.dart:1-76`
- Test: extend `test/core/network/api_constants_test.dart` (if missing, create it)

- [ ] **Step 1: Write the failing test**

Append to `test/core/network/api_constants_test.dart` (create the file if absent, with `import 'package:flutter_test/flutter_test.dart';` and `import 'package:musea/core/constants/api_constants.dart';`):

```dart
void main() {
  test('userFollow returns /users/:username/follow', () {
    expect(ApiConstants.userFollow('spaciba'), '/users/spaciba/follow');
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/core/network/api_constants_test.dart`
Expected: FAIL — `'userFollow' isn't a method of 'ApiConstants'`.

- [ ] **Step 3: Add the helper to `api_constants.dart`**

Add this method to the `ApiConstants` class (next to `userLikes` / `userCollections`):

```dart
static String userFollow(String username) => '$users/$username/follow';
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/core/network/api_constants_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/constants/api_constants.dart test/core/network/api_constants_test.dart
git commit -m "feat(follow): add userFollow API helper"
```

---

## Task 2: Add `copyWith` to the `User` entity

**Files:**
- Modify: `lib/features/discover/domain/entities/user.dart:1-160`

`User` is a plain immutable class. We need a `copyWith` so the follow controller can flip `followedByUser` without rewriting all 30+ fields.

- [ ] **Step 1: Verify there is no existing test to update**

Run: `grep -r "User(" test/features/discover/` (use Grep tool)

If no test currently constructs a `User` literally with positional/named args that we'd break, skip to step 2. If something constructs `User` and relies on positional ordering of `fromJson`, no change is needed since we're only adding a method.

- [ ] **Step 2: Add the `copyWith` method**

Append to the `User` class (right after `toJson`, before `fromJson`):

```dart
User copyWith({
  String? id,
  DateTime? updatedAt,
  String? username,
  String? name,
  String? firstName,
  String? lastName,
  String? bio,
  String? location,
  String? portfolioUrl,
  String? instagramUsername,
  String? twitterUsername,
  String? profileImageSmall,
  String? profileImageMedium,
  String? profileImageLarge,
  int? totalPhotos,
  int? totalLikes,
  int? totalCollections,
  int? totalFreePhotos,
  int? totalPromotedPhotos,
  int? totalIllustrations,
  int? totalFreeIllustrations,
  int? totalPromotedIllustrations,
  bool? acceptedTos,
  bool? forHire,
  UserLinks? links,
  UserSocial? social,
  List<UserPhotoPreview>? photosPreview,
  UserTags? tags,
  bool? allowMessages,
  bool? followedByUser,
  int? numericId,
  int? downloads,
  UserMeta? meta,
}) {
  return User(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    username: username ?? this.username,
    name: name ?? this.name,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    bio: bio ?? this.bio,
    location: location ?? this.location,
    portfolioUrl: portfolioUrl ?? this.portfolioUrl,
    instagramUsername: instagramUsername ?? this.instagramUsername,
    twitterUsername: twitterUsername ?? this.twitterUsername,
    profileImageSmall: profileImageSmall ?? this.profileImageSmall,
    profileImageMedium: profileImageMedium ?? this.profileImageMedium,
    profileImageLarge: profileImageLarge ?? this.profileImageLarge,
    totalPhotos: totalPhotos ?? this.totalPhotos,
    totalLikes: totalLikes ?? this.totalLikes,
    totalCollections: totalCollections ?? this.totalCollections,
    totalFreePhotos: totalFreePhotos ?? this.totalFreePhotos,
    totalPromotedPhotos: totalPromotedPhotos ?? this.totalPromotedPhotos,
    totalIllustrations: totalIllustrations ?? this.totalIllustrations,
    totalFreeIllustrations: totalFreeIllustrations ?? this.totalFreeIllustrations,
    totalPromotedIllustrations:
        totalPromotedIllustrations ?? this.totalPromotedIllustrations,
    acceptedTos: acceptedTos ?? this.acceptedTos,
    forHire: forHire ?? this.forHire,
    links: links ?? this.links,
    social: social ?? this.social,
    photosPreview: photosPreview ?? this.photosPreview,
    tags: tags ?? this.tags,
    allowMessages: allowMessages ?? this.allowMessages,
    followedByUser: followedByUser ?? this.followedByUser,
    numericId: numericId ?? this.numericId,
    downloads: downloads ?? this.downloads,
    meta: meta ?? this.meta,
  );
}
```

- [ ] **Step 3: Verify the file still compiles**

Run: `flutter analyze lib/features/discover/domain/entities/user.dart`
Expected: no errors.

- [ ] **Step 4: Add a unit test for `copyWith`**

Create `test/features/discover/domain/entities/user_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/features/discover/domain/entities/user.dart';

void main() {
  User sampleUser() => const User(
        id: '1',
        username: 'spaciba',
        name: 'Paula Poeira',
        profileImageSmall: 'small',
        profileImageMedium: 'medium',
        profileImageLarge: 'large',
        totalPhotos: 10,
        totalLikes: 20,
        totalCollections: 3,
        followedByUser: false,
      );

  test('copyWith flips followedByUser without touching other fields', () {
    final original = sampleUser();
    final updated = original.copyWith(followedByUser: true);

    expect(updated.followedByUser, isTrue);
    expect(updated.id, original.id);
    expect(updated.username, original.username);
    expect(updated.name, original.name);
    expect(updated.totalPhotos, original.totalPhotos);
    expect(updated.profileImageMedium, original.profileImageMedium);
  });

  test('copyWith with no args returns a value-equal copy', () {
    final original = sampleUser();
    final copy = original.copyWith();

    expect(copy.followedByUser, original.followedByUser);
    expect(copy.username, original.username);
    expect(copy.totalLikes, original.totalLikes);
  });
}
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `flutter test test/features/discover/domain/entities/user_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/features/discover/domain/entities/user.dart test/features/discover/domain/entities/user_test.dart
git commit -m "feat(user): add copyWith to User entity"
```

---

## Task 3: Create `FollowRemoteDataSource` and its test

**Files:**
- Create: `lib/features/follow/data/datasources/follow_remote_datasource.dart`
- Create: `test/features/follow/data/datasources/follow_remote_datasource_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/follow/data/datasources/follow_remote_datasource_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musea/core/network/dio_client.dart';
import 'package:musea/features/follow/data/datasources/follow_remote_datasource.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late MockDioClient dioClient;
  late FollowRemoteDataSourceImpl dataSource;

  setUp(() {
    dioClient = MockDioClient();
    dataSource = FollowRemoteDataSourceImpl(dioClient);
  });

  group('follow', () {
    test('POSTs to /users/:username/follow and returns the parsed User',
        () async {
      when(() => dioClient.post('/users/spaciba/follow'))
          .thenAnswer((_) async => <String, dynamic>{
                'id': 'u1',
                'username': 'spaciba',
                'name': 'Paula Poeira',
                'profile_image': {
                  'small': 'https://example.com/s.jpg',
                  'medium': 'https://example.com/m.jpg',
                  'large': 'https://example.com/l.jpg',
                },
                'total_photos': 12,
                'total_likes': 30,
                'total_collections': 4,
                'followed_by_user': true,
                'followers_count': 42,
              });

      final user = await dataSource.follow('spaciba');

      verify(() => dioClient.post('/users/spaciba/follow')).called(1);
      expect(user.username, 'spaciba');
      expect(user.followedByUser, isTrue);
    });
  });

  group('unfollow', () {
    test('DELETEs /users/:username/follow and returns the parsed User',
        () async {
      when(() => dioClient.delete('/users/spaciba/follow'))
          .thenAnswer((_) async => <String, dynamic>{
                'id': 'u1',
                'username': 'spaciba',
                'name': 'Paula Poeira',
                'profile_image': {
                  'small': 'https://example.com/s.jpg',
                  'medium': 'https://example.com/m.jpg',
                  'large': 'https://example.com/l.jpg',
                },
                'total_photos': 12,
                'total_likes': 30,
                'total_collections': 4,
                'followed_by_user': false,
                'followers_count': 41,
              });

      final user = await dataSource.unfollow('spaciba');

      verify(() => dioClient.delete('/users/spaciba/follow')).called(1);
      expect(user.followedByUser, isFalse);
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/follow/data/datasources/follow_remote_datasource_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:musea/features/follow/data/datasources/follow_remote_datasource.dart'`.

- [ ] **Step 3: Implement the data source**

Create `lib/features/follow/data/datasources/follow_remote_datasource.dart`:

```dart
import 'package:musea/core/constants/api_constants.dart';
import 'package:musea/core/network/dio_client.dart';
import 'package:musea/features/discover/data/models/user_model.dart';
import 'package:musea/features/discover/domain/entities/user.dart';

abstract class FollowRemoteDataSource {
  Future<User> follow(String username);
  Future<User> unfollow(String username);
}

class FollowRemoteDataSourceImpl implements FollowRemoteDataSource {
  FollowRemoteDataSourceImpl(this._dioClient);

  final DioClient _dioClient;

  @override
  Future<User> follow(String username) async {
    final response = await _dioClient.post(ApiConstants.userFollow(username));
    return UserModel.fromJson(response as Map).toEntity();
  }

  @override
  Future<User> unfollow(String username) async {
    final response = await _dioClient.delete(ApiConstants.userFollow(username));
    return UserModel.fromJson(response as Map).toEntity();
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/features/follow/data/datasources/follow_remote_datasource_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/follow/data/datasources/follow_remote_datasource.dart test/features/follow/data/datasources/follow_remote_datasource_test.dart
git commit -m "feat(follow): add follow remote data source"
```

---

## Task 4: Create `FollowRepository` interface, implementation, and test

**Files:**
- Create: `lib/features/follow/domain/repositories/follow_repository.dart`
- Create: `lib/features/follow/data/repositories/follow_repository_impl.dart`
- Create: `test/features/follow/data/repositories/follow_repository_impl_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/follow/data/repositories/follow_repository_impl_test.dart`:

```dart
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musea/core/errors/exceptions.dart';
import 'package:musea/core/errors/failures.dart';
import 'package:musea/features/follow/data/datasources/follow_remote_datasource.dart';
import 'package:musea/features/follow/data/repositories/follow_repository_impl.dart';
import 'package:musea/features/discover/domain/entities/user.dart';

class MockFollowRemoteDataSource extends Mock
    implements FollowRemoteDataSource {}

void main() {
  late MockFollowRemoteDataSource dataSource;
  late FollowRepositoryImpl repository;

  setUp(() {
    dataSource = MockFollowRemoteDataSource();
    repository = FollowRepositoryImpl(dataSource);
  });

  const username = 'spaciba';

  final sampleUser = User(
    id: 'u1',
    username: username,
    name: 'Paula Poeira',
    profileImageSmall: 's',
    profileImageMedium: 'm',
    profileImageLarge: 'l',
    totalPhotos: 12,
    totalLikes: 30,
    totalCollections: 4,
    followedByUser: true,
  );

  test('follow returns Right(User) on success', () async {
    when(() => dataSource.follow(username))
        .thenAnswer((_) async => sampleUser);

    final result = await repository.follow(username);

    expect(result, Right<Failure, User>(sampleUser));
  });

  test('unfollow returns Right(User) on success', () async {
    when(() => dataSource.unfollow(username))
        .thenAnswer((_) async => sampleUser);

    final result = await repository.unfollow(username);

    expect(result, Right<Failure, User>(sampleUser));
  });

  test('follow converts ServerException to Failure.server', () async {
    when(() => dataSource.follow(username)).thenThrow(
      ServerException(statusCode: 500, message: 'boom'),
    );

    final result = await repository.follow(username);

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure, isA<ServerFailure>()),
      (_) => fail('expected Left'),
    );
  });

  test('follow converts NetworkException to Failure.network', () async {
    when(() => dataSource.follow(username))
        .thenThrow(NetworkException(message: 'offline'));

    final result = await repository.follow(username);

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure, isA<NetworkFailure>()),
      (_) => fail('expected Left'),
    );
  });

  test('follow converts UnauthorizedException to Failure.unauthorized',
      () async {
    when(() => dataSource.follow(username))
        .thenThrow(UnauthorizedException(message: 'nope'));

    final result = await repository.follow(username);

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure, isA<UnauthorizedFailure>()),
      (_) => fail('expected Left'),
    );
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/follow/data/repositories/follow_repository_impl_test.dart`
Expected: FAIL — `Target of URI doesn't exist`.

- [ ] **Step 3: Inspect existing repository pattern to mirror it**

Run: `cat lib/features/auth/data/repositories/auth_repository_impl.dart` (use Read tool) to see the exact pattern for mapping exceptions to `Failure` and the import path. **Copy that file's `try/catch` structure verbatim** into the new repository.

- [ ] **Step 4: Create the repository interface**

Create `lib/features/follow/domain/repositories/follow_repository.dart`:

```dart
import 'package:dartz/dartz.dart';
import 'package:musea/core/errors/failures.dart';
import 'package:musea/features/discover/domain/entities/user.dart';

abstract class FollowRepository {
  Future<Either<Failure, User>> follow(String username);
  Future<Either<Failure, User>> unfollow(String username);
}
```

- [ ] **Step 5: Create the implementation**

Create `lib/features/follow/data/repositories/follow_repository_impl.dart` — mirror the `try/catch` shape of `auth_repository_impl.dart`, mapping each `XxxException` to its corresponding `Failure`:

```dart
import 'package:dartz/dartz.dart';
import 'package:musea/core/errors/exceptions.dart';
import 'package:musea/core/errors/failures.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/features/follow/data/datasources/follow_remote_datasource.dart';
import 'package:musea/features/follow/domain/repositories/follow_repository.dart';

class FollowRepositoryImpl implements FollowRepository {
  FollowRepositoryImpl(this._dataSource);

  final FollowRemoteDataSource _dataSource;

  @override
  Future<Either<Failure, User>> follow(String username) async {
    try {
      final user = await _dataSource.follow(username);
      return Right(user);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(message: e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> unfollow(String username) async {
    try {
      final user = await _dataSource.unfollow(username);
      return Right(user);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(message: e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
```

- [ ] **Step 6: Run the test to verify it passes**

Run: `flutter test test/features/follow/data/repositories/follow_repository_impl_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 7: Commit**

```bash
git add lib/features/follow/domain/repositories/follow_repository.dart lib/features/follow/data/repositories/follow_repository_impl.dart test/features/follow/data/repositories/follow_repository_impl_test.dart
git commit -m "feat(follow): add follow repository"
```

---

## Task 5: Create the `FollowState` machine and the controller

**Files:**
- Create: `lib/features/follow/presentation/controllers/follow_controller.dart`
- Create: `test/features/follow/presentation/controllers/follow_controller_test.dart`

The controller is a Riverpod `FamilyAsyncNotifier<FollowState, String>` keyed by username. The state carries the `User` so the widget can rebuild on success / failure. The controller never shows a SnackBar — that's the widget's job.

- [ ] **Step 1: Write the failing test**

Create `test/features/follow/presentation/controllers/follow_controller_test.dart`:

```dart
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/core/errors/failures.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/features/follow/domain/repositories/follow_repository.dart';
import 'package:musea/features/follow/presentation/controllers/follow_controller.dart';
import 'package:musea/features/follow/presentation/providers/follow_providers.dart';

class _FakeFollowRepository implements FollowRepository {
  _FakeFollowRepository(this._followResult, this._unfollowResult);

  Either<Failure, User> Function() _followResult;
  Either<Failure, User> Function() _unfollowResult;
  int followCalls = 0;
  int unfollowCalls = 0;

  @override
  Future<Either<Failure, User>> follow(String username) async {
    followCalls += 1;
    return _followResult();
  }

  @override
  Future<Either<Failure, User>> unfollow(String username) async {
    unfollowCalls += 1;
    return _unfollowResult();
  }
}

User makeUser({required bool followedByUser}) => User(
      id: 'u1',
      username: 'spaciba',
      name: 'Paula',
      profileImageSmall: 's',
      profileImageMedium: 'm',
      profileImageLarge: 'l',
      totalPhotos: 0,
      totalLikes: 0,
      totalCollections: 0,
      followedByUser: followedByUser,
    );

void main() {
  group('FollowController', () {
    test('initial state is FollowIdle', () {
      final container = ProviderContainer(
        overrides: [
          followRepositoryProvider.overrideWithValue(
            _FakeFollowRepository(
              () => Right(makeUser(followedByUser: true)),
              () => Right(makeUser(followedByUser: false)),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(followControllerProvider('spaciba'));
      expect(state, isA<FollowIdle>());
    });

    test('toggle on unfollowed user calls follow() and emits FollowInFlight then FollowIdle',
        () async {
      final user = makeUser(followedByUser: false);
      final updated = user.copyWith(followedByUser: true);
      final repo = _FakeFollowRepository(
        () => Right(updated),
        () => Right(user),
      );
      final container = ProviderContainer(
        overrides: [followRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final future = container
          .read(followControllerProvider('spaciba').notifier)
          .toggle(user);

      // Drain microtasks to observe the in-flight state.
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(followControllerProvider('spaciba')),
        isA<FollowInFlight>(),
      );

      await future;
      expect(container.read(followControllerProvider('spaciba')),
          isA<FollowIdle>());
      expect(repo.followCalls, 1);
    });

    test('toggle on followed user calls unfollow()', () async {
      final user = makeUser(followedByUser: true);
      final updated = user.copyWith(followedByUser: false);
      final repo = _FakeFollowRepository(
        () => Right(user),
        () => Right(updated),
      );
      final container = ProviderContainer(
        overrides: [followRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container
          .read(followControllerProvider('spaciba').notifier)
          .toggle(user);

      expect(repo.unfollowCalls, 1);
      expect(container.read(followControllerProvider('spaciba')),
          isA<FollowIdle>());
    });

    test('failure emits FollowFailed with the Failure', () async {
      final user = makeUser(followedByUser: false);
      final repo = _FakeFollowRepository(
        () => Left(NetworkFailure(message: 'offline')),
        () => Right(user),
      );
      final container = ProviderContainer(
        overrides: [followRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container
          .read(followControllerProvider('spaciba').notifier)
          .toggle(user);

      final state = container.read(followControllerProvider('spaciba'));
      expect(state, isA<FollowFailed>());
      expect((state as FollowFailed).failure, isA<NetworkFailure>());
    });

    test('second tap while in-flight is a no-op', () async {
      final user = makeUser(followedByUser: false);
      final updated = user.copyWith(followedByUser: true);
      final repo = _FakeFollowRepository(
        () => Right(updated),
        () => Right(user),
      );
      final container = ProviderContainer(
        overrides: [followRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final first = container
          .read(followControllerProvider('spaciba').notifier)
          .toggle(user);
      final second = container
          .read(followControllerProvider('spaciba').notifier)
          .toggle(user);
      await Future.wait([first, second]);

      expect(repo.followCalls, 1);
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/follow/presentation/controllers/follow_controller_test.dart`
Expected: FAIL — `Target of URI doesn't exist`.

- [ ] **Step 3: Create the controller**

Create `lib/features/follow/presentation/controllers/follow_controller.dart`:

```dart
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/core/errors/failures.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/features/follow/domain/repositories/follow_repository.dart';
import 'package:musea/features/follow/presentation/providers/follow_providers.dart';

sealed class FollowState {
  const FollowState();
}

class FollowIdle extends FollowState {
  const FollowIdle();
}

class FollowInFlight extends FollowState {
  const FollowInFlight();
}

class FollowFailed extends FollowState {
  const FollowFailed(this.failure);
  final Failure failure;
}

class FollowController
    extends FamilyAsyncNotifier<FollowState, String> {
  late FollowRepository _repository;

  @override
  Future<FollowState> build(String username) async {
    _repository = ref.read(followRepositoryProvider);
    return const FollowIdle();
  }

  /// Toggles the follow status for [user]. The caller is responsible for
  /// providing the current `User`; this controller does not hold a copy of
  /// it. The widget re-reads `widget.user` on every rebuild, so the latest
  /// server state is always reflected.
  Future<void> toggle(User user) async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (current is FollowInFlight) return;

    final desiredFollowed = !(user.followedByUser ?? false);
    state = const AsyncData(FollowInFlight());

    final Either<Failure, User> result = desiredFollowed
        ? await _repository.follow(user.username)
        : await _repository.unfollow(user.username);

    result.fold(
      (failure) => state = AsyncData(FollowFailed(failure)),
      (_) => state = const AsyncData(FollowIdle()),
    );
  }
}

final followControllerProvider =
    AsyncNotifierProvider.family<FollowController, FollowState, String>(
  FollowController.new,
);
```

- [ ] **Step 4: Create the providers file referenced above**

The codebase already exposes `dioClientProvider` in `lib/core/network/providers.dart`. Reuse it so the follow data source shares the same Dio instance (and therefore the same auth interceptor) as every other feature.

Create `lib/features/follow/presentation/providers/follow_providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/core/network/dio_client.dart';
import 'package:musea/core/network/providers.dart';
import 'package:musea/features/follow/data/datasources/follow_remote_datasource.dart';
import 'package:musea/features/follow/data/repositories/follow_repository_impl.dart';
import 'package:musea/features/follow/domain/repositories/follow_repository.dart';

final followRemoteDataSourceProvider =
    Provider<FollowRemoteDataSource>((ref) {
  return FollowRemoteDataSourceImpl(ref.watch(dioClientProvider));
});

final followRepositoryProvider = Provider<FollowRepository>((ref) {
  return FollowRepositoryImpl(ref.watch(followRemoteDataSourceProvider));
});
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `flutter test test/features/follow/presentation/controllers/follow_controller_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/features/follow/presentation/controllers/follow_controller.dart lib/features/follow/presentation/providers/follow_providers.dart test/features/follow/presentation/controllers/follow_controller_test.dart
git commit -m "feat(follow): add follow controller state machine"
```

---

## Task 6: Create the `FollowButton` widget and its test

**Files:**
- Create: `lib/features/follow/presentation/widgets/follow_button.dart`
- Create: `test/features/follow/presentation/widgets/follow_button_test.dart`

The widget reads `authControllerProvider`; on tap, if unauthenticated, it shows the auth gate sheet. Otherwise it seeds the follow controller with the current user and dispatches `toggle()`.

- [ ] **Step 1: Add the i18n keys (placeholder keys) so the test can compile**

Edit `lib/l10n/app_en.arb`. Find the `@@_PAGE_NAV` block (or the closest appropriate section) and add the new keys just before it:

```json
"@@_FOLLOW": "Follow action",
"follow": "Follow",
"following": "Following",
"followUpdateFailed": "Could not update follow status right now",
"followSignInTitle": "Sign in to follow photographers",
"followSignInBody": "Follow Unsplash creators to keep up with their latest photos.",
```

Mirror them in `lib/l10n/app_zh.arb`:

```json
"@@_FOLLOW": "Follow action",
"follow": "关注",
"following": "已关注",
"followUpdateFailed": "关注状态更新失败，请稍后再试",
"followSignInTitle": "登录后关注摄影师",
"followSignInBody": "关注 Unsplash 创作者，及时看到他们的最新作品。",
```

Regenerate the l10n delegates:

```bash
flutter gen-l10n
```

- [ ] **Step 2: Write the failing widget test**

Create `test/features/follow/presentation/widgets/follow_button_test.dart`:

```dart
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/core/errors/failures.dart';
import 'package:musea/features/auth/domain/entities/auth_session.dart';
import 'package:musea/features/auth/domain/entities/auth_user.dart';
import 'package:musea/features/auth/domain/repositories/auth_repository.dart';
import 'package:musea/features/auth/presentation/providers/auth_provider.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/features/follow/domain/repositories/follow_repository.dart';
import 'package:musea/features/follow/presentation/providers/follow_providers.dart';
import 'package:musea/features/follow/presentation/widgets/follow_button.dart';
import 'package:musea/l10n/generated/app_localizations.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this._session);
  final AuthSession? _session;
  @override
  Future<AuthSession?> getStoredSession() async => _session;
  @override
  Future<void> saveSession(AuthSession session) async {}
  @override
  Future<void> clearSession() async {}
  @override
  Future<String?> getPendingOAuthState() async => null;
  @override
  Future<void> savePendingOAuthState(String? state) async {}
  @override
  Uri buildAuthorizationUri({required String state}) =>
      Uri.parse('https://example.com');
  @override
  Future<OAuthToken> exchangeCodeForToken(String code) async =>
      const OAuthToken(accessToken: '', tokenType: '', scope: '', createdAt: 0);
  @override
  Future<AuthUser> fetchCurrentUser() async => const AuthUser(
        id: '',
        username: '',
        displayName: '',
        profileImageMedium: '',
        totalPhotos: 0,
        totalLikes: 0,
        totalCollections: 0,
      );
  @override
  Future<void> signOut() async {}
}

class _CountingFollowRepository implements FollowRepository {
  _CountingFollowRepository({required this.followResult, required this.unfollowResult});

  final Either<Failure, User> Function() followResult;
  final Either<Failure, User> Function() unfollowResult;
  int followCalls = 0;
  int unfollowCalls = 0;

  @override
  Future<Either<Failure, User>> follow(String username) async {
    followCalls += 1;
    return followResult();
  }

  @override
  Future<Either<Failure, User>> unfollow(String username) async {
    unfollowCalls += 1;
    return unfollowResult();
  }
}

User makeUser({required bool followedByUser}) => User(
      id: 'u1',
      username: 'spaciba',
      name: 'Paula',
      profileImageSmall: 's',
      profileImageMedium: 'm',
      profileImageLarge: 'l',
      totalPhotos: 0,
      totalLikes: 0,
      totalCollections: 0,
      followedByUser: followedByUser,
    );

Future<void> _pumpButton(
  WidgetTester tester, {
  required User user,
  required AuthSession? session,
  required FollowRepository repo,
}) async {
  tester.view.physicalSize = const Size(430, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository(session)),
        followRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Center(child: FollowButton(user: user))),
      ),
    ),
  );
}

void main() {
  testWidgets('renders "Follow" label when user is not followed', (tester) async {
    await _pumpButton(
      tester,
      user: makeUser(followedByUser: false),
      session: null,
      repo: _CountingFollowRepository(
        followResult: () => Right(makeUser(followedByUser: true)),
        unfollowResult: () => Right(makeUser(followedByUser: false)),
      ),
    );

    expect(find.text('Follow'), findsOneWidget);
  });

  testWidgets('renders "Following" label when user is followed', (tester) async {
    await _pumpButton(
      tester,
      user: makeUser(followedByUser: true),
      session: null,
      repo: _CountingFollowRepository(
        followResult: () => Right(makeUser(followedByUser: true)),
        unfollowResult: () => Right(makeUser(followedByUser: false)),
      ),
    );

    expect(find.text('Following'), findsOneWidget);
  });

  testWidgets('unauthenticated tap does not call the repository', (tester) async {
    final repo = _CountingFollowRepository(
      followResult: () => Right(makeUser(followedByUser: true)),
      unfollowResult: () => Right(makeUser(followedByUser: false)),
    );

    await _pumpButton(
      tester,
      user: makeUser(followedByUser: false),
      session: null, // unauthenticated
      repo: repo,
    );

    await tester.tap(find.byType(FollowButton));
    await tester.pump();

    expect(repo.followCalls, 0);
    expect(repo.unfollowCalls, 0);
  });

  testWidgets('authenticated tap calls the repository', (tester) async {
    const session = AuthSession(
      token: 'tk',
      tokenType: 'bearer',
      scope: 'public',
      createdAt: 0,
      user: AuthUser(
        id: 'me',
        username: 'me',
        displayName: 'Me',
        profileImageMedium: '',
        totalPhotos: 0,
        totalLikes: 0,
        totalCollections: 0,
      ),
    );
    final repo = _CountingFollowRepository(
      followResult: () => Right(makeUser(followedByUser: true)),
      unfollowResult: () => Right(makeUser(followedByUser: false)),
    );

    await _pumpButton(
      tester,
      user: makeUser(followedByUser: false),
      session: session,
      repo: repo,
    );

    await tester.tap(find.byType(FollowButton));
    await tester.pumpAndSettle();

    expect(repo.followCalls, 1);
  });
}
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `flutter test test/features/follow/presentation/widgets/follow_button_test.dart`
Expected: FAIL — `Target of URI doesn't exist`.

- [ ] **Step 4: Implement the widget**

Create `lib/features/follow/presentation/widgets/follow_button.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/features/auth/presentation/providers/auth_provider.dart';
import 'package:musea/features/auth/presentation/widgets/auth_gate_sheet.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/features/follow/presentation/controllers/follow_controller.dart';
import 'package:musea/l10n/generated/app_localizations.dart';

enum FollowButtonSize { compact, regular }

class FollowButton extends ConsumerWidget {
  const FollowButton({super.key, required this.user, this.size = FollowButtonSize.regular});

  final User user;
  final FollowButtonSize size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(followControllerProvider(user.username));
    final l10n = AppLocalizations.of(context)!;
    final followed = (user.followedByUser ?? false);
    final inFlight = state is FollowInFlight;

    return _FollowPill(
      size: size,
      label: followed ? l10n.following : l10n.follow,
      showCheck: followed,
      inFlight: inFlight,
      onTap: () => _onTap(context, ref, l10n),
    );
  }

  Future<void> _onTap(BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final auth = ref.read(authControllerProvider);
    if (!auth.isAuthenticated) {
      await showAuthGateSheet(
        context,
        ref,
        title: l10n.followSignInTitle,
        body: l10n.followSignInBody,
      );
      return;
    }

    final controller = ref.read(followControllerProvider(user.username).notifier);
    final messenger = ScaffoldMessenger.of(context);
    await controller.toggle(user);

    final result = ref.read(followControllerProvider(user.username));
    if (result is FollowFailed && context.mounted) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.followUpdateFailed)));
    }
  }
}

class _FollowPill extends StatelessWidget {
  const _FollowPill({
    required this.size,
    required this.label,
    required this.showCheck,
    required this.inFlight,
    required this.onTap,
  });

  final FollowButtonSize size;
  final String label;
  final bool showCheck;
  final bool inFlight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final compact = size == FollowButtonSize.compact;
    final height = compact ? 28.0 : 36.0;
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 12)
        : const EdgeInsets.symmetric(horizontal: 18);
    final fontSize = compact ? 11.0 : 13.0;
    final followed = showCheck;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: inFlight ? null : onTap,
      child: Container(
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: followed ? AppColors.gray100 : AppColors.primary,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (inFlight)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            else if (followed)
              const Icon(Icons.check, size: 14, color: AppColors.gray900),
            if (inFlight || followed) const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: followed ? AppColors.gray900 : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Inspect imports**

`AppColors.gray100` and `AppColors.gray900` must exist. If they don't, open `lib/core/theme/colors.dart` and add them (e.g., `static const Color gray100 = Color(0xFFF4F4F5);` `static const Color gray900 = Color(0xFF18181B);`) — match the palette used by other widgets.

- [ ] **Step 6: Run the test to verify it passes**

Run: `flutter test test/features/follow/presentation/widgets/follow_button_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 7: Commit**

```bash
git add lib/features/follow/presentation/widgets/follow_button.dart test/features/follow/presentation/widgets/follow_button_test.dart lib/l10n/app_en.arb lib/l10n/app_zh.arb lib/l10n/generated/ lib/core/theme/colors.dart
git commit -m "feat(follow): add FollowButton widget"
```

---

## Task 7: Wire `FollowButton` into Photo Detail `_UserRow`

**Files:**
- Modify: `lib/features/photo_detail/presentation/pages/photo_detail_page.dart:464-528` (the `_UserRow` widget)
- Modify: `test/features/photo_detail/presentation/pages/photo_detail_page_test.dart`

- [ ] **Step 1: Locate the static Follow `Container` in `_UserRow`**

In `lib/features/photo_detail/presentation/pages/photo_detail_page.dart`, find the `_UserRow` widget (around line 464-528). The trailing `Container` with `Text(l10n.follow, ...)` is the static pill to replace.

- [ ] **Step 2: Replace the static pill with `FollowButton`**

Add the import near the top of the file:

```dart
import 'package:musea/features/follow/presentation/widgets/follow_button.dart';
```

Replace the entire `Container(height: 32, padding: ..., child: Center(child: Text(l10n.follow, ...)))` block at the end of the `_UserRow`'s `Row` children with:

```dart
FollowButton(
  user: photo.user,
  size: FollowButtonSize.compact,
),
```

- [ ] **Step 3: Run the existing photo detail test to find what breaks**

Run: `flutter test test/features/photo_detail/presentation/pages/photo_detail_page_test.dart`
Expected: at least one test references the literal "Follow" text in the static pill. With the new `FollowButton` consumer widget, the label now reads from `widget.user.followedByUser` directly, so the test should still find the "Follow" text without any extra pump.

- [ ] **Step 4: Update the test setup if needed**

Locate where the photo is constructed in the failing test. Ensure the `user` field on the photo has `followedByUser: false` (or true) as the test expects. The literal `find.text('Follow')` (or whatever the test uses) should now find the button — no extra `pump` is required because the label is read from `widget.user` directly.

If the test asserts the **shape** of the trailing widget (e.g. that it is a `Container` with a black background), update that assertion to look for `find.byType(FollowButton)` instead.

- [ ] **Step 5: Run the photo detail test to verify it passes**

Run: `flutter test test/features/photo_detail/presentation/pages/photo_detail_page_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/photo_detail/presentation/pages/photo_detail_page.dart test/features/photo_detail/presentation/pages/photo_detail_page_test.dart
git commit -m "feat(photo-detail): wire FollowButton into _UserRow"
```

---

## Task 8: Wire `FollowButton` into the Profile Page hero

**Files:**
- Modify: `lib/features/profile/presentation/pages/profile_page.dart` (the hero region of `_ProfileContent`)

- [ ] **Step 1: Locate the hero region**

Open `lib/features/profile/presentation/pages/profile_page.dart` and find the hero block (avatar + name + username + bio). The exact location depends on the current implementation. If a `Follow` text is already rendered there as a static decoration, replace it; if it isn't rendered at all, add a new trailing widget.

- [ ] **Step 2: Add the import**

```dart
import 'package:musea/features/auth/presentation/providers/auth_provider.dart';
import 'package:musea/features/follow/presentation/widgets/follow_button.dart';
```

- [ ] **Step 3: Add the `FollowButton` in the hero region**

Inside the hero `Row` (or wherever the trailing slot is), after the user info column, add:

```dart
Consumer(
  builder: (context, ref, _) {
    final auth = ref.watch(authControllerProvider);
    final isSelf = auth.session?.user.username == user.username;
    if (isSelf) return const SizedBox.shrink();
    return FollowButton(user: user, size: FollowButtonSize.regular);
  },
),
```

Adjust the `user` reference to match the local variable in scope (the file may use `user` or `_user`).

- [ ] **Step 4: Run the existing profile page test**

Run: `flutter test test/features/profile/presentation/pages/profile_page_test.dart`
Expected: any assertion that "no FollowButton is present" for non-self users will now fail.

- [ ] **Step 5: Update the test to expect the button when not viewing self**

In the test, when the profile is someone other than the signed-in user, add:

```dart
expect(find.byType(FollowButton), findsOneWidget);
```

When viewing self, the button is hidden — assert `findsNothing`. No `pump` is needed because `FollowButton` is a plain `ConsumerWidget`.

- [ ] **Step 6: Run the test to verify it passes**

Run: `flutter test test/features/profile/presentation/pages/profile_page_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/profile/presentation/pages/profile_page.dart test/features/profile/presentation/pages/profile_page_test.dart
git commit -m "feat(profile): wire FollowButton into hero region"
```

---

## Task 9: Final pass — analyze and full test suite

**Files:** none

- [ ] **Step 1: Run `flutter analyze`**

Run: `flutter analyze`
Expected: no errors. Fix any warnings before continuing.

- [ ] **Step 2: Run the full test suite**

Run: `flutter test`
Expected: all green.

- [ ] **Step 3: Manually smoke test (optional but recommended)**

Run: `flutter run` on a simulator. Sign in, open Photo Detail, tap Follow → see the pill flip to "Following" with a check, and the count not change in the UI (the API call updates it on next fetch). Tap again to unfollow. Sign out, tap Follow → auth gate sheet appears.

- [ ] **Step 4: Final commit (if any analyze / test fixups were made)**

```bash
git add -A
git commit -m "chore(follow): final pass fixes from analyze + full test run"
```

(only run this if there are uncommitted changes)
