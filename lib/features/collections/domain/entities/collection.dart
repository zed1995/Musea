import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';

class Collection {
  final String id;
  final String title;
  final String? description;
  final int totalPhotos;
  final Photo? coverPhoto;
  final List<PreviewPhoto> previewPhotos;
  final User? user;
  final DateTime? updatedAt;

  const Collection({
    required this.id,
    required this.title,
    this.description,
    required this.totalPhotos,
    this.coverPhoto,
    this.previewPhotos = const [],
    this.user,
    this.updatedAt,
  });
}

class PreviewPhoto {
  final String id;
  final String? slug;
  final String thumbUrl;
  final String smallUrl;

  const PreviewPhoto({
    required this.id,
    this.slug,
    required this.thumbUrl,
    required this.smallUrl,
  });
}
