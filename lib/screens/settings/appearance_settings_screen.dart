import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/settings_repository.dart';

class AppearanceSettingsScreen extends ConsumerStatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  ConsumerState<AppearanceSettingsScreen> createState() =>
      _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState
    extends ConsumerState<AppearanceSettingsScreen> {
  late ThemeMode _currentMode;
  late Color _currentColor;
  late ThemeMode _savedMode;
  late Color _savedColor;

  final List<Color> _availableColors = [
    Colors.brown,
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.orange,
  ];

  @override
  void initState() {
    super.initState();
    final repo = ref.read(settingsRepositoryProvider);
    final themeString = repo.get('appThemeMode', defaultValue: 'system');
    final colorValue = repo.get('appColorSeed', defaultValue: Colors.blue.value);

    _currentMode = ThemeMode.values.firstWhere(
          (e) => e.name == themeString,
      orElse: () => ThemeMode.system,
    );
    _currentColor = Color(colorValue);
    _savedMode = _currentMode;
    _savedColor = _currentColor;
  }

  void _applySettings() async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.put('appThemeMode', _currentMode.name);
    await repo.put('appColorSeed', _currentColor.value);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Theme applied!')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasChanges = _currentMode != _savedMode ||
        _currentColor.value != _savedColor.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Appearance'),

      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theme Mode', style: Theme.of(context).textTheme.titleMedium),
                const Divider(height: 24),
                for (var mode in ThemeMode.values)
                  RadioListTile<ThemeMode>(
                    title: Text(
                      mode.name[0].toUpperCase() + mode.name.substring(1),
                    ),
                    value: mode,
                    groupValue: _currentMode,
                    onChanged: (v) => setState(() => _currentMode = v!),
                  ),
                const SizedBox(height: 24),
                Text('Accent Color', style: Theme.of(context).textTheme.titleMedium),
                const Divider(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _availableColors.map((color) {
                    return GestureDetector(
                      onTap: () => setState(() => _currentColor = color),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: color,
                        child: _currentColor.value == color.value
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),
                Center(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Apply Changes'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _applySettings, // or _saveProfileSettings / _saveFinancialSettings etc.
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
