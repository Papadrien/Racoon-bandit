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
    if (!context.mounted) return;
    await Navigator.pushNamed(context, AppRoutes.onboarding);
  }

  Future<void> _debugSimulateReward() async {
    if (!context.mounted) return;
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
    if (!context.mounted) return;
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
        minimum: const EdgeInsets.symmetric(horizontal: 4),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // ── Son & Vibrations ──────────────────────────────────────────
            const _SectionLabel(label: 'Audio & Retours'),
            _SettingsCard(
              children: [
                _ToggleTile(
                  icon: Icons.volume_up_rounded,
                  label: 'Sons',
                  subtitle: 'Effets sonores du jeu',
                  value: _soundEnabled,
                  onChanged: _onSoundChanged,
                ),
                const _CardDivider(),
                _ToggleTile(
                  icon: Icons.vibration_rounded,
                  label: 'Vibrations',
                  subtitle: 'Retours haptiques',
                  value: _vibrationEnabled,
                  onChanged: _onVibrationChanged,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Profils & Tutoriel ────────────────────────────────────────
            const _SectionLabel(label: 'Jeu'),
            _SettingsCard(
              children: [
                _NavTile(
                  icon: Icons.person_outline_rounded,
                  label: 'Gestion des profils',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.profiles),
                ),
                const _CardDivider(),
                _NavTile(
                  icon: Icons.school_outlined,
                  label: 'Revoir le tutoriel',
                  onTap: _replayTutorial,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Légal ─────────────────────────────────────────────────────
            const _SectionLabel(label: 'Légal'),
            _SettingsCard(
              children: [
                _NavTile(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Politique de confidentialité',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.privacyPolicy),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ── Section Debug (debug uniquement) ─────────────────────────
            if (kDebugMode) ...[
              _SectionLabel(label: 'Debug', color: Colors.orange),
              _SettingsCard(
                borderColor: Colors.orange.withValues(alpha: 0.3),
                children: [
                  _DebugTile(
                    icon: Icons.emoji_events_outlined,
                    label: 'Simuler récompense',
                    onTap: _debugSimulateReward,
                  ),
                  _CardDivider(color: Colors.orange.withValues(alpha: 0.2)),
                  _DebugTile(
                    icon: Icons.lock_open_rounded,
                    label: 'Débloquer tous les dos',
                    onTap: _debugUnlockAll,
                  ),
                  _CardDivider(color: Colors.orange.withValues(alpha: 0.2)),
                  _DebugTile(
                    icon: Icons.replay_rounded,
                    label: 'Reset onboarding (relancer app)',
                    onTap: () async {
                      await OnboardingService.resetForDebug();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Onboarding reset — relancez l\'app'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],

            // ── Version ───────────────────────────────────────────────────
            const Center(
              child: Text(
                'v1.0.0 — Raccoon Bandit',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Composants internes
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color? color;

  const _SectionLabel({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: (color ?? AppTheme.primary).withValues(alpha: 0.8),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  final Color? borderColor;

  const _SettingsCard({required this.children, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.07),
          width: 1,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _CardDivider extends StatelessWidget {
  final Color? color;
  const _CardDivider({this.color});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      color: color ?? Colors.white.withValues(alpha: 0.07),
      indent: 16,
      endIndent: 16,
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      secondary: Icon(icon, color: AppTheme.primary, size: 22),
      title: Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppTheme.primary,
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: AppTheme.primary, size: 22),
      title: Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
      onTap: onTap,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: Colors.orange, size: 22),
      title: Text(
        label,
        style: const TextStyle(color: Colors.orange, fontSize: 14, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }
}
