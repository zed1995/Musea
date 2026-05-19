import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/features/discover/data/models/photo_model.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';
import 'package:musea/features/discover/presentation/providers/photos_provider.dart';
import 'package:musea/features/photo_detail/presentation/pages/photo_detail_page.dart';
import 'package:musea/features/photo_detail/presentation/widgets/color_palette_bar.dart';
import 'package:musea/features/profile/presentation/providers/profile_provider.dart';

void main() {
  Photo buildPhoto({
    required String id,
    required String username,
    required String name,
    required String color,
    List<Map<String, String>> tags = const [],
    String make = 'Sony',
    String model = 'A7 III',
  }) {
    return PhotoModel.fromJson({
      'id': id,
      'created_at': '2024-01-01T00:00:00Z',
      'width': 1200,
      'height': 1600,
      'color': color,
      'description': 'Quiet light',
      'urls': {
        'raw': 'https://example.com/$id-raw.jpg',
        'full': 'https://example.com/$id-full.jpg',
        'regular': 'https://example.com/$id-regular.jpg',
        'small': 'https://example.com/$id-small.jpg',
        'thumb': 'https://example.com/$id-thumb.jpg',
      },
      'likes': 1284,
      'downloads': 12000,
      'views': 52300,
      'user': {
        'id': 'user-$id',
        'username': username,
        'name': name,
        'profile_image': {
          'small': 'https://example.com/small-profile.jpg',
          'medium': 'https://example.com/medium-profile.jpg',
          'large': 'https://example.com/large-profile.jpg',
        },
        'total_photos': 20,
        'total_likes': 30,
        'total_collections': 2,
      },
      'exif': {
        'make': make,
        'model': model,
        'aperture': '2.8',
        'exposure_time': '1/250',
        'focal_length': '35mm',
        'iso': 400,
      },
      'location': {
        'city': 'Kyoto',
        'country': 'Japan',
        'position': {
          'latitude': 35.0116,
          'longitude': 135.7681,
        },
      },
      'tags': tags,
    }).toEntity();
  }

  testWidgets(
      'PhotoDetailPage tolerates null numeric fields from detail payload',
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
        'make': 'VeryLongCameraBrandName',
        'model': 'SuperDetailedMirrorlessBodyEdition',
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

  testWidgets(
      'PhotoDetailPage renders color palette and long exif can open full text',
      (tester) async {
    final photo = buildPhoto(
      id: 'photo-main',
      username: 'paula',
      name: 'Paula Poeira',
      color: '#5B7B9A',
      tags: const [
        {'title': 'Kyoto'},
        {'title': 'Temple'},
        {'title': 'Autumn'},
      ],
      make: 'VeryLongCameraBrandName',
      model: 'SuperDetailedMirrorlessBodyEdition',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          photoDetailProvider('photo-main').overrideWith((ref) => photo),
          userPhotosProvider('paula').overrideWith((ref) => <Photo>[]),
        ],
        child: const MaterialApp(
          home: PhotoDetailPage(photoId: 'photo-main'),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('COLOR PALETTE'), findsOneWidget);
    expect(find.byType(ColorPaletteSection), findsOneWidget);

    await tester.tap(
      find
          .text('VeryLongCameraBrandName SuperDetailedMirrorlessBodyEdition')
          .first,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text('VeryLongCameraBrandName SuperDetailedMirrorlessBodyEdition'),
      findsAtLeastNWidgets(2),
    );
    expect(find.text('Camera'), findsAtLeastNWidgets(2));
  });
}
