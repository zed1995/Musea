import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/collections/presentation/providers/collections_provider.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/features/discover/presentation/providers/photos_provider.dart';
import 'package:musea/features/profile/presentation/providers/profile_provider.dart';

class PaginatedState<T> {
  const PaginatedState({
    this.items = const [],
    this.page = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMorePages = true,
    this.error,
  });

  final List<T> items;
  final int page;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMorePages;
  final Object? error;

  PaginatedState<T> copyWith({
    List<T>? items,
    int? page,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMorePages,
    Object? error = _unset,
  }) {
    return PaginatedState<T>(
      items: items ?? this.items,
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMorePages: hasMorePages ?? this.hasMorePages,
      error: identical(error, _unset) ? this.error : error,
    );
  }
}

const _unset = Object();

class SearchPhotosController extends StateNotifier<PaginatedState<Photo>> {
  SearchPhotosController(this.ref) : super(const PaginatedState<Photo>());

  final Ref ref;
  String _query = '';
  String _orderBy = 'relevant';
  String? _color;
  String? _orientation;
  String _contentFilter = 'high';

  Future<void> search(
    String query, {
    String orderBy = 'relevant',
    String? color,
    String? orientation,
    String contentFilter = 'high',
  }) async {
    _query = query;
    _orderBy = orderBy;
    _color = color;
    _orientation = orientation;
    _contentFilter = contentFilter;

    state = const PaginatedState<Photo>(isLoading: true);

    try {
      final repository = ref.read(photoRepositoryProvider);
      final result = await repository.searchPhotos(
        query,
        page: 1,
        perPage: 20,
        orderBy: orderBy,
        color: color,
        orientation: orientation,
        contentFilter: contentFilter,
      );

      result.fold(
        (failure) => state = PaginatedState<Photo>(
          error: failure,
          hasMorePages: false,
        ),
        (searchResult) => state = PaginatedState<Photo>(
          items: searchResult.results,
          page: 1,
          hasMorePages: 1 < searchResult.totalPages,
        ),
      );
    } catch (e) {
      state = PaginatedState<Photo>(error: e, hasMorePages: false);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMorePages) return;
    if (_query.isEmpty) return;

    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true, error: null);

    try {
      final repository = ref.read(photoRepositoryProvider);
      final result = await repository.searchPhotos(
        _query,
        page: nextPage,
        perPage: 20,
        orderBy: _orderBy,
        color: _color,
        orientation: _orientation,
        contentFilter: _contentFilter,
      );

      result.fold(
        (failure) => state = state.copyWith(
          isLoadingMore: false,
          hasMorePages: false,
          error: failure,
        ),
        (searchResult) => state = state.copyWith(
          items: [...state.items, ...searchResult.results],
          page: nextPage,
          isLoadingMore: false,
          hasMorePages: nextPage < searchResult.totalPages,
        ),
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, hasMorePages: false, error: e);
    }
  }
}

class SearchCollectionsController
    extends StateNotifier<PaginatedState<Collection>> {
  SearchCollectionsController(this.ref)
      : super(const PaginatedState<Collection>());

  final Ref ref;
  String _query = '';

  Future<void> search(String query) async {
    _query = query;
    state = const PaginatedState<Collection>(isLoading: true);

    try {
      final repository = ref.read(collectionRepositoryProvider);
      final result = await repository.searchCollections(query, page: 1, perPage: 20);

      result.fold(
        (failure) => state = PaginatedState<Collection>(
          error: failure,
          hasMorePages: false,
        ),
        (searchResult) => state = PaginatedState<Collection>(
          items: searchResult.results,
          page: 1,
          hasMorePages: 1 < searchResult.totalPages,
        ),
      );
    } catch (e) {
      state = PaginatedState<Collection>(error: e, hasMorePages: false);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMorePages) return;
    if (_query.isEmpty) return;

    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true, error: null);

    try {
      final repository = ref.read(collectionRepositoryProvider);
      final result = await repository.searchCollections(
        _query,
        page: nextPage,
        perPage: 20,
      );

      result.fold(
        (failure) => state = state.copyWith(
          isLoadingMore: false,
          hasMorePages: false,
          error: failure,
        ),
        (searchResult) => state = state.copyWith(
          items: [...state.items, ...searchResult.results],
          page: nextPage,
          isLoadingMore: false,
          hasMorePages: nextPage < searchResult.totalPages,
        ),
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, hasMorePages: false, error: e);
    }
  }
}

class SearchUsersController extends StateNotifier<PaginatedState<User>> {
  SearchUsersController(this.ref) : super(const PaginatedState<User>());

  final Ref ref;
  String _query = '';

  Future<void> search(String query) async {
    _query = query;
    state = const PaginatedState<User>(isLoading: true);

    try {
      final repository = ref.read(profileRepositoryProvider);
      final result = await repository.searchUsers(query, page: 1, perPage: 20);

      result.fold(
        (failure) => state = PaginatedState<User>(
          error: failure,
          hasMorePages: false,
        ),
        (searchResult) => state = PaginatedState<User>(
          items: searchResult.results,
          page: 1,
          hasMorePages: 1 < searchResult.totalPages,
        ),
      );
    } catch (e) {
      state = PaginatedState<User>(error: e, hasMorePages: false);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMorePages) return;
    if (_query.isEmpty) return;

    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true, error: null);

    try {
      final repository = ref.read(profileRepositoryProvider);
      final result = await repository.searchUsers(
        _query,
        page: nextPage,
        perPage: 20,
      );

      result.fold(
        (failure) => state = state.copyWith(
          isLoadingMore: false,
          hasMorePages: false,
          error: failure,
        ),
        (searchResult) => state = state.copyWith(
          items: [...state.items, ...searchResult.results],
          page: nextPage,
          isLoadingMore: false,
          hasMorePages: nextPage < searchResult.totalPages,
        ),
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, hasMorePages: false, error: e);
    }
  }
}

final searchPhotosControllerProvider =
    StateNotifierProvider<SearchPhotosController, PaginatedState<Photo>>((ref) {
  return SearchPhotosController(ref);
});

final searchCollectionsControllerProvider = StateNotifierProvider<
    SearchCollectionsController, PaginatedState<Collection>>((ref) {
  return SearchCollectionsController(ref);
});

final searchUsersControllerProvider =
    StateNotifierProvider<SearchUsersController, PaginatedState<User>>((ref) {
  return SearchUsersController(ref);
});
