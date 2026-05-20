class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    required this.displayName,
    this.firstName,
    this.lastName,
    this.bio,
    this.location,
    this.email,
    this.instagramUsername,
    this.twitterUsername,
    this.portfolioUrl,
    this.profileImageSmall,
    required this.profileImageMedium,
    this.profileImageLarge,
    required this.totalPhotos,
    required this.totalLikes,
    required this.totalCollections,
    this.downloads,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      email: json['email'] as String?,
      instagramUsername: json['instagramUsername'] as String?,
      twitterUsername: json['twitterUsername'] as String?,
      portfolioUrl: json['portfolioUrl'] as String?,
      profileImageSmall: json['profileImageSmall'] as String?,
      profileImageMedium: json['profileImageMedium'] as String? ?? '',
      profileImageLarge: json['profileImageLarge'] as String?,
      totalPhotos: (json['totalPhotos'] as num?)?.toInt() ?? 0,
      totalLikes: (json['totalLikes'] as num?)?.toInt() ?? 0,
      totalCollections: (json['totalCollections'] as num?)?.toInt() ?? 0,
      downloads: (json['downloads'] as num?)?.toInt(),
    );
  }

  final String id;
  final String username;
  final String displayName;
  final String? firstName;
  final String? lastName;
  final String? bio;
  final String? location;
  final String? email;
  final String? instagramUsername;
  final String? twitterUsername;
  final String? portfolioUrl;
  final String? profileImageSmall;
  final String profileImageMedium;
  final String? profileImageLarge;
  final int totalPhotos;
  final int totalLikes;
  final int totalCollections;
  final int? downloads;

  AuthUser copyWith({
    String? id,
    String? username,
    String? displayName,
    String? firstName,
    String? lastName,
    String? bio,
    String? location,
    String? email,
    String? instagramUsername,
    String? twitterUsername,
    String? portfolioUrl,
    String? profileImageSmall,
    String? profileImageMedium,
    String? profileImageLarge,
    int? totalPhotos,
    int? totalLikes,
    int? totalCollections,
    int? downloads,
  }) {
    return AuthUser(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      email: email ?? this.email,
      instagramUsername: instagramUsername ?? this.instagramUsername,
      twitterUsername: twitterUsername ?? this.twitterUsername,
      portfolioUrl: portfolioUrl ?? this.portfolioUrl,
      profileImageSmall: profileImageSmall ?? this.profileImageSmall,
      profileImageMedium: profileImageMedium ?? this.profileImageMedium,
      profileImageLarge: profileImageLarge ?? this.profileImageLarge,
      totalPhotos: totalPhotos ?? this.totalPhotos,
      totalLikes: totalLikes ?? this.totalLikes,
      totalCollections: totalCollections ?? this.totalCollections,
      downloads: downloads ?? this.downloads,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'displayName': displayName,
      'firstName': firstName,
      'lastName': lastName,
      'bio': bio,
      'location': location,
      'email': email,
      'instagramUsername': instagramUsername,
      'twitterUsername': twitterUsername,
      'portfolioUrl': portfolioUrl,
      'profileImageSmall': profileImageSmall,
      'profileImageMedium': profileImageMedium,
      'profileImageLarge': profileImageLarge,
      'totalPhotos': totalPhotos,
      'totalLikes': totalLikes,
      'totalCollections': totalCollections,
      'downloads': downloads,
    };
  }
}
