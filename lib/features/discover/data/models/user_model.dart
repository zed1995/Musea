import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:musea/features/discover/domain/entities/user.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const UserModel._();

  const factory UserModel({
    required String id,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    required String username,
    required String name,
    @JsonKey(name: 'first_name') String? firstName,
    @JsonKey(name: 'last_name') String? lastName,
    String? bio,
    String? location,
    @JsonKey(name: 'portfolio_url') String? portfolioUrl,
    @JsonKey(name: 'instagram_username') String? instagramUsername,
    @JsonKey(name: 'twitter_username') String? twitterUsername,
    UserLinksModel? links,
    @JsonKey(name: 'profile_image') required ProfileImageModel profileImage,
    @JsonKey(name: 'total_photos') required int totalPhotos,
    @JsonKey(name: 'total_likes') required int totalLikes,
    @JsonKey(name: 'total_collections') required int totalCollections,
    @JsonKey(name: 'total_free_photos') int? totalFreePhotos,
    @JsonKey(name: 'total_promoted_photos') int? totalPromotedPhotos,
    @JsonKey(name: 'total_illustrations') int? totalIllustrations,
    @JsonKey(name: 'total_free_illustrations') int? totalFreeIllustrations,
    @JsonKey(name: 'total_promoted_illustrations')
    int? totalPromotedIllustrations,
    @JsonKey(name: 'accepted_tos') bool? acceptedTos,
    @JsonKey(name: 'for_hire') bool? forHire,
    UserSocialModel? social,
    @JsonKey(name: 'photos') @Default([]) List<UserPhotoPreviewModel> photos,
    UserTagsModel? tags,
    @JsonKey(name: 'allow_messages') bool? allowMessages,
    @JsonKey(name: 'numeric_id') int? numericId,
    int? downloads,
    UserMetaModel? meta,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  User toEntity() => User(
        id: id,
        updatedAt: updatedAt,
        username: username,
        name: name,
        firstName: firstName,
        lastName: lastName,
        bio: bio,
        location: location,
        portfolioUrl: portfolioUrl,
        instagramUsername: instagramUsername,
        twitterUsername: twitterUsername,
        links: links?.toEntity(),
        profileImageSmall: profileImage.small,
        profileImageMedium: profileImage.medium,
        profileImageLarge: profileImage.large,
        totalPhotos: totalPhotos,
        totalLikes: totalLikes,
        totalCollections: totalCollections,
        totalFreePhotos: totalFreePhotos,
        totalPromotedPhotos: totalPromotedPhotos,
        totalIllustrations: totalIllustrations,
        totalFreeIllustrations: totalFreeIllustrations,
        totalPromotedIllustrations: totalPromotedIllustrations,
        acceptedTos: acceptedTos,
        forHire: forHire,
        social: social?.toEntity(),
        photosPreview: photos.map((photo) => photo.toEntity()).toList(),
        tags: tags?.toEntity(),
        allowMessages: allowMessages,
        numericId: numericId,
        downloads: downloads,
        meta: meta?.toEntity(),
      );
}

@freezed
class UserLinksModel with _$UserLinksModel {
  const UserLinksModel._();

  const factory UserLinksModel({
    String? self,
    String? html,
    String? photos,
    String? likes,
  }) = _UserLinksModel;

  factory UserLinksModel.fromJson(Map<String, dynamic> json) =>
      _$UserLinksModelFromJson(json);

  UserLinks toEntity() => UserLinks(
        self: self,
        html: html,
        photos: photos,
        likes: likes,
      );
}

@freezed
class ProfileImageModel with _$ProfileImageModel {
  const factory ProfileImageModel({
    required String small,
    required String medium,
    required String large,
  }) = _ProfileImageModel;

  factory ProfileImageModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileImageModelFromJson(json);
}

@freezed
class UserSocialModel with _$UserSocialModel {
  const UserSocialModel._();

  const factory UserSocialModel({
    @JsonKey(name: 'instagram_username') String? instagramUsername,
    @JsonKey(name: 'portfolio_url') String? portfolioUrl,
    @JsonKey(name: 'twitter_username') String? twitterUsername,
    @JsonKey(name: 'paypal_email') String? paypalEmail,
  }) = _UserSocialModel;

  factory UserSocialModel.fromJson(Map<String, dynamic> json) =>
      _$UserSocialModelFromJson(json);

  UserSocial toEntity() => UserSocial(
        instagramUsername: instagramUsername,
        portfolioUrl: portfolioUrl,
        twitterUsername: twitterUsername,
        paypalEmail: paypalEmail,
      );
}

@freezed
class UserPhotoPreviewModel with _$UserPhotoPreviewModel {
  const UserPhotoPreviewModel._();

  const factory UserPhotoPreviewModel({
    required String id,
    String? slug,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'blur_hash') String? blurHash,
    @JsonKey(name: 'asset_type') String? assetType,
    @JsonKey(name: 'urls') required UserPhotoPreviewUrlsModel urls,
  }) = _UserPhotoPreviewModel;

  factory UserPhotoPreviewModel.fromJson(Map<String, dynamic> json) =>
      _$UserPhotoPreviewModelFromJson(json);

  UserPhotoPreview toEntity() => UserPhotoPreview(
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
class UserPhotoPreviewUrlsModel with _$UserPhotoPreviewUrlsModel {
  const factory UserPhotoPreviewUrlsModel({
    required String thumb,
    required String small,
    required String regular,
  }) = _UserPhotoPreviewUrlsModel;

  factory UserPhotoPreviewUrlsModel.fromJson(Map<String, dynamic> json) =>
      _$UserPhotoPreviewUrlsModelFromJson(json);
}

@freezed
class UserTagsModel with _$UserTagsModel {
  const UserTagsModel._();

  const factory UserTagsModel({
    @Default([]) List<UserTagItemModel> custom,
    @Default([]) List<UserTagItemModel> aggregated,
  }) = _UserTagsModel;

  factory UserTagsModel.fromJson(Map<String, dynamic> json) =>
      _$UserTagsModelFromJson(json);

  UserTags toEntity() => UserTags(
        custom: custom.map((item) => item.toEntity()).toList(),
        aggregated: aggregated.map((item) => item.toEntity()).toList(),
      );
}

@freezed
class UserTagItemModel with _$UserTagItemModel {
  const UserTagItemModel._();

  const factory UserTagItemModel({
    required String title,
    String? type,
  }) = _UserTagItemModel;

  factory UserTagItemModel.fromJson(Map<String, dynamic> json) =>
      _$UserTagItemModelFromJson(json);

  UserTagItem toEntity() => UserTagItem(
        title: title,
        type: type,
      );
}

@freezed
class UserMetaModel with _$UserMetaModel {
  const UserMetaModel._();

  const factory UserMetaModel({
    bool? index,
  }) = _UserMetaModel;

  factory UserMetaModel.fromJson(Map<String, dynamic> json) =>
      _$UserMetaModelFromJson(json);

  UserMeta toEntity() => UserMeta(
        index: index,
      );
}
