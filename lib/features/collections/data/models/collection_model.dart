import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/discover/data/models/photo_model.dart';
import 'package:musea/features/discover/data/models/user_model.dart';

part 'collection_model.freezed.dart';
part 'collection_model.g.dart';

@freezed
class CollectionModel with _$CollectionModel {
  const CollectionModel._();

  const factory CollectionModel({
    required String id,
    required String title,
    String? description,
    @JsonKey(name: 'total_photos') required int totalPhotos,
    @JsonKey(name: 'cover_photo') PhotoModel? coverPhoto,
    @JsonKey(name: 'preview_photos') @Default([]) List<PreviewPhotoModel> previewPhotos,
    UserModel? user,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _CollectionModel;

  factory CollectionModel.fromJson(Map<String, dynamic> json) =>
      _$CollectionModelFromJson(json);

  Collection toEntity() => Collection(
    id: id,
    title: title,
    description: description,
    totalPhotos: totalPhotos,
    coverPhoto: coverPhoto?.toEntity(),
    previewPhotos: previewPhotos.map((p) => p.toEntity()).toList(),
    user: user?.toEntity(),
    updatedAt: updatedAt,
  );
}

@freezed
class PreviewPhotoModel with _$PreviewPhotoModel {
  const PreviewPhotoModel._();

  const factory PreviewPhotoModel({
    required String id,
    String? slug,
    @JsonKey(name: 'thumb') required String thumbUrl,
    @JsonKey(name: 'small') required String smallUrl,
  }) = _PreviewPhotoModel;

  factory PreviewPhotoModel.fromJson(Map<String, dynamic> json) =>
      _$PreviewPhotoModelFromJson(json);

  PreviewPhoto toEntity() => PreviewPhoto(
    id: id,
    slug: slug,
    thumbUrl: thumbUrl,
    smallUrl: smallUrl,
  );
}
