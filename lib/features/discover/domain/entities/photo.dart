import 'package:musea/features/discover/domain/entities/user.dart';

class Photo {
  final String id;
  final String? slug;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? promotedAt;
  final int width;
  final int height;
  final String color;
  final String? blurHash;
  final String? description;
  final String? altDescription;
  final String urlRaw;
  final String urlFull;
  final String urlRegular;
  final String urlSmall;
  final String urlThumb;
  final String? downloadLink;
  final String? downloadLocation;
  final int likes;
  final int downloads;
  final int? views;
  final bool likedByUser;
  final bool bookmarked;
  final String? assetType;
  final User user;
  final ExifData? exif;
  final LocationData? location;
  final List<Tag> tags;

  const Photo({
    required this.id,
    this.slug,
    required this.createdAt,
    this.updatedAt,
    this.promotedAt,
    required this.width,
    required this.height,
    required this.color,
    this.blurHash,
    this.description,
    this.altDescription,
    required this.urlRaw,
    required this.urlFull,
    required this.urlRegular,
    required this.urlSmall,
    required this.urlThumb,
    this.downloadLink,
    this.downloadLocation,
    required this.likes,
    required this.downloads,
    this.views,
    this.likedByUser = false,
    this.bookmarked = false,
    this.assetType,
    required this.user,
    this.exif,
    this.location,
    this.tags = const [],
  });

  double get aspectRatio => width / height;

  bool get isPortrait => height > width;

  bool get isLandscape => width > height;
}

class ExifData {
  final String? make;
  final String? model;
  final String? exposureTime;
  final String? aperture;
  final String? focalLength;
  final int? iso;

  const ExifData({
    this.make,
    this.model,
    this.exposureTime,
    this.aperture,
    this.focalLength,
    this.iso,
  });
}

class LocationData {
  final String? city;
  final String? country;
  final double? latitude;
  final double? longitude;

  const LocationData({
    this.city,
    this.country,
    this.latitude,
    this.longitude,
  });

  String get displayName {
    final parts = [city, country].where((p) => p != null && p.isNotEmpty);
    return parts.isEmpty ? 'Unknown location' : parts.join(', ');
  }
}

class Tag {
  final String title;
  final String? type;

  const Tag({
    required this.title,
    this.type,
  });
}
