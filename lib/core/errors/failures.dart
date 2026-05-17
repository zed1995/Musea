import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';

@freezed
class Failure with _$Failure {
  const factory Failure.network({
    required String message,
  }) = NetworkFailure;
  
  const factory Failure.server({
    required int statusCode,
    required String message,
  }) = ServerFailure;
  
  const factory Failure.cache({
    required String message,
  }) = CacheFailure;
  
  const factory Failure.notFound({
    required String message,
  }) = NotFoundFailure;
  
  const factory Failure.unauthorized({
    required String message,
  }) = UnauthorizedFailure;
  
  const factory Failure.rateLimit({
    required String message,
  }) = RateLimitFailure;
  
  const factory Failure.unknown({
    required String message,
  }) = UnknownFailure;
}
