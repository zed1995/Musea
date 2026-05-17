class User {
  final String id;
  final DateTime? updatedAt;
  final String username;
  final String name;
  final String? firstName;
  final String? lastName;
  final String? bio;
  final String? location;
  final String? portfolioUrl;
  final String? instagramUsername;
  final String? twitterUsername;
  final String profileImageSmall;
  final String profileImageMedium;
  final String profileImageLarge;
  final int totalPhotos;
  final int totalLikes;
  final int totalCollections;
  final int? totalFreePhotos;
  final int? totalPromotedPhotos;
  final int? totalIllustrations;
  final int? totalFreeIllustrations;
  final int? totalPromotedIllustrations;
  final bool? acceptedTos;
  final bool? forHire;
  final UserLinks? links;
  final UserSocial? social;
  final List<UserPhotoPreview> photosPreview;
  final UserTags? tags;
  final bool? allowMessages;
  final int? numericId;
  final int? downloads;
  final UserMeta? meta;

  const User({
    required this.id,
    this.updatedAt,
    required this.username,
    required this.name,
    this.firstName,
    this.lastName,
    this.bio,
    this.location,
    this.portfolioUrl,
    this.instagramUsername,
    this.twitterUsername,
    required this.profileImageSmall,
    required this.profileImageMedium,
    required this.profileImageLarge,
    required this.totalPhotos,
    required this.totalLikes,
    required this.totalCollections,
    this.totalFreePhotos,
    this.totalPromotedPhotos,
    this.totalIllustrations,
    this.totalFreeIllustrations,
    this.totalPromotedIllustrations,
    this.acceptedTos,
    this.forHire,
    this.links,
    this.social,
    this.photosPreview = const [],
    this.tags,
    this.allowMessages,
    this.numericId,
    this.downloads,
    this.meta,
  });
}

class UserLinks {
  final String? self;
  final String? html;
  final String? photos;
  final String? likes;

  const UserLinks({
    this.self,
    this.html,
    this.photos,
    this.likes,
  });
}

class UserSocial {
  final String? instagramUsername;
  final String? portfolioUrl;
  final String? twitterUsername;
  final String? paypalEmail;

  const UserSocial({
    this.instagramUsername,
    this.portfolioUrl,
    this.twitterUsername,
    this.paypalEmail,
  });
}

class UserPhotoPreview {
  final String id;
  final String? slug;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? blurHash;
  final String? assetType;
  final String thumbUrl;
  final String smallUrl;
  final String regularUrl;

  const UserPhotoPreview({
    required this.id,
    this.slug,
    this.createdAt,
    this.updatedAt,
    this.blurHash,
    this.assetType,
    required this.thumbUrl,
    required this.smallUrl,
    required this.regularUrl,
  });
}

class UserTags {
  final List<UserTagItem> custom;
  final List<UserTagItem> aggregated;

  const UserTags({
    this.custom = const [],
    this.aggregated = const [],
  });
}

class UserTagItem {
  final String title;
  final String? type;

  const UserTagItem({
    required this.title,
    this.type,
  });
}

class UserMeta {
  final bool? index;

  const UserMeta({
    this.index,
  });
}
