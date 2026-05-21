import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/core/network/providers.dart';
import 'package:musea/features/discover/data/datasources/photo_local_datasource.dart';
import 'package:musea/features/discover/data/datasources/photo_remote_datasource.dart';
import 'package:musea/features/discover/data/datasources/topic_local_datasource.dart';
import 'package:musea/features/discover/data/repositories/photo_repository_impl.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/repositories/photo_repository.dart';
import 'package:musea/core/errors/failures.dart';

const discoverAllFeedKey = '__all__';

final photoRemoteDataSourceProvider = Provider<PhotoRemoteDataSource>((ref) {
  return PhotoRemoteDataSourceImpl(ref.watch(dioClientProvider));
});

final photoLocalDataSourceProvider = Provider<PhotoLocalDataSource>((ref) {
  return PhotoLocalDataSourceImpl();
});

final topicLocalDataSourceProvider = Provider<TopicLocalDataSource>((ref) {
  return TopicLocalDataSourceImpl();
});

final photoRepositoryProvider = Provider<PhotoRepository>((ref) {
  return PhotoRepositoryImpl(
    remoteDataSource: ref.watch(photoRemoteDataSourceProvider),
    localDataSource: ref.watch(photoLocalDataSourceProvider),
    topicLocalDataSource: ref.watch(topicLocalDataSourceProvider),
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

final discoverFeedProvider = StateNotifierProvider.family<
    DiscoverFeedController, DiscoverFeedState, String?>((ref, topicSlug) {
  return DiscoverFeedController(ref, topicSlug: topicSlug);
});

class DiscoverFeedState {
  const DiscoverFeedState({
    this.photos = const [],
    this.page = 0,
    this.isInitialLoading = false,
    this.isLoadingMore = false,
    this.hasMorePages = true,
    this.error,
    this.initialized = false,
  });

  final List<Photo> photos;
  final int page;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool hasMorePages;
  final Object? error;
  final bool initialized;

  DiscoverFeedState copyWith({
    List<Photo>? photos,
    int? page,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? hasMorePages,
    Object? error = _unset,
    bool? initialized,
  }) {
    return DiscoverFeedState(
      photos: photos ?? this.photos,
      page: page ?? this.page,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMorePages: hasMorePages ?? this.hasMorePages,
      error: identical(error, _unset) ? this.error : error,
      initialized: initialized ?? this.initialized,
    );
  }
}

class DiscoverFeedController extends StateNotifier<DiscoverFeedState> {
  DiscoverFeedController(this.ref, {required this.topicSlug})
      : super(const DiscoverFeedState()) {
    loadInitial();
  }

  final Ref ref;
  final String? topicSlug;

  Future<void> loadInitial() async {
    if (state.initialized || state.isInitialLoading) return;

    state = state.copyWith(
      isInitialLoading: true,
      isLoadingMore: false,
      error: null,
    );

    final photosResult = await _fetchPage(1);
    state = DiscoverFeedState(
      photos: photosResult,
      page: 1,
      isInitialLoading: false,
      isLoadingMore: false,
      hasMorePages: photosResult.isNotEmpty,
      error: null,
      initialized: true,
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(
      isInitialLoading: true,
      isLoadingMore: false,
      hasMorePages: true,
      error: null,
      initialized: false,
    );

    try {
      final photosResult = await _fetchPage(1);
      state = DiscoverFeedState(
        photos: photosResult,
        page: 1,
        isInitialLoading: false,
        isLoadingMore: false,
        hasMorePages: photosResult.isNotEmpty,
        error: null,
        initialized: true,
      );
    } catch (error) {
      state = DiscoverFeedState(
        photos: const [],
        page: 0,
        isInitialLoading: false,
        isLoadingMore: false,
        hasMorePages: true,
        error: error,
        initialized: true,
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.initialized ||
        state.isInitialLoading ||
        state.isLoadingMore ||
        !state.hasMorePages) {
      return;
    }

    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true, error: null);

    try {
      final nextPhotos = await _fetchPage(nextPage);
      state = state.copyWith(
        photos: [...state.photos, ...nextPhotos],
        page: nextPage,
        isLoadingMore: false,
        hasMorePages: nextPhotos.isNotEmpty,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingMore: false,
        hasMorePages: false,
        error: error,
      );
    }
  }

  Future<List<Photo>> _fetchPage(int page) async {
    final repository = ref.read(photoRepositoryProvider);
    final result = topicSlug == null
        ? await repository.getPhotos(page: page)
        : await repository.getTopicPhotos(topicSlug!, page: page);

    return result.fold(
      (failure) => throw _mapFailureToException(failure),
      (photos) => photos,
    );
  }
}

const _unset = Object();

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
