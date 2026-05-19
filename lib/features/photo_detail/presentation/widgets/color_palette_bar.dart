import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musea/core/utils/color_palette.dart';

class ColorPaletteSection extends StatelessWidget {
  const ColorPaletteSection({super.key, required this.hexColor});

  final String hexColor;

  @override
  Widget build(BuildContext context) {
    final palette = generateColorPalette(hexColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'COLOR PALETTE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF71717A),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    spreadRadius: 0,
                    blurRadius: 0,
                    offset: Offset.zero,
                  ),
                ],
                border: Border.all(color: const Color(0x0D000000)),
              ),
              child: SizedBox(
                height: 34,
                width: double.infinity,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final color in palette)
                      Expanded(
                        child: _PaletteSwatch(color: color),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PaletteSwatch extends StatelessWidget {
  const _PaletteSwatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final r = color.red;
    final g = color.green;
    final b = color.blue;
    final hex =
        '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'
            .toUpperCase();

    return Semantics(
      label: hex,
      button: true,
      child: GestureDetector(
        onTap: () {
          Clipboard.setData(ClipboardData(text: hex));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Copied $hex'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: ColoredBox(color: color),
      ),
    );
  }
}
