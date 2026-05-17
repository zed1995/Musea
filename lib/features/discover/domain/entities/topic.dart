import 'package:musea/features/discover/domain/entities/photo.dart';

class Topic {
  final String id;
  final String slug;
  final String title;
  final String? description;
  final int totalPhotos;
  final Photo? coverPhoto;
  final String? link;

  const Topic({
    required this.id,
    required this.slug,
    required this.title,
    this.description,
    required this.totalPhotos,
    this.coverPhoto,
    this.link,
  });
}
