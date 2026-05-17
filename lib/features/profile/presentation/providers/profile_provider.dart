import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/domain/entities/user.dart';
import 'package:musea/core/network/providers.dart';
import 'package:musea/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:musea/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:musea/features/profile/domain/repositories/profile_repository.dart';
import 'package:musea/core/errors/failures.dart';

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSourceImpl(ref.watch(dioClientProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(
    remoteDataSource: ref.watch(profileRemoteDataSourceProvider),
  );
});

final userProfileProvider = FutureProvider.family<User, String>((ref, username) async {
  final repository = ref.watch(profileRepositoryProvider);
  final result = await repository.getUserProfile(username);
  return result.fold(
    (failure) => throw _mapFailureToException(failure),
    (user) => user,
  );
});

final userPhotosProvider = FutureProvider.family<List<Photo>, String>((ref, username) async {
  final repository = ref.watch(profileRepositoryProvider);
  final result = await repository.getUserPhotos(username);
  return result.fold(
    (failure) => throw _mapFailureToException(failure),
    (photos) => photos,
  );
});

Exception _mapFailureToException(Failure failure) {
  return failure.when(
    network: (message) => Exception('Network error: $message'),
    server: (statusCode, message) => Exception('Server error ($statusCode): $message'),
    cache: (message) => Exception('Cache error: $message'),
    notFound: (message) => Exception('Not found: $message'),
    unauthorized: (message) => Exception('Unauthorized: $message'),
    rateLimit: (message) => Exception('Rate limit: $message'),
    unknown: (message) => Exception('Error: $message'),
  );
}
