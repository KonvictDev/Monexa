import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/settings_repository.dart';

/// Watches theme changes from Hive and updates app theme live.
final themeSettingsProvider = StreamProvider<ThemeSettings>((ref) async* {
  final settingsRepo = ref.read(settingsRepositoryProvider);
  final boxListenable =
  settingsRepo.getListenable(keys: ['appThemeMode', 'appColorSeed']);

  final controller = StreamController<ThemeSettings>();

  void emitCurrent() {
    final themeString =
    settingsRepo.get('appThemeMode', defaultValue: 'system');
    final themeMode = ThemeMode.values.firstWhere(
          (e) => e.name == themeString,
      orElse: () => ThemeMode.system,
    );

    final colorValue =
    settingsRepo.get('appColorSeed', defaultValue: Colors.blue.value);
    final colorSeed = Color(colorValue);

    controller.add(ThemeSettings(themeMode: themeMode, colorSeed: colorSeed));
  }

  emitCurrent(); // Emit initial theme
  boxListenable.addListener(emitCurrent);

  ref.onDispose(() {
    boxListenable.removeListener(emitCurrent);
    controller.close();
  });

  yield* controller.stream;
});

class ThemeSettings {
  final ThemeMode themeMode;
  final Color colorSeed;

  ThemeSettings({required this.themeMode, required this.colorSeed});
}
