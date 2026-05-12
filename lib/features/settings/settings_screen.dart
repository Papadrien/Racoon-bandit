import 'package:flutter/material.dart';

import '../../core/services/settings_service.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _soundEnabled;
  late bool _vibrationEnabled;

  @override
  void initState() {
    super.initState();
    _soundEnabled = SettingsService.soundEnabled;
    _vibrationEnabled = SettingsService.vibrationEnabled;
  }

  void _onSoundChanged(bool value) {
    setState(() => _soundEnabled = value);
    SettingsService.setSoundEnabled(value);
  }

  void _onVibrationChanged(bool value) {
    setState(() => _vibrationEnabled = value);
    SettingsService.setVibrationEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PARAMÈTRES'),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            const SizedBox(height: 16),
            _SettingTile(
              icon: Icons.volume_up,
              label: 'Sons',
              value: _soundEnabled,
              onChanged: _onSoundChanged,
            ),
            const Divider(color: AppTheme.textMuted, height: 1),
            _SettingTile(
              icon: Icons.vibration,
              label: 'Vibrations',
              value: _vibrationEnabled,
              onChanged: _onVibrationChanged,
            ),
            const Divider(color: AppTheme.textMuted, height: 1),
            const SizedBox(height: 32),
            const Center(
              child: Text(
                'v0.1.0 — Raccoon Bandit',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppTheme.primary),
      title: Text(label),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppTheme.primary,
    );
  }
}
