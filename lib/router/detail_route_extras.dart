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

Collection? collectionDetailFromExtra(Object? extra) {
  return extra is CollectionDetailExtra ? extra.collection : null;
}
