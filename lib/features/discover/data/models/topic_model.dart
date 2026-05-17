import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:musea/features/discover/domain/entities/topic.dart';
import 'package:musea/features/discover/data/models/photo_model.dart';

part 'topic_model.freezed.dart';
part 'topic_model.g.dart';

@freezed
class TopicModel with _$TopicModel {
  const TopicModel._();
  
  const factory TopicModel({
    required String id,
    required String slug,
    required String title,
    String? description,
    @JsonKey(name: 'total_photos') required int totalPhotos,
    @JsonKey(name: 'cover_photo') PhotoModel? coverPhoto,
    TopicLinksModel? links,
  }) = _TopicModel;

  factory TopicModel.fromJson(Map<String, dynamic> json) =>
      _$TopicModelFromJson(json);
  
  Topic toEntity() => Topic(
    id: id,
    slug: slug,
    title: title,
    description: description,
    totalPhotos: totalPhotos,
    coverPhoto: coverPhoto?.toEntity(),
    link: links?.self,
  );
}

@freezed
class TopicLinksModel with _$TopicLinksModel {
  const factory TopicLinksModel({
    String? self,
    String? html,
    String? photos,
  }) = _TopicLinksModel;

  factory TopicLinksModel.fromJson(Map<String, dynamic> json) =>
      _$TopicLinksModelFromJson(json);
}
