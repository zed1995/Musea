import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musea/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:musea/features/settings/presentation/providers/settings_provider.dart';

void main() {
  group('AppThemeModeX.toFlutterThemeMode', () {
    test('system maps to ThemeMode.system', () {
      expect(AppThemeMode.system.toFlutterThemeMode(), ThemeMode.system);
    });
    test('light maps to ThemeMode.light', () {
      expect(AppThemeMode.light.toFlutterThemeMode(), ThemeMode.light);
    });
    test('dark maps to ThemeMode.dark', () {
      expect(AppThemeMode.dark.toFlutterThemeMode(), ThemeMode.dark);
    });
  });
}
