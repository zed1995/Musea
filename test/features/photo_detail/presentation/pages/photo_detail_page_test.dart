import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/features/discover/data/models/photo_model.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/presentation/providers/photos_provider.dart';
import 'package:musea/features/photo_detail/presentation/pages/photo_detail_page.dart';
import 'package:musea/features/profile/presentation/providers/profile_provider.dart';

void main() {
  testWidgets('PhotoDetailPage tolerates null numeric fields from detail payload',
      (tester) async {
    final photo = PhotoModel.fromJson({
      'id': 'photo-1',
      'created_at': '2024-01-01T00:00:00Z',
      'width': null,
      'height': null,
      'color': '#FFFFFF',
      'description': 'Quiet light',
      'urls': {
        'raw': 'https://example.com/raw.jpg',
        'full': 'https://example.com/full.jpg',
        'regular': 'https://example.com/regular.jpg',
        'small': 'https://example.com/small.jpg',
        'thumb': 'https://example.com/thumb.jpg',
      },
      'likes': null,
      'downloads': null,
      'views': null,
      'user': {
        'id': 'user-1',
        'username': 'paula',
        'name': 'Paula Poeira',
        'profile_image': {
          'small': 'https://example.com/small-profile.jpg',
          'medium': 'https://example.com/medium-profile.jpg',
          'large': 'https://example.com/large-profile.jpg',
        },
        'total_photos': null,
        'total_likes': null,
        'total_collections': null,
      },
      'exif': {
        'iso': null,
      },
      'location': {
        'city': 'Paris',
        'country': 'France',
        'position': {
          'latitude': null,
          'longitude': null,
        },
      },
      'tags': const [
        {'title': 'editorial'}
      ],
    }).toEntity();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          photoDetailProvider('photo-1').overrideWith((ref) => photo),
          userPhotosProvider('paula').overrideWith((ref) => <Photo>[]),
        ],
        child: const MaterialApp(
          home: PhotoDetailPage(photoId: 'photo-1'),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Paula Poeira'), findsOneWidget);
    expect(find.text('Quiet light'), findsOneWidget);
    expect(find.text('Download Free'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
