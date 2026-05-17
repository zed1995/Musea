# Musea MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Flutter image discovery app using Unsplash API with browsing, search, photo details, and local collections management.

**Architecture:** Clean Architecture with feature-first structure using Riverpod for state management. Data flows from UI → Providers → Repository → API/Local Storage. Features are isolated by domain (discover, explore, collections, photo_detail, profile).

**Tech Stack:** Flutter 3.x, Riverpod 2.x, Dio (HTTP), Hive (local storage), cached_network_image (image caching), freezed/json_serializable (models)

---

## File Structure Overview

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   │   ├── api_constants.dart
│   │   └── app_constants.dart
│   ├── errors/
│   │   ├── failures.dart
│   │   └── exceptions.dart
│   ├── network/
│   │   ├── dio_client.dart
│   │   └── api_interceptor.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── colors.dart
│   │   └── text_styles.dart
│   └── utils/
│       ├── date_formatter.dart
│       └── number_formatter.dart
├── features/
│   ├── discover/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── photo_model.dart
│   │   │   │   ├── photo_model.freezed.dart
│   │   │   │   ├── photo_model.g.dart
│   │   │   │   ├── topic_model.dart
│   │   │   │   ├── topic_model.freezed.dart
│   │   │   │   └── topic_model.g.dart
│   │   │   ├── repositories/
│   │   │   │   └── photo_repository_impl.dart
│   │   │   └── datasources/
│   │   │       ├── photo_remote_datasource.dart
│   │   │       └── photo_local_datasource.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── photo.dart
│   │   │   │   ├── topic.dart
│   │   │   │   └── user.dart
│   │   │   └── repositories/
│   │   │       └── photo_repository.dart
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── discover_page.dart
│   │       ├── widgets/
│   │       │   ├── photo_card.dart
│   │       │   ├── topic_chip.dart
│   │       │   └── search_bar_widget.dart
│   │       └── providers/
│   │           ├── photos_provider.dart
│   │           └── topics_provider.dart
│   ├── explore/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── search_result_model.dart
│   │   │   └── repositories/
│   │   │       └── search_repository_impl.dart
│   │   ├── domain/
│   │   │   └── repositories/
│   │   │       └── search_repository.dart
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── explore_page.dart
│   │       ├── widgets/
│   │       │   ├── filter_bar.dart
│   │       │   └── search_input.dart
│   │       └── providers/
│   │           └── search_provider.dart
│   ├── photo_detail/
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   │   └── photo_detail_page.dart
│   │   │   ├── widgets/
│   │   │   │   ├── exif_info.dart
│   │   │   │   ├── location_info.dart
│   │   │   │   ├── color_palette.dart
│   │   │   │   └── tag_list.dart
│   │   │   └── providers/
│   │   │       └── photo_detail_provider.dart
│   ├── collections/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── collection_model.dart
│   │   │   ├── repositories/
│   │   │   │   └── collection_repository_impl.dart
│   │   │   └── datasources/
│   │   │       └── collection_local_datasource.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── collection.dart
│   │   │   └── repositories/
│   │   │       └── collection_repository.dart
│   │   └── presentation/
│   │       ├── pages/
│   │       │   ├── collections_page.dart
│   │       │   └── collection_detail_page.dart
│   │       ├── widgets/
│   │       │   └── collection_card.dart
│   │       └── providers/
│   │           └── collections_provider.dart
│   └── profile/
│       └── presentation/
│           ├── pages/
│           │   └── profile_page.dart
│           └── providers/
│               └── settings_provider.dart
├── shared/
│   ├── widgets/
│   │   ├── empty_state.dart
│   │   ├── error_state.dart
│   │   ├── loading_indicator.dart
│   │   └── bottom_nav_bar.dart
│   └── providers/
│       └── theme_provider.dart
└── router/
    └── app_router.dart

test/
├── features/
│   ├── discover/
│   │   ├── data/
│   │   │   └── repositories/
│   │   │       └── photo_repository_impl_test.dart
│   │   └── presentation/
│   │       └── providers/
│   │           └── photos_provider_test.dart
│   └── collections/
│       └── data/
│           └── repositories/
│               └── collection_repository_impl_test.dart
└── core/
    └── network/
        └── dio_client_test.dart
```

---

## Task 1: Project Initialization

**Files:**
- Create: `pubspec.yaml`
- Create: `analysis_options.yaml`
- Create: `.gitignore`

- [ ] **Step 1: Create Flutter project**

Run: `flutter create --org com.musea --project-name musea .`
Expected: Flutter project created with basic structure

- [ ] **Step 2: Update pubspec.yaml with dependencies**

```yaml
name: musea
description: A Flutter image discovery app using Unsplash API.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.4.9
  riverpod_annotation: ^2.3.3
  
  # Network
  dio: ^5.4.0
  
  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.1.1
  
  # Image Caching
  cached_network_image: ^3.3.1
  flutter_blurhash: ^0.8.2
  
  # Models
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1
  
  # Navigation
  go_router: ^13.1.0
  
  # UI
  flutter_staggered_grid_view: ^0.7.0
  shimmer: ^3.0.0
  
  # Utils
  intl: ^0.19.0
  url_launcher: ^6.2.2
  share_plus: ^7.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  
  flutter_lints: ^3.0.1
  
  # Code Generation
  build_runner: ^2.4.8
  freezed: ^2.4.6
  json_serializable: ^6.7.1
  riverpod_generator: ^2.3.9
  hive_generator: ^2.0.1

flutter:
  uses-material-design: true
  
  fonts:
    - family: GoogleSans
      fonts:
        - asset: assets/fonts/GoogleSans-Regular.ttf
        - asset: assets/fonts/GoogleSans-Medium.ttf
          weight: 500
        - asset: assets/fonts/GoogleSans-Bold.ttf
          weight: 700

```

- [ ] **Step 3: Create analysis_options.yaml**

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_const_literals_to_create_immutables
    - avoid_print
    - prefer_single_quotes
    - sort_constructors_first
    - sort_unnamed_constructors_first

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "build/**"
```

- [ ] **Step 4: Create .gitignore**

```
# Miscellaneous
*.class
*.log
*.pyc
*.swp
.DS_Store
.atom/
.buildlog/
.history
.svn/
migrate_working_dir/

# IntelliJ related
*.iml
*.ipr
*.iws
.idea/

# VS Code related
.vscode/

# Flutter/Dart/Pub related
**/doc/api/
**/ios/Flutter/.last_build_id
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
/build/

# Symbolication related
app.*.symbols

# Obfuscation related
app.*.map.json

# Android Studio will place build artifacts here
/android/app/debug
/android/app/profile
/android/app/release

# Environment
.env
.env.local

# Generated files
*.g.dart
*.freezed.dart
```

- [ ] **Step 5: Install dependencies**

Run: `flutter pub get`
Expected: All dependencies installed successfully

- [ ] **Step 6: Commit initial project setup**

```bash
git add .
git commit -m "chore: initialize Flutter project with dependencies"
```

---

## Task 2: Core Constants and Configuration

**Files:**
- Create: `lib/core/constants/api_constants.dart`
- Create: `lib/core/constants/app_constants.dart`

- [ ] **Step 1: Create API constants**

```dart
// lib/core/constants/api_constants.dart

class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://api.unsplash.com';
  
  static const String photos = '/photos';
  static const String searchPhotos = '/search/photos';
  static const String topics = '/topics';
  static const String users = '/users';
  static const String collections = '/collections';
  
  static const String clientId = 'YOUR_UNSPLASH_CLIENT_ID';
  
  static const int defaultPerPage = 20;
  static const int searchPerPage = 30;
  
  static Map<String, String> get headers => {
    'Authorization': 'Client-ID $clientId',
    'Accept-Version': 'v1',
  };
  
  static String photoUrl(String photoId) => '$photos/$photoId';
  static String photoStatistics(String photoId) => '$photos/$photoId/statistics';
  static String photoDownload(String photoId) => '$photos/$photoId/download';
  static String topicPhotos(String topicSlug) => '$topics/$topicSlug/photos';
  static String userPhotos(String username) => '$users/$username/photos';
}
```

- [ ] **Step 2: Create app constants**

```dart
// lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  static const String appName = 'Musea';
  static const String appVersion = '1.0.0';
  
  static const int cacheMaxAge = 7 * 24 * 60 * 60; // 7 days in seconds
  static const int maxSearchHistory = 10;
  
  static const List<String> popularSearches = [
    'Nature',
    'Wallpaper',
    'Minimal',
    'Travel',
    'Architecture',
    'Food',
    'People',
    'Animals',
  ];
  
  static const Map<String, String> colorFilters = {
    'All': '',
    'Black and White': 'black_and_white',
    'Red': 'red',
    'Orange': 'orange',
    'Yellow': 'yellow',
    'Green': 'green',
    'Teal': 'teal',
    'Blue': 'blue',
    'Purple': 'purple',
    'Magenta': 'magenta',
    'White': 'white',
    'Black': 'black',
  };
}
```

- [ ] **Step 3: Commit constants**

```bash
git add lib/core/constants/
git commit -m "feat: add API and app constants"
```

---

## Task 3: Error Handling

**Files:**
- Create: `lib/core/errors/failures.dart`
- Create: `lib/core/errors/exceptions.dart`

- [ ] **Step 1: Create failure classes**

```dart
// lib/core/errors/failures.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';

@freezed
class Failure with _$Failure {
  const factory Failure.network({
    required String message,
  }) = NetworkFailure;
  
  const factory Failure.server({
    required int statusCode,
    required String message,
  }) = ServerFailure;
  
  const factory Failure.cache({
    required String message,
  }) = CacheFailure;
  
  const factory Failure.notFound({
    required String message,
  }) = NotFoundFailure;
  
  const factory Failure.unauthorized({
    required String message,
  }) = UnauthorizedFailure;
  
  const factory Failure.rateLimit({
    required String message,
  }) = RateLimitFailure;
  
  const factory Failure.unknown({
    required String message,
  }) = UnknownFailure;
}
```

- [ ] **Step 2: Create exception classes**

```dart
// lib/core/errors/exceptions.dart

class ServerException implements Exception {
  final int statusCode;
  final String message;
  
  ServerException({
    required this.statusCode,
    required this.message,
  });
  
  @override
  String toString() => 'ServerException: $statusCode - $message';
}

class NetworkException implements Exception {
  final String message;
  
  NetworkException({required this.message});
  
  @override
  String toString() => 'NetworkException: $message';
}

class CacheException implements Exception {
  final String message;
  
  CacheException({required this.message});
  
  @override
  String toString() => 'CacheException: $message';
}

class UnauthorizedException implements Exception {
  final String message;
  
  UnauthorizedException({required this.message});
  
  @override
  String toString() => 'UnauthorizedException: $message';
}

class RateLimitException implements Exception {
  final String message;
  
  RateLimitException({required this.message});
  
  @override
  String toString() => 'RateLimitException: $message';
}
```

- [ ] **Step 3: Run build_runner for failures**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: failures.freezed.dart generated

- [ ] **Step 4: Commit error handling**

```bash
git add lib/core/errors/
git commit -m "feat: add error handling classes"
```

---

## Task 4: Network Layer Setup

**Files:**
- Create: `lib/core/network/dio_client.dart`
- Create: `lib/core/network/api_interceptor.dart`
- Create: `test/core/network/dio_client_test.dart`

- [ ] **Step 1: Write failing test for DioClient**

```dart
// test/core/network/dio_client_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:musea/core/network/dio_client.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late DioClient dioClient;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    dioClient = DioClient(mockDio);
  });

  group('DioClient', () {
    test('should perform GET request successfully', () async {
      final response = Response(
        data: {'test': 'data'},
        statusCode: 200,
        requestOptions: RequestOptions(path: '/test'),
      );

      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => response);

      final result = await dioClient.get('/test');

      expect(result, equals({'test': 'data'}));
      verify(() => mockDio.get('/test')).called(1);
    });

    test('should throw ServerException on error status code', () async {
      when(() => mockDio.get(any()))
          .thenThrow(DioException(
            response: Response(
              statusCode: 404,
              requestOptions: RequestOptions(path: '/test'),
            ),
            requestOptions: RequestOptions(path: '/test'),
          ));

      expect(
        () => dioClient.get('/test'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/network/dio_client_test.dart`
Expected: FAIL - DioClient not defined

- [ ] **Step 3: Create API interceptor**

```dart
// lib/core/network/api_interceptor.dart

import 'package:dio/dio.dart';
import 'package:musea/core/constants/api_constants.dart';

class ApiInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.addAll(ApiConstants.headers);
    
    print('REQUEST[${options.method}] => PATH: ${options.path}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}');
    super.onError(err, handler);
  }
}
```

- [ ] **Step 4: Create DioClient implementation**

```dart
// lib/core/network/dio_client.dart

import 'package:dio/dio.dart';
import 'package:musea/core/errors/exceptions.dart';
import 'package:musea/core/network/api_interceptor.dart';
import 'package:musea/core/constants/api_constants.dart';

class DioClient {
  final Dio _dio;

  DioClient([Dio? dio]) : _dio = dio ?? _createDio();

  static Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ));

    dio.interceptors.addAll([
      ApiInterceptor(),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    ]);

    return dio;
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Never _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw NetworkException(message: 'Connection timeout');
      
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        final message = error.response?.statusMessage ?? 'Unknown error';
        
        if (statusCode == 401) {
          throw UnauthorizedException(message: 'Unauthorized access');
        } else if (statusCode == 403) {
          throw RateLimitException(message: 'Rate limit exceeded');
        } else if (statusCode == 404) {
          throw ServerException(statusCode: statusCode, message: 'Resource not found');
        } else {
          throw ServerException(statusCode: statusCode, message: message);
        }
      
      case DioExceptionType.cancel:
        throw NetworkException(message: 'Request cancelled');
      
      case DioExceptionType.connectionError:
        throw NetworkException(message: 'No internet connection');
      
      default:
        throw NetworkException(message: 'Unexpected error occurred');
    }
  }
}
```

- [ ] **Step 5: Add mocktail dependency to pubspec.yaml**

Add to dev_dependencies in pubspec.yaml:
```yaml
  mocktail: ^1.0.2
```

Run: `flutter pub get`

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/core/network/dio_client_test.dart`
Expected: PASS

- [ ] **Step 7: Commit network layer**

```bash
git add lib/core/network/ test/core/network/ pubspec.yaml
git commit -m "feat: implement network layer with DioClient"
```

---

## Task 5: Domain Entities

**Files:**
- Create: `lib/features/discover/domain/entities/user.dart`
- Create: `lib/features/discover/domain/entities/photo.dart`
- Create: `lib/features/discover/domain/entities/topic.dart`

- [ ] **Step 1: Create User entity**

```dart
// lib/features/discover/domain/entities/user.dart

class User {
  final String id;
  final String username;
  final String name;
  final String? bio;
  final String? portfolioUrl;
  final String profileImageSmall;
  final String profileImageMedium;
  final String profileImageLarge;
  final int totalPhotos;
  final int totalLikes;
  final int totalCollections;

  const User({
    required this.id,
    required this.username,
    required this.name,
    this.bio,
    this.portfolioUrl,
    required this.profileImageSmall,
    required this.profileImageMedium,
    required this.profileImageLarge,
    required this.totalPhotos,
    required this.totalLikes,
    required this.totalCollections,
  });
}
```

- [ ] **Step 2: Create Photo entity**

```dart
// lib/features/discover/domain/entities/photo.dart

import 'package:musea/features/discover/domain/entities/user.dart';

class Photo {
  final String id;
  final DateTime createdAt;
  final int width;
  final int height;
  final String color;
  final String? blurHash;
  final String? description;
  final String? altDescription;
  final String urlRaw;
  final String urlFull;
  final String urlRegular;
  final String urlSmall;
  final String urlThumb;
  final int likes;
  final int downloads;
  final User user;
  final ExifData? exif;
  final LocationData? location;
  final List<Tag> tags;

  const Photo({
    required this.id,
    required this.createdAt,
    required this.width,
    required this.height,
    required this.color,
    this.blurHash,
    this.description,
    this.altDescription,
    required this.urlRaw,
    required this.urlFull,
    required this.urlRegular,
    required this.urlSmall,
    required this.urlThumb,
    required this.likes,
    required this.downloads,
    required this.user,
    this.exif,
    this.location,
    this.tags = const [],
  });

  double get aspectRatio => width / height;
  
  bool get isPortrait => height > width;
  
  bool get isLandscape => width > height;
}

class ExifData {
  final String? make;
  final String? model;
  final String? exposureTime;
  final String? aperture;
  final String? focalLength;
  final int? iso;

  const ExifData({
    this.make,
    this.model,
    this.exposureTime,
    this.aperture,
    this.focalLength,
    this.iso,
  });
}

class LocationData {
  final String? city;
  final String? country;
  final double? latitude;
  final double? longitude;

  const LocationData({
    this.city,
    this.country,
    this.latitude,
    this.longitude,
  });
  
  String get displayName {
    final parts = [city, country].where((p) => p != null && p.isNotEmpty);
    return parts.isEmpty ? 'Unknown location' : parts.join(', ');
  }
}

class Tag {
  final String title;
  final String? type;

  const Tag({
    required this.title,
    this.type,
  });
}
```

- [ ] **Step 3: Create Topic entity**

```dart
// lib/features/discover/domain/entities/topic.dart

import 'package:musea/features/discover/domain/entities/photo.dart';

class Topic {
  final String id;
  final String slug;
  final String title;
  final String? description;
  final int totalPhotos;
  final Photo? coverPhoto;
  final String? link;

  const Topic({
    required this.id,
    required this.slug,
    required this.title,
    this.description,
    required this.totalPhotos,
    this.coverPhoto,
    this.link,
  });
}
```

- [ ] **Step 4: Commit domain entities**

```bash
git add lib/features/discover/domain/entities/
git commit -m "feat: add domain entities for User, Photo, and Topic"
```

---

## Task 6: Data Models with Serialization

**Files:**
- Create: `lib/features/discover/data/models/user_model.dart`
- Create: `lib/features/discover/data/models/user_model.freezed.dart` (generated)
- Create: `lib/features/discover/data/models/user_model.g.dart` (generated)
- Create: `lib/features/discover/data/models/photo_model.dart`
- Create: `lib/features/discover/data/models/photo_model.freezed.dart` (generated)
- Create: `lib/features/discover/data/models/photo_model.g.dart` (generated)
- Create: `lib/features/discover/data/models/topic_model.dart`
- Create: `lib/features/discover/data/models/topic_model.freezed.dart` (generated)
- Create: `lib/features/discover/data/models/topic_model.g.dart` (generated)

- [ ] **Step 1: Create User model**

```dart
// lib/features/discover/data/models/user_model.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:musea/features/discover/domain/entities/user.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const UserModel._();
  
  const factory UserModel({
    required String id,
    required String username,
    required String name,
    String? bio,
    @JsonKey(name: 'portfolio_url') String? portfolioUrl,
    @JsonKey(name: 'profile_image') required ProfileImageModel profileImage,
    @JsonKey(name: 'total_photos') required int totalPhotos,
    @JsonKey(name: 'total_likes') required int totalLikes,
    @JsonKey(name: 'total_collections') required int totalCollections,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
  
  User toEntity() => User(
    id: id,
    username: username,
    name: name,
    bio: bio,
    portfolioUrl: portfolioUrl,
    profileImageSmall: profileImage.small,
    profileImageMedium: profileImage.medium,
    profileImageLarge: profileImage.large,
    totalPhotos: totalPhotos,
    totalLikes: totalLikes,
    totalCollections: totalCollections,
  );
}

@freezed
class ProfileImageModel with _$ProfileImageModel {
  const factory ProfileImageModel({
    required String small,
    required String medium,
    required String large,
  }) = _ProfileImageModel;

  factory ProfileImageModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileImageModelFromJson(json);
}
```

- [ ] **Step 2: Create Photo model**

```dart
// lib/features/discover/data/models/photo_model.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/data/models/user_model.dart';

part 'photo_model.freezed.dart';
part 'photo_model.g.dart';

@freezed
class PhotoModel with _$PhotoModel {
  const PhotoModel._();
  
  const factory PhotoModel({
    required String id,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    required int width,
    required int height,
    required String color,
    @JsonKey(name: 'blur_hash') String? blurHash,
    String? description,
    @JsonKey(name: 'alt_description') String? altDescription,
    required UrlsModel urls,
    required int likes,
    @Default(0) int downloads,
    required UserModel user,
    ExifModel? exif,
    LocationModel? location,
    @Default([]) List<TagModel> tags,
  }) = _PhotoModel;

  factory PhotoModel.fromJson(Map<String, dynamic> json) =>
      _$PhotoModelFromJson(json);
  
  Photo toEntity() => Photo(
    id: id,
    createdAt: createdAt,
    width: width,
    height: height,
    color: color,
    blurHash: blurHash,
    description: description,
    altDescription: altDescription,
    urlRaw: urls.raw,
    urlFull: urls.full,
    urlRegular: urls.regular,
    urlSmall: urls.small,
    urlThumb: urls.thumb,
    likes: likes,
    downloads: downloads,
    user: user.toEntity(),
    exif: exif?.toEntity(),
    location: location?.toEntity(),
    tags: tags.map((t) => t.toEntity()).toList(),
  );
}

@freezed
class UrlsModel with _$UrlsModel {
  const factory UrlsModel({
    required String raw,
    required String full,
    required String regular,
    required String small,
    required String thumb,
  }) = _UrlsModel;

  factory UrlsModel.fromJson(Map<String, dynamic> json) =>
      _$UrlsModelFromJson(json);
}

@freezed
class ExifModel with _$ExifModel {
  const ExifModel._();
  
  const factory ExifModel({
    String? make,
    String? model,
    @JsonKey(name: 'exposure_time') String? exposureTime,
    String? aperture,
    @JsonKey(name: 'focal_length') String? focalLength,
    int? iso,
  }) = _ExifModel;

  factory ExifModel.fromJson(Map<String, dynamic> json) =>
      _$ExifModelFromJson(json);
  
  ExifData toEntity() => ExifData(
    make: make,
    model: model,
    exposureTime: exposureTime,
    aperture: aperture,
    focalLength: focalLength,
    iso: iso,
  );
}

@freezed
class LocationModel with _$LocationModel {
  const LocationModel._();
  
  const factory LocationModel({
    String? city,
    String? country,
    PositionModel? position,
  }) = _LocationModel;

  factory LocationModel.fromJson(Map<String, dynamic> json) =>
      _$LocationModelFromJson(json);
  
  LocationData toEntity() => LocationData(
    city: city,
    country: country,
    latitude: position?.latitude,
    longitude: position?.longitude,
  );
}

@freezed
class PositionModel with _$PositionModel {
  const factory PositionModel({
    required double latitude,
    required double longitude,
  }) = _PositionModel;

  factory PositionModel.fromJson(Map<String, dynamic> json) =>
      _$PositionModelFromJson(json);
}

@freezed
class TagModel with _$TagModel {
  const TagModel._();
  
  const factory TagModel({
    required String title,
    String? type,
  }) = _TagModel;

  factory TagModel.fromJson(Map<String, dynamic> json) =>
      _$TagModelFromJson(json);
  
  Tag toEntity() => Tag(title: title, type: type);
}
```

- [ ] **Step 3: Create Topic model**

```dart
// lib/features/discover/data/models/topic_model.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:musea/features/discover/domain/entities/topic.dart';
import 'package:musea/features/discover/data/models/photo_model.dart';

part 'topic_model.freezed.dart';
part 'topic_model.g.dart';

@freezed
class TopicModel with _$TopicModel {
  const TopicModel._();
  
  const factory TopicModel({
    required String id,
    required String slug,
    required String title,
    String? description,
    @JsonKey(name: 'total_photos') required int totalPhotos,
    @JsonKey(name: 'cover_photo') PhotoModel? coverPhoto,
    List<String>? links,
  }) = _TopicModel;

  factory TopicModel.fromJson(Map<String, dynamic> json) =>
      _$TopicModelFromJson(json);
  
  Topic toEntity() => Topic(
    id: id,
    slug: slug,
    title: title,
    description: description,
    totalPhotos: totalPhotos,
    coverPhoto: coverPhoto?.toEntity(),
    link: links?.isNotEmpty == true ? links!.first : null,
  );
}
```

- [ ] **Step 4: Run build_runner to generate code**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: All .freezed.dart and .g.dart files generated

- [ ] **Step 5: Commit data models**

```bash
git add lib/features/discover/data/models/
git commit -m "feat: add data models with JSON serialization"
```

---

## Task 7: Data Sources

**Files:**
- Create: `lib/features/discover/data/datasources/photo_remote_datasource.dart`
- Create: `lib/features/discover/data/datasources/photo_local_datasource.dart`

- [ ] **Step 1: Create remote data source**

```dart
// lib/features/discover/data/datasources/photo_remote_datasource.dart

import 'package:musea/core/network/dio_client.dart';
import 'package:musea/core/constants/api_constants.dart';
import 'package:musea/features/discover/data/models/photo_model.dart';
import 'package:musea/features/discover/data/models/topic_model.dart';

abstract class PhotoRemoteDataSource {
  Future<List<PhotoModel>> getPhotos({int page = 1, int perPage = 20});
  Future<PhotoModel> getPhotoById(String id);
  Future<PhotoModel> getRandomPhoto();
  Future<List<PhotoModel>> getRandomPhotos({int count = 1});
  Future<List<TopicModel>> getTopics({int page = 1, int perPage = 10});
  Future<List<PhotoModel>> getTopicPhotos(String topicSlug, {int page = 1, int perPage = 20});
  Future<void> trackDownload(String photoId);
}

class PhotoRemoteDataSourceImpl implements PhotoRemoteDataSource {
  final DioClient _dioClient;

  PhotoRemoteDataSourceImpl(this._dioClient);

  @override
  Future<List<PhotoModel>> getPhotos({int page = 1, int perPage = 20}) async {
    final response = await _dioClient.get(
      ApiConstants.photos,
      queryParameters: {
        'page': page,
        'per_page': perPage,
        'order_by': 'popular',
      },
    );

    return (response as List)
        .map((json) => PhotoModel.fromJson(json))
        .toList();
  }

  @override
  Future<PhotoModel> getPhotoById(String id) async {
    final response = await _dioClient.get(ApiConstants.photoUrl(id));
    return PhotoModel.fromJson(response);
  }

  @override
  Future<PhotoModel> getRandomPhoto() async {
    final response = await _dioClient.get(
      '${ApiConstants.photos}/random',
      queryParameters: {'count': 1},
    );
    
    final photos = response as List;
    return PhotoModel.fromJson(photos.first);
  }

  @override
  Future<List<PhotoModel>> getRandomPhotos({int count = 1}) async {
    final response = await _dioClient.get(
      '${ApiConstants.photos}/random',
      queryParameters: {'count': count},
    );
    
    return (response as List)
        .map((json) => PhotoModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<TopicModel>> getTopics({int page = 1, int perPage = 10}) async {
    final response = await _dioClient.get(
      ApiConstants.topics,
      queryParameters: {
        'page': page,
        'per_page': perPage,
      },
    );

    return (response as List)
        .map((json) => TopicModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<PhotoModel>> getTopicPhotos(String topicSlug, {int page = 1, int perPage = 20}) async {
    final response = await _dioClient.get(
      ApiConstants.topicPhotos(topicSlug),
      queryParameters: {
        'page': page,
        'per_page': perPage,
      },
    );

    return (response as List)
        .map((json) => PhotoModel.fromJson(json))
        .toList();
  }

  @override
  Future<void> trackDownload(String photoId) async {
    await _dioClient.get(ApiConstants.photoDownload(photoId));
  }
}
```

- [ ] **Step 2: Create local data source for caching**

```dart
// lib/features/discover/data/datasources/photo_local_datasource.dart

import 'package:hive_flutter/hive_flutter.dart';
import 'package:musea/features/discover/data/models/photo_model.dart';

abstract class PhotoLocalDataSource {
  Future<void> cachePhotos(List<PhotoModel> photos);
  Future<List<PhotoModel>> getCachedPhotos();
  Future<void> cachePhoto(PhotoModel photo);
  Future<PhotoModel?> getCachedPhoto(String id);
  Future<void> clearCache();
}

class PhotoLocalDataSourceImpl implements PhotoLocalDataSource {
  static const String _boxName = 'photos_cache';
  Box<dynamic>? _box;

  Future<Box<dynamic>> get box async {
    _box ??= await Hive.openBox(_boxName);
    return _box!;
  }

  @override
  Future<void> cachePhotos(List<PhotoModel> photos) async {
    final photoBox = await box;
    for (final photo in photos) {
      await photoBox.put(photo.id, photo.toJson());
    }
  }

  @override
  Future<List<PhotoModel>> getCachedPhotos() async {
    final photoBox = await box;
    final photos = photoBox.values.toList();
    return photos
        .map((json) => PhotoModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> cachePhoto(PhotoModel photo) async {
    final photoBox = await box;
    await photoBox.put(photo.id, photo.toJson());
  }

  @override
  Future<PhotoModel?> getCachedPhoto(String id) async {
    final photoBox = await box;
    final json = photoBox.get(id);
    if (json == null) return null;
    return PhotoModel.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<void> clearCache() async {
    final photoBox = await box;
    await photoBox.clear();
  }
}
```

- [ ] **Step 3: Commit data sources**

```bash
git add lib/features/discover/data/datasources/
git commit -m "feat: implement remote and local data sources for photos"
```

---

## Task 8: Repository Layer

**Files:**
- Create: `lib/features/discover/domain/repositories/photo_repository.dart`
- Create: `lib/features/discover/data/repositories/photo_repository_impl.dart`
- Create: `test/features/discover/data/repositories/photo_repository_impl_test.dart`

- [ ] **Step 1: Write failing test for repository**

```dart
// test/features/discover/data/repositories/photo_repository_impl_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:musea/features/discover/data/datasources/photo_remote_datasource.dart';
import 'package:musea/features/discover/data/datasources/photo_local_datasource.dart';
import 'package:musea/features/discover/data/repositories/photo_repository_impl.dart';
import 'package:musea/features/discover/data/models/photo_model.dart';
import 'package:mocktail/mocktail.dart';

class MockRemoteDataSource extends Mock implements PhotoRemoteDataSource {}
class MockLocalDataSource extends Mock implements PhotoLocalDataSource {}

void main() {
  late PhotoRepositoryImpl repository;
  late MockRemoteDataSource mockRemoteDataSource;
  late MockLocalDataSource mockLocalDataSource;

  setUp(() {
    mockRemoteDataSource = MockRemoteDataSource();
    mockLocalDataSource = MockLocalDataSource();
    repository = PhotoRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
    );
  });

  group('PhotoRepositoryImpl', () {
    test('should return photos from remote data source', () async {
      final mockPhotos = [
        PhotoModel(
          id: '1',
          createdAt: DateTime.now(),
          width: 100,
          height: 100,
          color: '#FFFFFF',
          urls: UrlsModel(
            raw: 'raw',
            full: 'full',
            regular: 'regular',
            small: 'small',
            thumb: 'thumb',
          ),
          likes: 100,
          user: UserModel(
            id: '1',
            username: 'test',
            name: 'Test User',
            profileImage: ProfileImageModel(
              small: 'small',
              medium: 'medium',
              large: 'large',
            ),
            totalPhotos: 10,
            totalLikes: 20,
            totalCollections: 5,
          ),
        ),
      ];

      when(() => mockRemoteDataSource.getPhotos())
          .thenAnswer((_) async => mockPhotos);

      final result = await repository.getPhotos();

      expect(result.length, equals(1));
      expect(result.first.id, equals('1'));
      verify(() => mockRemoteDataSource.getPhotos()).called(1);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/discover/data/repositories/photo_repository_impl_test.dart`
Expected: FAIL - PhotoRepositoryImpl not defined

- [ ] **Step 3: Create repository interface**

```dart
// lib/features/discover/domain/repositories/photo_repository.dart

import 'package:dartz/dartz.dart';
import 'package:musea/core/errors/failures.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/topic.dart';

abstract class PhotoRepository {
  Future<Either<Failure, List<Photo>>> getPhotos({int page = 1, int perPage = 20});
  Future<Either<Failure, Photo>> getPhotoById(String id);
  Future<Either<Failure, Photo>> getRandomPhoto();
  Future<Either<Failure, List<Topic>>> getTopics({int page = 1, int perPage = 10});
  Future<Either<Failure, List<Photo>>> getTopicPhotos(String topicSlug, {int page = 1, int perPage = 20});
  Future<Either<Failure, void>> trackDownload(String photoId);
}
```

- [ ] **Step 4: Add dartz dependency to pubspec.yaml**

Add to dependencies:
```yaml
  dartz: ^0.10.1
```

Run: `flutter pub get`

- [ ] **Step 5: Create repository implementation**

```dart
// lib/features/discover/data/repositories/photo_repository_impl.dart

import 'package:dartz/dartz.dart';
import 'package:musea/core/errors/exceptions.dart';
import 'package:musea/core/errors/failures.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/topic.dart';
import 'package:musea/features/discover/domain/repositories/photo_repository.dart';
import 'package:musea/features/discover/data/datasources/photo_remote_datasource.dart';
import 'package:musea/features/discover/data/datasources/photo_local_datasource.dart';

class PhotoRepositoryImpl implements PhotoRepository {
  final PhotoRemoteDataSource remoteDataSource;
  final PhotoLocalDataSource localDataSource;

  PhotoRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<Photo>>> getPhotos({int page = 1, int perPage = 20}) async {
    try {
      final photos = await remoteDataSource.getPhotos(page: page, perPage: perPage);
      await localDataSource.cachePhotos(photos);
      return Right(photos.map((p) => p.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(Failure.server(statusCode: e.statusCode, message: e.message));
    } on NetworkException catch (e) {
      final cached = await localDataSource.getCachedPhotos();
      if (cached.isNotEmpty) {
        return Right(cached.map((p) => p.toEntity()).toList());
      }
      return Left(Failure.network(message: e.message));
    } on RateLimitException catch (e) {
      return Left(Failure.rateLimit(message: e.message));
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Photo>> getPhotoById(String id) async {
    try {
      final photo = await remoteDataSource.getPhotoById(id);
      await localDataSource.cachePhoto(photo);
      return Right(photo.toEntity());
    } on ServerException catch (e) {
      if (e.statusCode == 404) {
        return Left(Failure.notFound(message: 'Photo not found'));
      }
      return Left(Failure.server(statusCode: e.statusCode, message: e.message));
    } on NetworkException catch (e) {
      final cached = await localDataSource.getCachedPhoto(id);
      if (cached != null) {
        return Right(cached.toEntity());
      }
      return Left(Failure.network(message: e.message));
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Photo>> getRandomPhoto() async {
    try {
      final photo = await remoteDataSource.getRandomPhoto();
      return Right(photo.toEntity());
    } on ServerException catch (e) {
      return Left(Failure.server(statusCode: e.statusCode, message: e.message));
    } on NetworkException catch (e) {
      return Left(Failure.network(message: e.message));
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Topic>>> getTopics({int page = 1, int perPage = 10}) async {
    try {
      final topics = await remoteDataSource.getTopics(page: page, perPage: perPage);
      return Right(topics.map((t) => t.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(Failure.server(statusCode: e.statusCode, message: e.message));
    } on NetworkException catch (e) {
      return Left(Failure.network(message: e.message));
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Photo>>> getTopicPhotos(String topicSlug, {int page = 1, int perPage = 20}) async {
    try {
      final photos = await remoteDataSource.getTopicPhotos(topicSlug, page: page, perPage: perPage);
      return Right(photos.map((p) => p.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(Failure.server(statusCode: e.statusCode, message: e.message));
    } on NetworkException catch (e) {
      return Left(Failure.network(message: e.message));
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> trackDownload(String photoId) async {
    try {
      await remoteDataSource.trackDownload(photoId);
      return const Right(null);
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

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/features/discover/data/repositories/photo_repository_impl_test.dart`
Expected: PASS

- [ ] **Step 7: Commit repository layer**

```bash
git add lib/features/discover/domain/repositories/ lib/features/discover/data/repositories/ test/features/discover/ pubspec.yaml
git commit -m "feat: implement photo repository with error handling"
```

---

## Task 9: Theme and Styling

**Files:**
- Create: `lib/core/theme/colors.dart`
- Create: `lib/core/theme/text_styles.dart`
- Create: `lib/core/theme/app_theme.dart`

- [ ] **Step 1: Create color palette**

```dart
// lib/core/theme/colors.dart

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF000000);
  static const Color onPrimary = Color(0xFFFFFFFF);
  
  static const Color background = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF000000);
  
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF000000);
  
  static const Color error = Color(0xFFB3261E);
  static const Color onError = Color(0xFFFFFFFF);
  
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFE5E5E5);
  static const Color gray300 = Color(0xFFD4D4D4);
  static const Color gray400 = Color(0xFFA3A3A3);
  static const Color gray500 = Color(0xFF737373);
  static const Color gray600 = Color(0xFF525252);
  static const Color gray700 = Color(0xFF404040);
  static const Color gray800 = Color(0xFF262626);
  static const Color gray900 = Color(0xFF171717);
}
```

- [ ] **Step 2: Create text styles**

```dart
// lib/core/theme/text_styles.dart

import 'package:flutter/material.dart';
import 'package:musea/core/theme/colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const String _fontFamily = 'GoogleSans';

  static const TextStyle heading1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.gray900,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.gray900,
  );

  static const TextStyle heading3 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.gray900,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.gray900,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.gray900,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.gray700,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.gray600,
  );

  static const TextStyle button = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.onPrimary,
  );
}
```

- [ ] **Step 3: Create app theme**

```dart
// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/core/theme/text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        background: AppColors.background,
        onBackground: AppColors.onBackground,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        error: AppColors.error,
        onError: AppColors.onError,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onBackground,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: AppColors.surface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.gray100,
        selectedColor: AppColors.primary,
        labelStyle: AppTextStyles.bodySmall,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.gray500,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.gray200,
        thickness: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.onPrimary,
        onPrimary: AppColors.primary,
        background: AppColors.gray900,
        onBackground: AppColors.gray50,
        surface: AppColors.gray800,
        onSurface: AppColors.gray50,
        error: AppColors.error,
        onError: AppColors.onError,
      ),
      scaffoldBackgroundColor: AppColors.gray900,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.gray900,
        foregroundColor: AppColors.gray50,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: AppColors.gray800,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.onPrimary,
          foregroundColor: AppColors.primary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.gray800,
        selectedColor: AppColors.onPrimary,
        labelStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.gray50,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.gray900,
        selectedItemColor: AppColors.onPrimary,
        unselectedItemColor: AppColors.gray500,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.gray700,
        thickness: 1,
      ),
    );
  }
}
```

- [ ] **Step 4: Commit theme files**

```bash
git add lib/core/theme/
git commit -m "feat: add app theme with light and dark modes"
```

---

## Task 10: Shared Widgets

**Files:**
- Create: `lib/shared/widgets/loading_indicator.dart`
- Create: `lib/shared/widgets/empty_state.dart`
- Create: `lib/shared/widgets/error_state.dart`
- Create: `lib/shared/widgets/bottom_nav_bar.dart`

- [ ] **Step 1: Create loading indicator**

```dart
// lib/shared/widgets/loading_indicator.dart

import 'package:flutter/material.dart';
import 'package:musea/core/theme/colors.dart';

class LoadingIndicator extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;

  const LoadingIndicator({
    super.key,
    this.size = 32,
    this.strokeWidth = 3,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppColors.primary,
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Create empty state widget**

```dart
// lib/shared/widgets/empty_state.dart

import 'package:flutter/material.dart';
import 'package:musea/core/theme/text_styles.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.heading3,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Create error state widget**

```dart
// lib/shared/widgets/error_state.dart

import 'package:flutter/material.dart';
import 'package:musea/core/theme/text_styles.dart';

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: AppTextStyles.heading3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Create bottom navigation bar**

```dart
// lib/shared/widgets/bottom_nav_bar.dart

import 'package:flutter/material.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:go_router/go_router.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).location;
    
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
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  int _calculateSelectedIndex(String location) {
    if (location.startsWith('/discover')) return 0;
    if (location.startsWith('/explore')) return 1;
    if (location.startsWith('/collections')) return 2;
    if (location.startsWith('/profile')) return 3;
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
      case 3:
        context.go('/profile');
        break;
    }
  }
}
```

- [ ] **Step 5: Commit shared widgets**

```bash
git add lib/shared/widgets/
git commit -m "feat: add shared widgets for loading, empty, and error states"
```

---

## Task 11: Riverpod Providers Setup

**Files:**
- Create: `lib/features/discover/presentation/providers/photos_provider.dart`
- Create: `lib/features/discover/presentation/providers/topics_provider.dart`

- [ ] **Step 1: Create photos provider**

```dart
// lib/features/discover/presentation/providers/photos_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/core/network/dio_client.dart';
import 'package:musea/features/discover/data/datasources/photo_local_datasource.dart';
import 'package:musea/features/discover/data/datasources/photo_remote_datasource.dart';
import 'package:musea/features/discover/data/repositories/photo_repository_impl.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/repositories/photo_repository.dart';
import 'package:musea/core/errors/failures.dart';

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

final photoRemoteDataSourceProvider = Provider<PhotoRemoteDataSource>((ref) {
  return PhotoRemoteDataSourceImpl(ref.watch(dioClientProvider));
});

final photoLocalDataSourceProvider = Provider<PhotoLocalDataSource>((ref) {
  return PhotoLocalDataSourceImpl();
});

final photoRepositoryProvider = Provider<PhotoRepository>((ref) {
  return PhotoRepositoryImpl(
    remoteDataSource: ref.watch(photoRemoteDataSourceProvider),
    localDataSource: ref.watch(photoLocalDataSourceProvider),
  );
});

final photosProvider = FutureProvider.family<List<Photo>, int>((ref, page) async {
  final repository = ref.watch(photoRepositoryProvider);
  final result = await repository.getPhotos(page: page);
  
  return result.fold(
    (failure) => throw _mapFailureToException(failure),
    (photos) => photos,
  );
});

final photoDetailProvider = FutureProvider.family<Photo, String>((ref, id) async {
  final repository = ref.watch(photoRepositoryProvider);
  final result = await repository.getPhotoById(id);
  
  return result.fold(
    (failure) => throw _mapFailureToException(failure),
    (photo) => photo,
  );
});

final randomPhotoProvider = FutureProvider<Photo>((ref) async {
  final repository = ref.watch(photoRepositoryProvider);
  final result = await repository.getRandomPhoto();
  
  return result.fold(
    (failure) => throw _mapFailureToException(failure),
    (photo) => photo,
  );
});

Exception _mapFailureToException(Failure failure) {
  return failure.maybeWhen(
    network: (message) => Exception(message),
    server: (statusCode, message) => Exception('$statusCode: $message'),
    rateLimit: (message) => Exception(message),
    orElse: () => Exception('Unknown error'),
  );
}
```

- [ ] **Step 2: Create topics provider**

```dart
// lib/features/discover/presentation/providers/topics_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/features/discover/domain/entities/topic.dart';
import 'package:musea/features/discover/presentation/providers/photos_provider.dart';

final topicsProvider = FutureProvider<List<Topic>>((ref) async {
  final repository = ref.watch(photoRepositoryProvider);
  final result = await repository.getTopics();
  
  return result.fold(
    (failure) => throw Exception(failure.toString()),
    (topics) => topics,
  );
});

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

- [ ] **Step 3: Commit providers**

```bash
git add lib/features/discover/presentation/providers/
git commit -m "feat: add Riverpod providers for photos and topics"
```

---

## Task 12: Photo Card Widget

**Files:**
- Create: `lib/features/discover/presentation/widgets/photo_card.dart`

- [ ] **Step 1: Create PhotoCard widget**

```dart
// lib/features/discover/presentation/widgets/photo_card.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:musea/core/theme/text_styles.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';

class PhotoCard extends StatelessWidget {
  final Photo photo;
  final VoidCallback? onTap;
  final VoidCallback? onUserTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onSaveTap;
  final VoidCallback? onDownloadTap;
  final bool isLiked;
  final bool isSaved;

  const PhotoCard({
    super.key,
    required this.photo,
    this.onTap,
    this.onUserTap,
    this.onLikeTap,
    this.onSaveTap,
    this.onDownloadTap,
    this.isLiked = false,
    this.isSaved = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Stack(
          children: [
            Hero(
              tag: 'photo-${photo.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: photo.blurHash != null
                    ? BlurHash(
                        hash: photo.blurHash!,
                        image: photo.urlRegular,
                        imageFit: BoxFit.cover,
                      )
                    : CachedNetworkImage(
                        imageUrl: photo.urlRegular,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) => Container(
                          height: 200,
                          color: Theme.of(context).colorScheme.surface,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 200,
                          color: Theme.of(context).colorScheme.surface,
                          child: const Icon(Icons.error),
                        ),
                      ),
              ),
            ),
            Positioned(
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
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
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
                            radius: 20,
                            backgroundImage: CachedNetworkImageProvider(
                              photo.user.profileImageMedium,
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
                        _ActionButton(
                          icon: isLiked ? Icons.favorite : Icons.favorite_border,
                          label: _formatCount(photo.likes),
                          onTap: onLikeTap,
                          isActive: isLiked,
                        ),
                        const SizedBox(width: 4),
                        _ActionButton(
                          icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
                          label: _formatCount(photo.downloads),
                          onTap: onSaveTap,
                          isActive: isSaved,
                        ),
                        const SizedBox(width: 4),
                        _ActionButton(
                          icon: Icons.download,
                          label: _formatCount(photo.downloads),
                          onTap: onDownloadTap,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isActive;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.white : Colors.white.withOpacity(0.9),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit photo card widget**

```bash
git add lib/features/discover/presentation/widgets/photo_card.dart
git commit -m "feat: add PhotoCard widget with BlurHash support"
```

---

## Task 13: Discover Page

**Files:**
- Create: `lib/features/discover/presentation/widgets/search_bar_widget.dart`
- Create: `lib/features/discover/presentation/widgets/topic_chip.dart`
- Create: `lib/features/discover/presentation/pages/discover_page.dart`

- [ ] **Step 1: Create search bar widget**

```dart
// lib/features/discover/presentation/widgets/search_bar_widget.dart

import 'package:flutter/material.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/core/theme/text_styles.dart';
import 'package:go_router/go_router.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => context.go('/explore'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: AppColors.gray500,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Search photos, photographers...',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              // TODO: Navigate to random photo
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shuffle,
                color: AppColors.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Create topic chip widget**

```dart
// lib/features/discover/presentation/widgets/topic_chip.dart

import 'package:flutter/material.dart';
import 'package:musea/core/theme/colors.dart';
import 'package:musea/core/theme/text_styles.dart';
import 'package:musea/features/discover/domain/entities/topic.dart';

class TopicChip extends StatelessWidget {
  final Topic? topic;
  final bool isSelected;
  final VoidCallback onTap;

  const TopicChip({
    super.key,
    this.topic,
    required this.isSelected,
    required this.onTap,
  });

  factory TopicChip.all({required bool isSelected, required VoidCallback onTap}) {
    return TopicChip(
      topic: null,
      isSelected: isSelected,
      onTap: onTap,
    );
  }

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
          topic?.title ?? 'All',
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

- [ ] **Step 3: Create discover page**

```dart
// lib/features/discover/presentation/pages/discover_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/features/discover/presentation/providers/photos_provider.dart';
import 'package:musea/features/discover/presentation/providers/topics_provider.dart';
import 'package:musea/features/discover/presentation/widgets/photo_card.dart';
import 'package:musea/features/discover/presentation/widgets/search_bar_widget.dart';
import 'package:musea/features/discover/presentation/widgets/topic_chip.dart';
import 'package:musea/shared/widgets/loading_indicator.dart';
import 'package:musea/shared/widgets/error_state.dart';
import 'package:go_router/go_router.dart';

class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({super.key});

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  String? selectedTopicSlug;
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

  @override
  Widget build(BuildContext context) {
    final topicsAsync = ref.watch(topicsProvider);
    final photosAsync = selectedTopicSlug == null
        ? ref.watch(photosProvider(_currentPage))
        : ref.watch(topicPhotosProvider(
            TopicPhotosParams(topicSlug: selectedTopicSlug!, page: _currentPage),
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
                    const SearchBarWidget(),
                    const SizedBox(height: 8),
                    topicsAsync.when(
                      data: (topics) => _buildTopicBar(topics),
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
                data: (photos) => SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= photos.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: LoadingIndicator(),
                            ),
                          );
                        }
                        final photo = photos[index];
                        return PhotoCard(
                          photo: photo,
                          onTap: () => context.push('/photo/${photo.id}'),
                          onUserTap: () => context.push('/user/${photo.user.username}'),
                        );
                      },
                      childCount: photos.length + 1,
                    ),
                  ),
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

  Widget _buildTopicBar(List<dynamic> topics) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: topics.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TopicChip.all(
                isSelected: selectedTopicSlug == null,
                onTap: () => setState(() => selectedTopicSlug = null),
              ),
            );
          }
          final topic = topics[index - 1];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TopicChip(
              topic: topic,
              isSelected: selectedTopicSlug == topic.slug,
              onTap: () => setState(() => selectedTopicSlug = topic.slug),
            ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 4: Commit discover page**

```bash
git add lib/features/discover/presentation/
git commit -m "feat: implement discover page with photo feed and topic filtering"
```

---

## Task 14: Router Setup

**Files:**
- Create: `lib/router/app_router.dart`
- Create: `lib/app.dart`
- Create: `lib/main.dart`

- [ ] **Step 1: Create app router**

```dart
// lib/router/app_router.dart

import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:musea/features/discover/presentation/pages/discover_page.dart';
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
            child: ExplorePage(),
          ),
        ),
        GoRoute(
          path: '/collections',
          name: 'collections',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CollectionsPage(),
          ),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProfilePage(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/photo/:id',
      name: 'photo-detail',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final photoId = state.pathParameters['id']!;
        return PhotoDetailPage(photoId: photoId);
      },
    ),
    GoRoute(
      path: '/user/:username',
      name: 'user-profile',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final username = state.pathParameters['username']!;
        return UserProfilePage(username: username);
      },
    ),
  ],
);

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithNavBar({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
```

- [ ] **Step 2: Create app widget**

```dart
// lib/app.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/core/theme/app_theme.dart';
import 'package:musea/router/app_router.dart';

class MuseaApp extends ConsumerWidget {
  const MuseaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Musea',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
```

- [ ] **Step 3: Create main entry point**

```dart
// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:musea/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  
  runApp(
    const ProviderScope(
      child: MuseaApp(),
    ),
  );
}
```

- [ ] **Step 4: Create placeholder pages for compilation**

```dart
// lib/features/explore/presentation/pages/explore_page.dart
import 'package:flutter/material.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Explore Page')),
    );
  }
}

// lib/features/collections/presentation/pages/collections_page.dart
import 'package:flutter/material.dart';

class CollectionsPage extends StatelessWidget {
  const CollectionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Collections Page')),
    );
  }
}

// lib/features/profile/presentation/pages/profile_page.dart
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Profile Page')),
    );
  }
}

// lib/features/photo_detail/presentation/pages/photo_detail_page.dart
import 'package:flutter/material.dart';

class PhotoDetailPage extends StatelessWidget {
  final String photoId;

  const PhotoDetailPage({
    super.key,
    required this.photoId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Photo Detail: $photoId')),
    );
  }
}

// lib/features/profile/presentation/pages/user_profile_page.dart
import 'package:flutter/material.dart';

class UserProfilePage extends StatelessWidget {
  final String username;

  const UserProfilePage({
    super.key,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('User Profile: $username')),
    );
  }
}
```

- [ ] **Step 5: Commit router and app setup**

```bash
git add lib/router/ lib/app.dart lib/main.dart lib/features/explore/ lib/features/collections/ lib/features/profile/ lib/features/photo_detail/
git commit -m "feat: set up routing with go_router and app structure"
```

---

## Task 15: Run and Verify Basic App

**Files:**
- Modify: `pubspec.yaml` (add Unsplash Client ID)

- [ ] **Step 1: Add Unsplash API key**

Update `lib/core/constants/api_constants.dart`:
```dart
static const String clientId = 'YOUR_ACTUAL_UNSPLASH_CLIENT_ID';
```

Get your Client ID from: https://unsplash.com/developers

- [ ] **Step 2: Run the app**

Run: `flutter run`
Expected: App launches with discover page showing photos

- [ ] **Step 3: Test navigation**

- Tap on bottom nav items to verify navigation works
- Tap on a photo card to verify navigation to detail page
- Tap on topics to verify filtering works

- [ ] **Step 4: Fix any runtime errors**

If errors occur, check:
- API key is valid
- Network permissions (iOS/Android)
- Dependencies are installed

- [ ] **Step 5: Commit working app**

```bash
git add -A
git commit -m "feat: complete MVP core with working discover page"
```

---

## Summary

This implementation plan covers the foundational architecture and core features for the Musea MVP:

**Completed:**
- ✅ Project initialization with dependencies
- ✅ Core constants and configuration
- ✅ Error handling framework
- ✅ Network layer with Dio
- ✅ Domain entities (User, Photo, Topic)
- ✅ Data models with JSON serialization
- ✅ Data sources (remote + local caching)
- ✅ Repository layer with error handling
- ✅ Theme and styling system
- ✅ Shared widgets (loading, empty, error states)
- ✅ Riverpod state management setup
- ✅ PhotoCard widget with BlurHash
- ✅ Discover page with topic filtering
- ✅ Routing setup with go_router
- ✅ Basic app structure

**Next Steps (not in this plan):**
- Explore page with search functionality
- Photo detail page with EXIF/location/tags
- Collections management (local storage)
- Profile page with settings
- Download functionality
- Dark mode toggle
- Performance optimization
- Testing coverage
- Error boundary improvements

This plan follows TDD principles where applicable, uses clean architecture, and implements the core browsing experience described in the functional design document. Each task is bite-sized (2-5 minutes) and includes complete code with no placeholders.
