import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/presentation/providers/photos_provider.dart';

class PhotoLikeState {
  const PhotoLikeState({
    required this.likes,
    required this.likedByUser,
  });

  final int likes;
  final bool likedByUser;
}

class PhotoLikeController extends StateNotifier<Map<String, PhotoLikeState>> {
  PhotoLikeController(this._ref) : super(const {});

  final Ref _ref;

  Future<bool> toggle({
    required Photo photo,
    required String accessToken,
  }) async {
    final repository = _ref.read(photoRepositoryProvider);
    final current = state[photo.id] ??
        PhotoLikeState(
          likes: photo.likes,
          likedByUser: photo.likedByUser,
        );

    final result = current.likedByUser
        ? await repository.unlikePhoto(
            photo.id,
            accessToken: accessToken,
          )
        : await repository.likePhoto(
            photo.id,
            accessToken: accessToken,
          );

    return result.fold(
      (_) => false,
      (updatedPhoto) {
        state = {
          ...state,
          photo.id: PhotoLikeState(
            likes: updatedPhoto.likes,
            likedByUser: updatedPhoto.likedByUser,
          ),
        };
        return true;
      },
    );
  }
}

final photoLikeControllerProvider =
    StateNotifierProvider<PhotoLikeController, Map<String, PhotoLikeState>>((
  ref,
) {
  return PhotoLikeController(ref);
});

final photoLikeStateProvider = Provider.family<PhotoLikeState, Photo>((
  ref,
  photo,
) {
  return ref.watch(
        photoLikeControllerProvider.select((state) => state[photo.id]),
      ) ??
      PhotoLikeState(
        likes: photo.likes,
        likedByUser: photo.likedByUser,
      );
});
