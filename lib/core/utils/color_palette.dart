import 'package:flutter/material.dart';

/// Builds a [count]-swatch palette from a single Unsplash [hex] color (e.g. `#5B7B9A`).
List<Color> generateColorPalette(String hex, {int count = 7}) {
  final base = _parseHexColor(hex);
  final hsl = HSLColor.fromColor(base);

  return List.generate(count, (index) {
    final t = count <= 1 ? 0.0 : index / (count - 1);
    final hueShift = (index - count ~/ 2) * 22.0;
    final lightness = (0.32 + t * 0.38).clamp(0.28, 0.72);
    final saturation = (hsl.saturation * (0.72 + (index % 3) * 0.12)).clamp(0.18, 0.95);

    return HSLColor.fromAHSL(
      1,
      (hsl.hue + hueShift) % 360,
      saturation,
      lightness,
    ).toColor();
  });
}

Color _parseHexColor(String hex) {
  final normalized = hex.trim().replaceFirst('#', '');
  if (normalized.length == 6) {
    return Color(int.parse('FF$normalized', radix: 16));
  }
  if (normalized.length == 8) {
    return Color(int.parse(normalized, radix: 16));
  }
  return const Color(0xFF71717A);
}
