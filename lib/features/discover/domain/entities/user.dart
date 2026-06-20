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
  final bool? followedByUser;
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
    this.followedByUser,
    this.numericId,
    this.downloads,
    this.meta,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'updated_at': updatedAt?.toIso8601String(),
        'username': username,
        'name': name,
        'first_name': firstName,
        'last_name': lastName,
        'bio': bio,
        'location': location,
        'portfolio_url': portfolioUrl,
        'instagram_username': instagramUsername,
        'twitter_username': twitterUsername,
        'profile_image_small': profileImageSmall,
        'profile_image_medium': profileImageMedium,
        'profile_image_large': profileImageLarge,
        'total_photos': totalPhotos,
        'total_likes': totalLikes,
        'total_collections': totalCollections,
        'total_free_photos': totalFreePhotos,
        'total_promoted_photos': totalPromotedPhotos,
        'total_illustrations': totalIllustrations,
        'total_free_illustrations': totalFreeIllustrations,
        'total_promoted_illustrations': totalPromotedIllustrations,
        'accepted_tos': acceptedTos,
        'for_hire': forHire,
        'links': links?.toJson(),
        'social': social?.toJson(),
        'photos_preview': photosPreview.map((p) => p.toJson()).toList(),
        'tags': tags?.toJson(),
        'allow_messages': allowMessages,
        'followed_by_user': followedByUser,
        'numeric_id': numericId,
        'downloads': downloads,
        'meta': meta?.toJson(),
      };

  User copyWith({
    String? id,
    DateTime? updatedAt,
    String? username,
    String? name,
    String? firstName,
    String? lastName,
    String? bio,
    String? location,
    String? portfolioUrl,
    String? instagramUsername,
    String? twitterUsername,
    String? profileImageSmall,
    String? profileImageMedium,
    String? profileImageLarge,
    int? totalPhotos,
    int? totalLikes,
    int? totalCollections,
    int? totalFreePhotos,
    int? totalPromotedPhotos,
    int? totalIllustrations,
    int? totalFreeIllustrations,
    int? totalPromotedIllustrations,
    bool? acceptedTos,
    bool? forHire,
    UserLinks? links,
    UserSocial? social,
    List<UserPhotoPreview>? photosPreview,
    UserTags? tags,
    bool? allowMessages,
    bool? followedByUser,
    int? numericId,
    int? downloads,
    UserMeta? meta,
  }) {
    return User(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      username: username ?? this.username,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      portfolioUrl: portfolioUrl ?? this.portfolioUrl,
      instagramUsername: instagramUsername ?? this.instagramUsername,
      twitterUsername: twitterUsername ?? this.twitterUsername,
      profileImageSmall: profileImageSmall ?? this.profileImageSmall,
      profileImageMedium: profileImageMedium ?? this.profileImageMedium,
      profileImageLarge: profileImageLarge ?? this.profileImageLarge,
      totalPhotos: totalPhotos ?? this.totalPhotos,
      totalLikes: totalLikes ?? this.totalLikes,
      totalCollections: totalCollections ?? this.totalCollections,
      totalFreePhotos: totalFreePhotos ?? this.totalFreePhotos,
      totalPromotedPhotos: totalPromotedPhotos ?? this.totalPromotedPhotos,
      totalIllustrations: totalIllustrations ?? this.totalIllustrations,
      totalFreeIllustrations:
          totalFreeIllustrations ?? this.totalFreeIllustrations,
      totalPromotedIllustrations:
          totalPromotedIllustrations ?? this.totalPromotedIllustrations,
      acceptedTos: acceptedTos ?? this.acceptedTos,
      forHire: forHire ?? this.forHire,
      links: links ?? this.links,
      social: social ?? this.social,
      photosPreview: photosPreview ?? this.photosPreview,
      tags: tags ?? this.tags,
      allowMessages: allowMessages ?? this.allowMessages,
      followedByUser: followedByUser ?? this.followedByUser,
      numericId: numericId ?? this.numericId,
      downloads: downloads ?? this.downloads,
      meta: meta ?? this.meta,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
        username: json['username'] as String,
        name: json['name'] as String,
        firstName: json['first_name'] as String?,
        lastName: json['last_name'] as String?,
        bio: json['bio'] as String?,
        location: json['location'] as String?,
        portfolioUrl: json['portfolio_url'] as String?,
        instagramUsername: json['instagram_username'] as String?,
        twitterUsername: json['twitter_username'] as String?,
        profileImageSmall: json['profile_image_small'] as String,
        profileImageMedium: json['profile_image_medium'] as String,
        profileImageLarge: json['profile_image_large'] as String,
        totalPhotos: (json['total_photos'] as num).toInt(),
        totalLikes: (json['total_likes'] as num).toInt(),
        totalCollections: (json['total_collections'] as num).toInt(),
        totalFreePhotos: (json['total_free_photos'] as num?)?.toInt(),
        totalPromotedPhotos:
            (json['total_promoted_photos'] as num?)?.toInt(),
        totalIllustrations: (json['total_illustrations'] as num?)?.toInt(),
        totalFreeIllustrations:
            (json['total_free_illustrations'] as num?)?.toInt(),
        totalPromotedIllustrations:
            (json['total_promoted_illustrations'] as num?)?.toInt(),
        acceptedTos: json['accepted_tos'] as bool?,
        forHire: json['for_hire'] as bool?,
        links: json['links'] != null
            ? UserLinks.fromJson(json['links'] as Map<String, dynamic>)
            : null,
        social: json['social'] != null
            ? UserSocial.fromJson(json['social'] as Map<String, dynamic>)
            : null,
        photosPreview: (json['photos_preview'] as List<dynamic>?)
                ?.map((p) =>
                    UserPhotoPreview.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [],
        tags: json['tags'] != null
            ? UserTags.fromJson(json['tags'] as Map<String, dynamic>)
            : null,
        allowMessages: json['allow_messages'] as bool?,
        followedByUser: json['followed_by_user'] as bool?,
        numericId: (json['numeric_id'] as num?)?.toInt(),
        downloads: (json['downloads'] as num?)?.toInt(),
        meta: json['meta'] != null
            ? UserMeta.fromJson(json['meta'] as Map<String, dynamic>)
            : null,
      );
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

  Map<String, dynamic> toJson() => {
        'self': self,
        'html': html,
        'photos': photos,
        'likes': likes,
      };

  factory UserLinks.fromJson(Map<String, dynamic> json) => UserLinks(
        self: json['self'] as String?,
        html: json['html'] as String?,
        photos: json['photos'] as String?,
        likes: json['likes'] as String?,
      );
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

  Map<String, dynamic> toJson() => {
        'instagram_username': instagramUsername,
        'portfolio_url': portfolioUrl,
        'twitter_username': twitterUsername,
        'paypal_email': paypalEmail,
      };

  factory UserSocial.fromJson(Map<String, dynamic> json) => UserSocial(
        instagramUsername: json['instagram_username'] as String?,
        portfolioUrl: json['portfolio_url'] as String?,
        twitterUsername: json['twitter_username'] as String?,
        paypalEmail: json['paypal_email'] as String?,
      );
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'slug': slug,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'blur_hash': blurHash,
        'asset_type': assetType,
        'thumb_url': thumbUrl,
        'small_url': smallUrl,
        'regular_url': regularUrl,
      };

  factory UserPhotoPreview.fromJson(Map<String, dynamic> json) =>
      UserPhotoPreview(
        id: json['id'] as String,
        slug: json['slug'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
        blurHash: json['blur_hash'] as String?,
        assetType: json['asset_type'] as String?,
        thumbUrl: json['thumb_url'] as String,
        smallUrl: json['small_url'] as String,
        regularUrl: json['regular_url'] as String,
      );
}

class UserTags {
  final List<UserTagItem> custom;
  final List<UserTagItem> aggregated;

  const UserTags({
    this.custom = const [],
    this.aggregated = const [],
  });

  Map<String, dynamic> toJson() => {
        'custom': custom.map((t) => t.toJson()).toList(),
        'aggregated': aggregated.map((t) => t.toJson()).toList(),
      };

  factory UserTags.fromJson(Map<String, dynamic> json) => UserTags(
        custom: (json['custom'] as List<dynamic>?)
                ?.map(
                    (t) => UserTagItem.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [],
        aggregated: (json['aggregated'] as List<dynamic>?)
                ?.map(
                    (t) => UserTagItem.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class UserTagItem {
  final String title;
  final String? type;

  const UserTagItem({
    required this.title,
    this.type,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'type': type,
      };

  factory UserTagItem.fromJson(Map<String, dynamic> json) => UserTagItem(
        title: json['title'] as String,
        type: json['type'] as String?,
      );
}

class UserMeta {
  final bool? index;

  const UserMeta({
    this.index,
  });

  Map<String, dynamic> toJson() => {'index': index};

  factory UserMeta.fromJson(Map<String, dynamic> json) => UserMeta(
        index: json['index'] as bool?,
      );
}
