import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/shared/widgets/progressive_network_photo.dart';

void main() {
  testWidgets('shows thumb first and keeps final image hidden until ready',
      (tester) async {
    final thumbProvider = _ControlledImageProvider();
    final fullProvider = _ControlledImageProvider();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProgressiveNetworkPhoto(
            thumbUrl: 'thumb',
            imageUrl: 'full',
            imageProviderBuilder: (url) =>
                url == 'thumb' ? thumbProvider : fullProvider,
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('progressive-thumb-layer')), findsNothing);
    expect(find.byKey(const ValueKey('progressive-full-layer')), findsNothing);

    thumbProvider.complete();
    await tester.pump();

    expect(find.byKey(const ValueKey('progressive-thumb-layer')), findsOneWidget);
    expect(find.byKey(const ValueKey('progressive-full-layer')), findsNothing);
  });

  testWidgets('reveals the final image and removes thumb after animation',
      (tester) async {
    final thumbProvider = _ControlledImageProvider();
    final fullProvider = _ControlledImageProvider();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProgressiveNetworkPhoto(
            thumbUrl: 'thumb',
            imageUrl: 'full',
            revealDuration: const Duration(milliseconds: 100),
            imageProviderBuilder: (url) =>
                url == 'thumb' ? thumbProvider : fullProvider,
          ),
        ),
      ),
    );

    thumbProvider.complete();
    await tester.pump();

    fullProvider.complete();
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('progressive-full-layer')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byKey(const ValueKey('progressive-thumb-layer')), findsNothing);
  });
}

class _ControlledImageProvider extends ImageProvider<_ControlledImageProvider> {
  _ControlledImageProvider();

  final Completer<ImageInfo> _imageCompleter = Completer<ImageInfo>();

  void complete() {
    if (_imageCompleter.isCompleted) return;

    _imageCompleter.complete(
      Future<ImageInfo>.sync(() async {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.drawRect(
          const Rect.fromLTWH(0, 0, 2, 2),
          Paint()..color = const Color(0xFFFFFFFF),
        );
        final picture = recorder.endRecording();
        final image = await picture.toImage(2, 2);
        return ImageInfo(image: image);
      }),
    );
  }

  @override
  Future<_ControlledImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_ControlledImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _ControlledImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return OneFrameImageStreamCompleter(_imageCompleter.future);
  }
}
