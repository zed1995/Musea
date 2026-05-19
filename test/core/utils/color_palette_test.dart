import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/core/utils/color_palette.dart';

void main() {
  test('generateColorPalette returns seven colors for a valid hex', () {
    final palette = generateColorPalette('#5B7B9A');

    expect(palette, hasLength(7));
    for (final color in palette) {
      expect(color, isA<Color>());
      expect(color.alpha, 255);
    }
  });

  test('generateColorPalette handles hex without hash prefix', () {
    final palette = generateColorPalette('5B7B9A');

    expect(palette, hasLength(7));
  });
}
