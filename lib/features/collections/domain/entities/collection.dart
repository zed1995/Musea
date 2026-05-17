import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';

class Collection {
  final String id;
  final String title;
  final String? description;
  final DateTime? publishedAt;
  final DateTime? lastCollectedAt;
  final int totalPhotos;
  final int? totalPlus;
  final bool featured;
  final bool isPrivate;
  final String? shareKey;
  final CollectionLinks? links;
  final CollectionMeta? meta;
  final List<String> mediaTypes;
  final Photo? coverPhoto;
  final List<PreviewPhoto> previewPhotos;
  final User? user;
  final DateTime? updatedAt;

  const Collection({
    required this.id,
    required this.title,
    this.description,
    this.publishedAt,
    this.lastCollectedAt,
    required this.totalPhotos,
    this.totalPlus,
    this.featured = false,
    this.isPrivate = false,
    this.shareKey,
    this.links,
    this.meta,
    this.mediaTypes = const [],
    this.coverPhoto,
    this.previewPhotos = const [],
    this.user,
    this.updatedAt,
  });
}

class PreviewPhoto {
  final String id;
  final String? slug;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? blurHash;
  final String? assetType;
  final String thumbUrl;
  final String smallUrl;
  final String regularUrl;

  const PreviewPhoto({
    required this.id,
    this.slug,
    this.createdAt,
    this.updatedAt,
    this.blurHash,
    this.assetType,
    required this.thumbUrl,
    required this.smallUrl,
    required this.regularUrl,
  });
}

class CollectionLinks {
  final String? self;
  final String? html;
  final String? photos;
  final String? related;

  const CollectionLinks({
    this.self,
    this.html,
    this.photos,
    this.related,
  });
}

class CollectionMeta {
  final String? title;
  final String? description;
  final bool? index;

  const CollectionMeta({
    this.title,
    this.description,
    this.index,
  });
}
