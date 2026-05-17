class User {
  final String id;
  final String username;
  final String name;
  final String? bio;
  final String? portfolioUrl;
  final String profileImageSmall;
  final String profileImageMedium;
  final String profileImageLarge;
  final int totalPhotos;
  final int totalLikes;
  final int totalCollections;

  const User({
    required this.id,
    required this.username,
    required this.name,
    this.bio,
    this.portfolioUrl,
    required this.profileImageSmall,
    required this.profileImageMedium,
    required this.profileImageLarge,
    required this.totalPhotos,
    required this.totalLikes,
    required this.totalCollections,
  });
}
