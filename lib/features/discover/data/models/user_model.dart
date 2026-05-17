import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:musea/features/discover/domain/entities/user.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const UserModel._();
  
  const factory UserModel({
    required String id,
    required String username,
    required String name,
    String? bio,
    @JsonKey(name: 'portfolio_url') String? portfolioUrl,
    @JsonKey(name: 'profile_image') required ProfileImageModel profileImage,
    @JsonKey(name: 'total_photos') required int totalPhotos,
    @JsonKey(name: 'total_likes') required int totalLikes,
    @JsonKey(name: 'total_collections') required int totalCollections,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
  
  User toEntity() => User(
    id: id,
    username: username,
    name: name,
    bio: bio,
    portfolioUrl: portfolioUrl,
    profileImageSmall: profileImage.small,
    profileImageMedium: profileImage.medium,
    profileImageLarge: profileImage.large,
    totalPhotos: totalPhotos,
    totalLikes: totalLikes,
    totalCollections: totalCollections,
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
