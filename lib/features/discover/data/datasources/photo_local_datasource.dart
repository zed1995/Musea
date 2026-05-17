import 'package:hive_flutter/hive_flutter.dart';
import 'package:musea/features/discover/data/models/photo_model.dart';

abstract class PhotoLocalDataSource {
  Future<void> cachePhotos(List<PhotoModel> photos);
  Future<List<PhotoModel>> getCachedPhotos();
  Future<void> cachePhoto(PhotoModel photo);
  Future<PhotoModel?> getCachedPhoto(String id);
  Future<void> clearCache();
}

class PhotoLocalDataSourceImpl implements PhotoLocalDataSource {
  static const String _boxName = 'photos_cache';
  Box<dynamic>? _box;

  Future<Box<dynamic>> get box async {
    _box ??= await Hive.openBox(_boxName);
    return _box!;
  }

  @override
  Future<void> cachePhotos(List<PhotoModel> photos) async {
    final photoBox = await box;
    for (final photo in photos) {
      await photoBox.put(photo.id, photo.toJson());
    }
  }

  @override
  Future<List<PhotoModel>> getCachedPhotos() async {
    final photoBox = await box;
    final photos = photoBox.values.toList();
    return photos
        .map((json) => PhotoModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> cachePhoto(PhotoModel photo) async {
    final photoBox = await box;
    await photoBox.put(photo.id, photo.toJson());
  }

  @override
  Future<PhotoModel?> getCachedPhoto(String id) async {
    final photoBox = await box;
    final json = photoBox.get(id);
    if (json == null) return null;
    return PhotoModel.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<void> clearCache() async {
    final photoBox = await box;
    await photoBox.clear();
  }
}
