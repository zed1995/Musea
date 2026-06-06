import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musea/app.dart';
import 'package:musea/core/services/download_notifier.dart';
import 'package:musea/core/services/providers.dart';
import 'package:musea/features/auth/presentation/providers/auth_provider.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/collections/presentation/pages/collection_detail_page.dart';
import 'package:musea/features/collections/presentation/providers/collections_provider.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/topic.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/features/discover/domain/repositories/photo_repository.dart';
import 'package:musea/features/discover/presentation/providers/photos_provider.dart';
import 'package:musea/features/discover/presentation/providers/topics_provider.dart';
import 'package:musea/features/photo_detail/presentation/pages/photo_detail_page.dart';
import 'package:musea/features/photo_detail/presentation/pages/photo_viewer_page.dart';
import 'package:musea/features/profile/presentation/providers/profile_provider.dart';
import 'package:musea/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:musea/features/settings/presentation/providers/settings_provider.dart';
import 'package:musea/router/app_router.dart';
import 'package:musea/router/detail_route_extras.dart';

class TestTopicListNotifier extends TopicListNotifier {
  TestTopicListNotifier(this.initialTopics);

  final List<Topic> initialTopics;

  @override
  List<Topic> build() => initialTopics;
}

class MockPhotoRepository extends Mock implements PhotoRepository {}

class _FakeSettingsLocalDataSource implements SettingsLocalDataSource {
  StoredSettings value = const StoredSettings(
    language: AppLanguage.system,
    downloadOverWifiOnly: true,
  );

  @override
  Future<StoredSettings> readSettings() async => value;

  @override
  Future<void> saveSettings(StoredSettings settings) async {
    value = settings;
  }
}

void main() {
  late MockPhotoRepository mockPhotoRepository;

  const user = User(
    id: 'user-1',
    username: 'forest',
    name: 'Forest Archive',
    bio: 'Shoots outdoors',
    location: 'Portland',
    profileImageSmall: 'https://example.com/small.jpg',
    profileImageMedium: 'https://example.com/medium.jpg',
    profileImageLarge: 'https://example.com/large.jpg',
    totalPhotos: 12,
    totalLikes: 44,
    totalCollections: 3,
  );

  final photo = Photo(
    id: 'photo-1',
    createdAt: DateTime(2024, 1, 1),
    width: 1200,
    height: 1600,
    color: '#AABBCC',
    description: 'Forest canopy',
    altDescription: 'Green trees',
    urlRaw: 'https://example.com/raw.jpg',
    urlFull: 'https://example.com/full.jpg',
    urlRegular: 'https://example.com/regular.jpg',
    urlSmall: 'https://example.com/small.jpg',
    urlThumb: 'https://example.com/thumb.jpg',
    likes: 80,
    downloads: 20,
    user: user,
  );

  const collection = Collection(
    id: 'collection-1',
    title: 'Forest Archive',
    description: 'Curated woodland work',
    totalPhotos: 12,
    user: user,
  );

  setUp(() {
    appRouter.go('/discover');
    mockPhotoRepository = MockPhotoRepository();

    when(() => mockPhotoRepository.getPhotos(
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        )).thenAnswer((_) async => Right(<Photo>[photo]));
    when(() => mockPhotoRepository.getPhotoById(any()))
        .thenAnswer((_) async => Right(photo));
    when(() => mockPhotoRepository.getRandomPhoto())
        .thenAnswer((_) async => Right(photo));
    when(() => mockPhotoRepository.getTopics(
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        )).thenAnswer((_) async => const Right(<Topic>[]));
    when(() => mockPhotoRepository.getTopicPhotos(
          any(),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        )).thenAnswer((_) async => Right(<Photo>[photo]));
    when(
      () => mockPhotoRepository.searchPhotos(
        any(),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
        orderBy: any(named: 'orderBy'),
        color: any(named: 'color'),
        orientation: any(named: 'orientation'),
        contentFilter: any(named: 'contentFilter'),
      ),
    ).thenThrow(UnimplementedError());
    when(() => mockPhotoRepository.trackDownload(any()))
        .thenAnswer((_) async => const Right(null));
  });

  testWidgets(
      'home keeps discover route and bottom nav shows discover collections and mine',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authLinkServiceProvider.overrideWithValue(_FakeAuthLinkService()),
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
          settingsLocalDataSourceProvider
              .overrideWithValue(_FakeSettingsLocalDataSource()),
          photoRepositoryProvider.overrideWithValue(mockPhotoRepository),
          photosProvider(1).overrideWith((ref) => <Photo>[photo]),
          topicsProvider.overrideWith(() => TestTopicListNotifier(<Topic>[])),
          collectionsProvider(1).overrideWith((ref) => <Collection>[]),
        ],
        child: const MuseaApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('Collections'), findsOneWidget);
    expect(find.text('Mine'), findsOneWidget);
    expect(find.text('Search photos, collections, users...'), findsOneWidget);
  });

  testWidgets('tapping the home search entry opens the full search page',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authLinkServiceProvider.overrideWithValue(_FakeAuthLinkService()),
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
          settingsLocalDataSourceProvider
              .overrideWithValue(_FakeSettingsLocalDataSource()),
          photoRepositoryProvider.overrideWithValue(mockPhotoRepository),
          photosProvider(1).overrideWith((ref) => <Photo>[photo]),
          topicsProvider.overrideWith(() => TestTopicListNotifier(<Topic>[])),
          collectionsProvider(1).overrideWith((ref) => <Collection>[]),
        ],
        child: const MuseaApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Search photos, collections, users...'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Photos'), findsWidgets);
    expect(find.text('Users'), findsWidgets);
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
  });

  testWidgets('router forwards photo and collection extras into detail pages',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authLinkServiceProvider.overrideWithValue(_FakeAuthLinkService()),
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
          settingsLocalDataSourceProvider
              .overrideWithValue(_FakeSettingsLocalDataSource()),
          photoRepositoryProvider.overrideWithValue(mockPhotoRepository),
          photosProvider(1).overrideWith((ref) => <Photo>[photo]),
          photoDetailProvider('photo-1').overrideWith((ref) => photo),
          topicsProvider.overrideWith(() => TestTopicListNotifier(<Topic>[])),
          collectionsProvider(1).overrideWith((ref) => <Collection>[]),
          userProfileProvider('forest').overrideWith((ref) => user),
          userPhotosProvider('forest').overrideWith((ref) => <Photo>[photo]),
          userCollectionsProvider('forest')
              .overrideWith((ref) => <Collection>[collection]),
          userLikesProvider('forest').overrideWith((ref) => <Photo>[]),
          collectionDetailProvider('collection-1')
              .overrideWith((ref) => collection),
          collectionPhotosProvider('collection-1')
              .overrideWith((ref) => <Photo>[]),
        ],
        child: const MuseaApp(),
      ),
    );

    final appContext =
        tester.element(find.text('Search photos, collections, users...'));
    GoRouter.of(appContext).go(
      '/photo/${photo.id}',
      extra: PhotoDetailExtra(photo: photo),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final photoPage = tester.widget<PhotoDetailPage>(
      find.byType(PhotoDetailPage),
    );
    expect(photoPage.photoId, photo.id);
    expect(photoPage.initialPhoto, same(photo));
    expect(find.text('Forest Archive'), findsWidgets);

    GoRouter.of(appContext).go(
      '/collection/${collection.id}',
      extra: const CollectionDetailExtra(collection: collection),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final collectionPage = tester.widget<CollectionDetailPage>(
      find.byType(CollectionDetailPage),
    );
    expect(collectionPage.collectionId, collection.id);
    expect(collectionPage.initialCollection, same(collection));
    expect(find.text('Forest Archive'), findsWidgets);
  });

  testWidgets('router forwards photo extra into photo viewer page',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authLinkServiceProvider.overrideWithValue(_FakeAuthLinkService()),
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
          settingsLocalDataSourceProvider
              .overrideWithValue(_FakeSettingsLocalDataSource()),
          photoRepositoryProvider.overrideWithValue(mockPhotoRepository),
          photosProvider(1).overrideWith((ref) => <Photo>[photo]),
          photoDetailProvider('photo-1').overrideWith((ref) => photo),
          topicsProvider.overrideWith(() => TestTopicListNotifier(<Topic>[])),
          collectionsProvider(1).overrideWith((ref) => <Collection>[]),
          userProfileProvider('forest').overrideWith((ref) => user),
          userPhotosProvider('forest').overrideWith((ref) => <Photo>[photo]),
          userCollectionsProvider('forest')
              .overrideWith((ref) => <Collection>[collection]),
          userLikesProvider('forest').overrideWith((ref) => <Photo>[]),
        ],
        child: const MuseaApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));

    final appContext = tester.element(find.byType(Scaffold).first);
    GoRouter.of(appContext).go(
      '/photo/${photo.id}/viewer',
      extra: PhotoViewerExtra(photo: photo),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final viewerPage = tester.widget<PhotoViewerPage>(
      find.byType(PhotoViewerPage),
    );
    expect(viewerPage.initialPhoto, same(photo));
    expect(viewerPage.photoId, photo.id);
  });

  testWidgets('router opens settings page from top-level path', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authLinkServiceProvider.overrideWithValue(_FakeAuthLinkService()),
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
          photoRepositoryProvider.overrideWithValue(mockPhotoRepository),
          settingsLocalDataSourceProvider
              .overrideWithValue(_FakeSettingsLocalDataSource()),
          appVersionProvider.overrideWith((ref) async => 'v1.0.0'),
          cacheBytesProvider.overrideWith((ref) async => 0),
          photosProvider(1).overrideWith((ref) => <Photo>[photo]),
          topicsProvider.overrideWith(() => TestTopicListNotifier(<Topic>[])),
          collectionsProvider(1).overrideWith((ref) => <Collection>[]),
          downloadNotifierProvider
              .overrideWith((ref) => DownloadNotifier.noop()),
        ],
        child: const MuseaApp(),
      ),
    );

    final appContext = tester.element(find.byType(Scaffold).first);
    GoRouter.of(appContext).go('/settings');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('saved chinese language localizes the settings route',
      (tester) async {
    final dataSource = _FakeSettingsLocalDataSource()
      ..value = const StoredSettings(
        language: AppLanguage.simplifiedChinese,
        downloadOverWifiOnly: true,
      );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authLinkServiceProvider.overrideWithValue(_FakeAuthLinkService()),
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
          photoRepositoryProvider.overrideWithValue(mockPhotoRepository),
          settingsLocalDataSourceProvider.overrideWithValue(dataSource),
          appVersionProvider.overrideWith((ref) async => 'v1.0.0'),
          cacheBytesProvider.overrideWith((ref) async => 0),
          photosProvider(1).overrideWith((ref) => <Photo>[photo]),
          topicsProvider.overrideWith(() => TestTopicListNotifier(<Topic>[])),
          collectionsProvider(1).overrideWith((ref) => <Collection>[]),
          downloadNotifierProvider
              .overrideWith((ref) => DownloadNotifier.noop()),
        ],
        child: const MuseaApp(),
      ),
    );

    final appContext = tester.element(find.byType(Scaffold).first);
    GoRouter.of(appContext).go('/settings');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('设置'), findsOneWidget);
  });

  testWidgets('saved chinese language localizes home shell labels',
      (tester) async {
    final dataSource = _FakeSettingsLocalDataSource()
      ..value = const StoredSettings(
        language: AppLanguage.simplifiedChinese,
        downloadOverWifiOnly: true,
      );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authLinkServiceProvider.overrideWithValue(_FakeAuthLinkService()),
          authRedirectUriProvider.overrideWithValue(
            Uri.parse('musea://auth/callback'),
          ),
          settingsLocalDataSourceProvider.overrideWithValue(dataSource),
          photoRepositoryProvider.overrideWithValue(mockPhotoRepository),
          photosProvider(1).overrideWith((ref) => <Photo>[photo]),
          topicsProvider.overrideWith(() => TestTopicListNotifier(<Topic>[])),
          collectionsProvider(1).overrideWith((ref) => <Collection>[]),
        ],
        child: const MuseaApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('发现'), findsOneWidget);
    expect(find.text('合集'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
    expect(find.text('搜索图片、合集、用户...'), findsOneWidget);
  });
}

class _FakeAuthLinkService implements AuthLinkService {
  @override
  Future<Uri?> getInitialLink() async => null;

  @override
  Stream<Uri> get uriStream => const Stream<Uri>.empty();
}
