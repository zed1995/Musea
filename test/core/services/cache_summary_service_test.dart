import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:musea/core/services/cache_summary_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('formats bytes into compact labels', () {
    expect(CacheSummaryService.formatBytes(0), '0 B');
    expect(CacheSummaryService.formatBytes(128), '128 B');
    expect(CacheSummaryService.formatBytes(2048), '2 KB');
    expect(CacheSummaryService.formatBytes(3 * 1024 * 1024), '3 MB');
  });

  test('computes directory size recursively', () async {
    final root = await Directory.systemTemp.createTemp(
      'musea_cache_summary_service_test',
    );
    final nested = Directory('${root.path}/nested')..createSync();
    File('${root.path}/a.bin').writeAsBytesSync(List<int>.filled(5, 1));
    File('${nested.path}/b.bin').writeAsBytesSync(List<int>.filled(7, 1));

    final bytes = await CacheSummaryService.directorySize(root);

    expect(bytes, 12);

    await root.delete(recursive: true);
  });
}
