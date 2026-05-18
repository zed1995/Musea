import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/features/collections/presentation/providers/collections_provider.dart';
import 'package:musea/features/discover/presentation/providers/photos_provider.dart';
import 'package:musea/features/profile/presentation/providers/profile_provider.dart';
import 'package:musea/features/search/domain/entities/search_result.dart';

class PhotoSearchParams {
  const PhotoSearchParams({
    required this.query,
    this.page = 1,
    this.perPage = 20,
    this.orderBy = 'relevant',
    this.color,
    this.orientation,
    this.contentFilter = 'high',
  });

  final String query;
  final int page;
  final int perPage;
  final String orderBy;
  final String? color;
  final String? orientation;
  final String contentFilter;

  @override
  bool operator ==(Object other) {
    return other is PhotoSearchParams &&
        other.query == query &&
        other.page == page &&
        other.perPage == perPage &&
        other.orderBy == orderBy &&
        other.color == color &&
        other.orientation == orientation &&
        other.contentFilter == contentFilter;
  }

  @override
  int get hashCode => Object.hash(
        query,
        page,
        perPage,
        orderBy,
        color,
        orientation,
        contentFilter,
      );
}

class CollectionSearchParams {
  const CollectionSearchParams({
    required this.query,
    this.page = 1,
    this.perPage = 20,
  });

  final String query;
  final int page;
  final int perPage;

  @override
  bool operator ==(Object other) {
    return other is CollectionSearchParams &&
        other.query == query &&
        other.page == page &&
        other.perPage == perPage;
  }

  @override
  int get hashCode => Object.hash(query, page, perPage);
}

class UserSearchParams {
  const UserSearchParams({
    required this.query,
    this.page = 1,
    this.perPage = 20,
  });

  final String query;
  final int page;
  final int perPage;

  @override
  bool operator ==(Object other) {
    return other is UserSearchParams &&
        other.query == query &&
        other.page == page &&
        other.perPage == perPage;
  }

  @override
  int get hashCode => Object.hash(query, page, perPage);
}

final photoSearchProvider =
    FutureProvider.family<SearchPhotosResult, PhotoSearchParams>(
        (ref, params) async {
  final query = params.query.trim();
  if (query.isEmpty) {
    return const SearchPhotosResult(total: 0, totalPages: 0, results: []);
  }

  final repository = ref.watch(photoRepositoryProvider);
  final result = await repository.searchPhotos(
    query,
    page: params.page,
    perPage: params.perPage,
    orderBy: params.orderBy,
    color: params.color,
    orientation: params.orientation,
    contentFilter: params.contentFilter,
  );

  return result.fold(
    (failure) => throw Exception(failure.toString()),
    (searchResult) => searchResult,
  );
});

final collectionSearchProvider =
    FutureProvider.family<SearchCollectionsResult, CollectionSearchParams>(
        (ref, params) async {
  final query = params.query.trim();
  if (query.isEmpty) {
    return const SearchCollectionsResult(
      total: 0,
      totalPages: 0,
      results: [],
    );
  }

  final repository = ref.watch(collectionRepositoryProvider);
  final result = await repository.searchCollections(
    query,
    page: params.page,
    perPage: params.perPage,
  );

  return result.fold(
    (failure) => throw Exception(failure.toString()),
    (searchResult) => searchResult,
  );
});

final userSearchProvider =
    FutureProvider.family<SearchUsersResult, UserSearchParams>(
        (ref, params) async {
  final query = params.query.trim();
  if (query.isEmpty) {
    return const SearchUsersResult(total: 0, totalPages: 0, results: []);
  }

  final repository = ref.watch(profileRepositoryProvider);
  final result = await repository.searchUsers(
    query,
    page: params.page,
    perPage: params.perPage,
  );

  return result.fold(
    (failure) => throw Exception(failure.toString()),
    (searchResult) => searchResult,
  );
});
