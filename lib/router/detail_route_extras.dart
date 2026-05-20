import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';

class PhotoDetailExtra {
  const PhotoDetailExtra({
    required this.photo,
    this.hydrateDeferredDetails = true,
  });

  final Photo photo;
  final bool hydrateDeferredDetails;
}

class PhotoViewerExtra {
  const PhotoViewerExtra({
    required this.photo,
    this.heroTag,
  });

  final Photo photo;
  final String? heroTag;
}

class CollectionDetailExtra {
  const CollectionDetailExtra({required this.collection});

  final Collection collection;
}

Photo? photoDetailFromExtra(Object? extra) {
  return extra is PhotoDetailExtra ? extra.photo : null;
}

bool photoDetailShouldHydrateFromExtra(Object? extra) {
  return extra is PhotoDetailExtra ? extra.hydrateDeferredDetails : false;
}

Photo? photoViewerFromExtra(Object? extra) {
  return extra is PhotoViewerExtra ? extra.photo : null;
}

String? photoViewerHeroTagFromExtra(Object? extra) {
  return extra is PhotoViewerExtra ? extra.heroTag : null;
}

Collection? collectionDetailFromExtra(Object? extra) {
  return extra is CollectionDetailExtra ? extra.collection : null;
}
