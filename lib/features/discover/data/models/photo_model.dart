import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/data/models/user_model.dart';

part 'photo_model.freezed.dart';
part 'photo_model.g.dart';

@freezed
class PhotoModel with _$PhotoModel {
  const PhotoModel._();
  
  const factory PhotoModel({
    required String id,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    required int width,
    required int height,
    required String color,
    @JsonKey(name: 'blur_hash') String? blurHash,
    String? description,
    @JsonKey(name: 'alt_description') String? altDescription,
    required UrlsModel urls,
    required int likes,
    @Default(0) int downloads,
    @Default(0) int views,
    required UserModel user,
    ExifModel? exif,
    LocationModel? location,
    @Default([]) List<TagModel> tags,
  }) = _PhotoModel;

  factory PhotoModel.fromJson(Map<String, dynamic> json) =>
      _$PhotoModelFromJson(json);
  
  Photo toEntity() => Photo(
    id: id,
    createdAt: createdAt,
    width: width,
    height: height,
    color: color,
    blurHash: blurHash,
    description: description,
    altDescription: altDescription,
    urlRaw: urls.raw,
    urlFull: urls.full,
    urlRegular: urls.regular,
    urlSmall: urls.small,
    urlThumb: urls.thumb,
    likes: likes,
    downloads: downloads,
    views: views,
    user: user.toEntity(),
    exif: exif?.toEntity(),
    location: location?.toEntity(),
    tags: tags.map((t) => t.toEntity()).toList(),
  );
}

@freezed
class UrlsModel with _$UrlsModel {
  const factory UrlsModel({
    required String raw,
    required String full,
    required String regular,
    required String small,
    required String thumb,
  }) = _UrlsModel;

  factory UrlsModel.fromJson(Map<String, dynamic> json) =>
      _$UrlsModelFromJson(json);
}

@freezed
class ExifModel with _$ExifModel {
  const ExifModel._();
  
  const factory ExifModel({
    String? make,
    String? model,
    @JsonKey(name: 'exposure_time') String? exposureTime,
    String? aperture,
    @JsonKey(name: 'focal_length') String? focalLength,
    int? iso,
  }) = _ExifModel;

  factory ExifModel.fromJson(Map<String, dynamic> json) =>
      _$ExifModelFromJson(json);
  
  ExifData toEntity() => ExifData(
    make: make,
    model: model,
    exposureTime: exposureTime,
    aperture: aperture,
    focalLength: focalLength,
    iso: iso,
  );
}

@freezed
class LocationModel with _$LocationModel {
  const LocationModel._();
  
  const factory LocationModel({
    String? city,
    String? country,
    PositionModel? position,
  }) = _LocationModel;

  factory LocationModel.fromJson(Map<String, dynamic> json) =>
      _$LocationModelFromJson(json);
  
  LocationData toEntity() => LocationData(
    city: city,
    country: country,
    latitude: position?.latitude,
    longitude: position?.longitude,
  );
}

@freezed
class PositionModel with _$PositionModel {
  const factory PositionModel({
    required double latitude,
    required double longitude,
  }) = _PositionModel;

  factory PositionModel.fromJson(Map<String, dynamic> json) =>
      _$PositionModelFromJson(json);
}

@freezed
class TagModel with _$TagModel {
  const TagModel._();
  
  const factory TagModel({
    required String title,
    String? type,
  }) = _TagModel;

  factory TagModel.fromJson(Map<String, dynamic> json) =>
      _$TagModelFromJson(json);
  
  Tag toEntity() => Tag(title: title, type: type);
}
