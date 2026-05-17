import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/navigation/app_router.dart';
import '../../core/models/reward_unlock.dart';
import '../../core/services/onboarding_service.dart';
import '../../core/services/progression_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/reward_unlock_dialog.dart';

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

  Future<void> _replayTutorial() async {
    if (!mounted) return;
    await Navigator.pushNamed(context, AppRoutes.onboarding);
  }

  Future<void> _debugSimulateReward() async {
    if (!mounted) return;
    const fakeReward = RewardUnlock(
      id: 'debug_reward',
      name: 'Dos Bleu',
      type: RewardType.cardBack,
      assetPath: 'assets/images/cards/card_back_blue.png',
      unlockHint: 'Débloqué après 5 parties jouées !',
    );
    await RewardUnlockDialog.showAll(context, [fakeReward]);
  }

  Future<void> _debugUnlockAll() async {
    await ProgressionService.debugUnlockAll();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tous les dos débloqués !'),
        backgroundColor: Colors.orange,
      ),
    );
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

            // ── Son & Vibrations ──────────────────────────────────────────
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

            // ── Profils ───────────────────────────────────────────────────
            ListTile(
              leading: const Icon(Icons.person_outline, color: AppTheme.primary),
              title: const Text('Gestion des profils'),
              trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
              onTap: () => Navigator.pushNamed(context, AppRoutes.profiles),
            ),
            const Divider(color: AppTheme.textMuted, height: 1),

            // ── Tutoriel (toujours visible) ───────────────────────────────
            ListTile(
              leading: const Icon(Icons.school_outlined, color: AppTheme.primary),
              title: const Text('Revoir le tutoriel'),
              trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
              onTap: _replayTutorial,
            ),
            const Divider(color: AppTheme.textMuted, height: 1),

            const SizedBox(height: 32),

            // ── Section Debug (debug uniquement) ─────────────────────────
            if (kDebugMode) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'DEBUG',
                  style: TextStyle(
                    color: Colors.orange.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              _DebugTile(
                icon: Icons.emoji_events_outlined,
                label: 'Simuler récompense',
                onTap: _debugSimulateReward,
              ),
              const Divider(color: Colors.orange, height: 1, indent: 16, endIndent: 16),
              _DebugTile(
                icon: Icons.lock_open_rounded,
                label: 'Débloquer tous les dos',
                onTap: _debugUnlockAll,
              ),
              const Divider(color: Colors.orange, height: 1, indent: 16, endIndent: 16),
              _DebugTile(
                icon: Icons.replay,
                label: 'Reset onboarding (relancer app)',
                onTap: () async {
                  await OnboardingService.resetForDebug();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Onboarding reset — relancez l\'app'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            // ── Version ───────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
// Widgets internes
// ─────────────────────────────────────────────────────────────────────────────

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

class _DebugTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DebugTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.orange),
      title: Text(
        label,
        style: const TextStyle(color: Colors.orange, fontSize: 14),
      ),
      onTap: onTap,
    );
  }
}
