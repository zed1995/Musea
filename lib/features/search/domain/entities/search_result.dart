import 'package:musea/features/collections/domain/entities/collection.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';

class SearchPhotosResult {
  const SearchPhotosResult({
    required this.total,
    required this.totalPages,
    required this.results,
  });

  final int total;
  final int totalPages;
  final List<Photo> results;
}

class SearchCollectionsResult {
  const SearchCollectionsResult({
    required this.total,
    required this.totalPages,
    required this.results,
  });

  final int total;
  final int totalPages;
  final List<Collection> results;
}

class SearchUsersResult {
  const SearchUsersResult({
    required this.total,
    required this.totalPages,
    required this.results,
  });

  final int total;
  final int totalPages;
  final List<User> results;
}
