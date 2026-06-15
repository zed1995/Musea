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
  final String? htmlLink;
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
    this.htmlLink,
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'slug': slug,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'promoted_at': promotedAt?.toIso8601String(),
        'width': width,
        'height': height,
        'color': color,
        'blur_hash': blurHash,
        'description': description,
        'alt_description': altDescription,
        'url_raw': urlRaw,
        'url_full': urlFull,
        'url_regular': urlRegular,
        'url_small': urlSmall,
        'url_thumb': urlThumb,
        'html_link': htmlLink,
        'download_link': downloadLink,
        'download_location': downloadLocation,
        'likes': likes,
        'downloads': downloads,
        'views': views,
        'liked_by_user': likedByUser,
        'bookmarked': bookmarked,
        'asset_type': assetType,
        'user': user.toJson(),
        'exif': exif?.toJson(),
        'location': location?.toJson(),
        'tags': tags.map((t) => t.toJson()).toList(),
      };

  factory Photo.fromJson(Map<String, dynamic> json) => Photo(
        id: json['id'] as String,
        slug: json['slug'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
        promotedAt: json['promoted_at'] != null
            ? DateTime.parse(json['promoted_at'] as String)
            : null,
        width: (json['width'] as num).toInt(),
        height: (json['height'] as num).toInt(),
        color: json['color'] as String,
        blurHash: json['blur_hash'] as String?,
        description: json['description'] as String?,
        altDescription: json['alt_description'] as String?,
        urlRaw: json['url_raw'] as String,
        urlFull: json['url_full'] as String,
        urlRegular: json['url_regular'] as String,
        urlSmall: json['url_small'] as String,
        urlThumb: json['url_thumb'] as String,
        htmlLink: json['html_link'] as String?,
        downloadLink: json['download_link'] as String?,
        downloadLocation: json['download_location'] as String?,
        likes: (json['likes'] as num).toInt(),
        downloads: (json['downloads'] as num).toInt(),
        views: (json['views'] as num?)?.toInt(),
        likedByUser: json['liked_by_user'] as bool? ?? false,
        bookmarked: json['bookmarked'] as bool? ?? false,
        assetType: json['asset_type'] as String?,
        user: User.fromJson(json['user'] as Map<String, dynamic>),
        exif: json['exif'] != null
            ? ExifData.fromJson(json['exif'] as Map<String, dynamic>)
            : null,
        location: json['location'] != null
            ? LocationData.fromJson(json['location'] as Map<String, dynamic>)
            : null,
        tags: (json['tags'] as List<dynamic>?)
                ?.map((t) =>
                    Tag.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [],
      );
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

  Map<String, dynamic> toJson() => {
        'make': make,
        'model': model,
        'exposure_time': exposureTime,
        'aperture': aperture,
        'focal_length': focalLength,
        'iso': iso,
      };

  factory ExifData.fromJson(Map<String, dynamic> json) => ExifData(
        make: json['make'] as String?,
        model: json['model'] as String?,
        exposureTime: json['exposure_time'] as String?,
        aperture: json['aperture'] as String?,
        focalLength: json['focal_length'] as String?,
        iso: json['iso'] as int?,
      );
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

  Map<String, dynamic> toJson() => {
        'city': city,
        'country': country,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory LocationData.fromJson(Map<String, dynamic> json) => LocationData(
        city: json['city'] as String?,
        country: json['country'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );
}

class Tag {
  final String title;
  final String? type;

  const Tag({
    required this.title,
    this.type,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'type': type,
      };

  factory Tag.fromJson(Map<String, dynamic> json) => Tag(
        title: json['title'] as String,
        type: json['type'] as String?,
      );
}
