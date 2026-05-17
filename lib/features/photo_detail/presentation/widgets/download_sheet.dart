import 'package:flutter/material.dart';
import 'package:musea/core/theme/text_styles.dart';
import 'package:musea/features/discover/domain/entities/photo.dart';

class DownloadOption {
  final String label;
  final String url;
  final String sizeLabel;

  const DownloadOption({
    required this.label,
    required this.url,
    required this.sizeLabel,
  });
}

class DownloadSheet extends StatelessWidget {
  final Photo photo;

  const DownloadSheet({super.key, required this.photo});

  static Future<DownloadOption?> show(BuildContext context, Photo photo) {
    return showModalBottomSheet<DownloadOption>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DownloadSheet(photo: photo),
    );
  }

  List<DownloadOption> get _options => [
    DownloadOption(label: 'Raw', url: photo.urlRaw, sizeLabel: 'Original'),
    DownloadOption(label: 'Full', url: photo.urlFull, sizeLabel: 'Full resolution'),
    DownloadOption(label: 'Regular', url: photo.urlRegular, sizeLabel: 'Standard quality'),
    DownloadOption(label: 'Small', url: photo.urlSmall, sizeLabel: 'Small size'),
    DownloadOption(label: 'Thumb', url: photo.urlThumb, sizeLabel: 'Thumbnail'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text('Choose Size', style: AppTextStyles.heading3),
            ),
            const SizedBox(height: 16),
            ..._options.map((option) => ListTile(
              leading: const Icon(Icons.image_outlined),
              title: Text(option.label, style: AppTextStyles.bodyLarge),
              subtitle: Text(option.sizeLabel, style: AppTextStyles.caption),
              onTap: () => Navigator.of(context).pop(option),
            )),
          ],
        ),
      ),
    );
  }
}
