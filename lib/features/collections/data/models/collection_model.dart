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
    @JsonKey(name: 'published_at') DateTime? publishedAt,
    @JsonKey(name: 'last_collected_at') DateTime? lastCollectedAt,
    @JsonKey(name: 'total_photos') required int totalPhotos,
    @JsonKey(name: 'total_plus') int? totalPlus,
    @Default(false) bool featured,
    @JsonKey(name: 'private') @Default(false) bool isPrivate,
    @JsonKey(name: 'share_key') String? shareKey,
    CollectionLinksModel? links,
    CollectionMetaModel? meta,
    @JsonKey(name: 'media_types') @Default([]) List<String> mediaTypes,
    @JsonKey(name: 'cover_photo') PhotoModel? coverPhoto,
    @JsonKey(name: 'preview_photos')
    @Default([])
    List<PreviewPhotoModel> previewPhotos,
    UserModel? user,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _CollectionModel;

  factory CollectionModel.fromJson(Map<String, dynamic> json) =>
      _$CollectionModelFromJson(json);

  Collection toEntity() => Collection(
        id: id,
        title: title,
        description: description,
        publishedAt: publishedAt,
        lastCollectedAt: lastCollectedAt,
        totalPhotos: totalPhotos,
        totalPlus: totalPlus,
        featured: featured,
        isPrivate: isPrivate,
        shareKey: shareKey,
        links: links?.toEntity(),
        meta: meta?.toEntity(),
        mediaTypes: mediaTypes,
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
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'blur_hash') String? blurHash,
    @JsonKey(name: 'asset_type') String? assetType,
    @JsonKey(name: 'urls') required PreviewPhotoUrlsModel urls,
  }) = _PreviewPhotoModel;

  factory PreviewPhotoModel.fromJson(Map<String, dynamic> json) =>
      _$PreviewPhotoModelFromJson(json);

  PreviewPhoto toEntity() => PreviewPhoto(
        id: id,
        slug: slug,
        createdAt: createdAt,
        updatedAt: updatedAt,
        blurHash: blurHash,
        assetType: assetType,
        thumbUrl: urls.thumb,
        smallUrl: urls.small,
        regularUrl: urls.regular,
      );
}

@freezed
class PreviewPhotoUrlsModel with _$PreviewPhotoUrlsModel {
  const factory PreviewPhotoUrlsModel({
    required String thumb,
    required String small,
    required String regular,
  }) = _PreviewPhotoUrlsModel;

  factory PreviewPhotoUrlsModel.fromJson(Map<String, dynamic> json) =>
      _$PreviewPhotoUrlsModelFromJson(json);
}

@freezed
class CollectionLinksModel with _$CollectionLinksModel {
  const CollectionLinksModel._();

  const factory CollectionLinksModel({
    String? self,
    String? html,
    String? photos,
    String? related,
  }) = _CollectionLinksModel;

  factory CollectionLinksModel.fromJson(Map<String, dynamic> json) =>
      _$CollectionLinksModelFromJson(json);

  CollectionLinks toEntity() => CollectionLinks(
        self: self,
        html: html,
        photos: photos,
        related: related,
      );
}

@freezed
class CollectionMetaModel with _$CollectionMetaModel {
  const CollectionMetaModel._();

  const factory CollectionMetaModel({
    String? title,
    String? description,
    bool? index,
  }) = _CollectionMetaModel;

  factory CollectionMetaModel.fromJson(Map<String, dynamic> json) =>
      _$CollectionMetaModelFromJson(json);

  CollectionMeta toEntity() => CollectionMeta(
        title: title,
        description: description,
        index: index,
      );
}
