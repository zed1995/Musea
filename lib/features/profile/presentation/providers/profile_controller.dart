import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/profile/presentation/providers/profile_provider.dart';
import 'package:musea/features/search/presentation/providers/search_controller.dart';

class UserPhotosController extends StateNotifier<PaginatedState<Photo>> {
  UserPhotosController(this.ref, {required this.username})
      : super(const PaginatedState<Photo>());
  final Ref ref;
  final String username;

  Future<void> loadInitial() async {
    if (state.page > 0 || state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(profileRepositoryProvider);
      final result = await repo.getUserPhotos(username, page: 1, perPage: 20);
      result.fold(
        (f) => state = PaginatedState<Photo>(error: f, hasMorePages: false),
        (photos) => state = PaginatedState<Photo>(
            items: photos, page: 1, hasMorePages: photos.length >= 20),
      );
    } catch (e) {
      state = PaginatedState<Photo>(error: e, hasMorePages: false);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMorePages) return;
    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true, error: null);
    try {
      final repo = ref.read(profileRepositoryProvider);
      final result =
          await repo.getUserPhotos(username, page: nextPage, perPage: 20);
      result.fold(
        (f) => state = state.copyWith(
            isLoadingMore: false, hasMorePages: false, error: f),
        (photos) => state = state.copyWith(
          items: [...state.items, ...photos],
          page: nextPage,
          isLoadingMore: false,
          hasMorePages: photos.length >= 20,
        ),
      );
    } catch (e) {
      state =
          state.copyWith(isLoadingMore: false, hasMorePages: false, error: e);
    }
  }
}

class UserCollectionsController
    extends StateNotifier<PaginatedState<Collection>> {
  UserCollectionsController(this.ref, {required this.username})
      : super(const PaginatedState<Collection>());
  final Ref ref;
  final String username;

  Future<void> loadInitial() async {
    if (state.page > 0 || state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(profileRepositoryProvider);
      final result =
          await repo.getUserCollections(username, page: 1, perPage: 20);
      result.fold(
        (f) =>
            state = PaginatedState<Collection>(error: f, hasMorePages: false),
        (cols) => state = PaginatedState<Collection>(
            items: cols, page: 1, hasMorePages: cols.length >= 20),
      );
    } catch (e) {
      state = PaginatedState<Collection>(error: e, hasMorePages: false);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMorePages) return;
    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true, error: null);
    try {
      final repo = ref.read(profileRepositoryProvider);
      final result = await repo.getUserCollections(username,
          page: nextPage, perPage: 20);
      result.fold(
        (f) => state = state.copyWith(
            isLoadingMore: false, hasMorePages: false, error: f),
        (cols) => state = state.copyWith(
          items: [...state.items, ...cols],
          page: nextPage,
          isLoadingMore: false,
          hasMorePages: cols.length >= 20,
        ),
      );
    } catch (e) {
      state =
          state.copyWith(isLoadingMore: false, hasMorePages: false, error: e);
    }
  }
}

class UserLikesController extends StateNotifier<PaginatedState<Photo>> {
  UserLikesController(this.ref, {required this.username})
      : super(const PaginatedState<Photo>());
  final Ref ref;
  final String username;

  Future<void> loadInitial() async {
    if (state.page > 0 || state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(profileRepositoryProvider);
      final result = await repo.getUserLikes(username, page: 1, perPage: 20);
      result.fold(
        (f) => state = PaginatedState<Photo>(error: f, hasMorePages: false),
        (photos) => state = PaginatedState<Photo>(
            items: photos, page: 1, hasMorePages: photos.length >= 20),
      );
    } catch (e) {
      state = PaginatedState<Photo>(error: e, hasMorePages: false);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMorePages) return;
    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true, error: null);
    try {
      final repo = ref.read(profileRepositoryProvider);
      final result =
          await repo.getUserLikes(username, page: nextPage, perPage: 20);
      result.fold(
        (f) => state = state.copyWith(
            isLoadingMore: false, hasMorePages: false, error: f),
        (photos) => state = state.copyWith(
          items: [...state.items, ...photos],
          page: nextPage,
          isLoadingMore: false,
          hasMorePages: photos.length >= 20,
        ),
      );
    } catch (e) {
      state =
          state.copyWith(isLoadingMore: false, hasMorePages: false, error: e);
    }
  }
}

final userPhotosControllerProvider = StateNotifierProvider.family<
    UserPhotosController, PaginatedState<Photo>, String>((ref, username) {
  return UserPhotosController(ref, username: username);
});

final userCollectionsControllerProvider = StateNotifierProvider.family<
    UserCollectionsController,
    PaginatedState<Collection>,
    String>((ref, username) {
  return UserCollectionsController(ref, username: username);
});

final userLikesControllerProvider = StateNotifierProvider.family<
    UserLikesController, PaginatedState<Photo>, String>((ref, username) {
  return UserLikesController(ref, username: username);
});
