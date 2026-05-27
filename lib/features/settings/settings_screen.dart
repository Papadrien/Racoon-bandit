import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:raccoon_bandit/l10n/app_localizations.dart';

import '../../core/navigation/app_router.dart';
import '../../core/models/reward_unlock.dart';
import '../../core/services/onboarding_service.dart';
import '../../core/services/progression_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/app_shadows.dart';
import '../../core/ui/app_spacing.dart';
import '../../widgets/reward_unlock_dialog.dart';
import 'widgets/settings_secondary_header.dart';

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
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.settingsDebugUnlockAll),
        backgroundColor: AppColors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sw = MediaQuery.sizeOf(context).width;
    final hPad = sw < 360 ? AppSpacing.hPadNarrow : AppSpacing.hPadNormal;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Stickers décoratifs fond ──────────────────────────────────
          const Positioned.fill(child: _SettingsBackgroundStickers()),

          // ── Contenu principal ─────────────────────────────────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header secondaire unifié ──────────────────────────
                SettingsSecondaryHeader(title: l10n.settingsTitle),

                // ── Body scrollable ───────────────────────────────────
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      hPad,
                      AppSpacing.lg,
                      hPad,
                      AppSpacing.xxl,
                    ),
                    children: [
                      // ── Son & Vibrations ──────────────────────────
                      _SectionLabel(label: l10n.settingsSectionAudio),
                      const SizedBox(height: AppSpacing.sm),
                      _SettingsCard(
                        children: [
                          _ToggleTile(
                            icon: Icons.volume_up_rounded,
                            label: l10n.settingsSoundLabel,
                            subtitle: l10n.settingsSoundSubtitle,
                            value: _soundEnabled,
                            onChanged: _onSoundChanged,
                          ),
                          const _CardDivider(),
                          _ToggleTile(
                            icon: Icons.vibration_rounded,
                            label: l10n.settingsVibrationLabel,
                            subtitle: l10n.settingsVibrationSubtitle,
                            value: _vibrationEnabled,
                            onChanged: _onVibrationChanged,
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // ── Jeu ────────────────────────────────────────
                      _SectionLabel(label: l10n.settingsSectionGame),
                      const SizedBox(height: AppSpacing.sm),
                      _SettingsCard(
                        children: [
                          _NavTile(
                            icon: Icons.person_outline_rounded,
                            label: l10n.settingsProfilesLabel,
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.profiles,
                            ),
                          ),
                          const _CardDivider(),
                          _NavTile(
                            icon: Icons.school_outlined,
                            label: l10n.settingsTutorialLabel,
                            onTap: _replayTutorial,
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // ── Légal ──────────────────────────────────────
                      _SectionLabel(label: l10n.settingsSectionLegal),
                      const SizedBox(height: AppSpacing.sm),
                      _SettingsCard(
                        children: [
                          _NavTile(
                            icon: Icons.privacy_tip_outlined,
                            label: l10n.settingsPrivacyLabel,
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.privacyPolicy,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // ── Debug (debug uniquement) ───────────────────
                      if (kDebugMode) ...[
                        const _SectionLabel(
                          label: 'Debug',
                          isDebug: true,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _SettingsCard(
                          isDebug: true,
                          children: [
                            _DebugTile(
                              icon: Icons.emoji_events_outlined,
                              label: 'Simuler récompense',
                              onTap: _debugSimulateReward,
                            ),
                            _CardDivider(
                              color: Colors.orange.withValues(alpha: 0.2),
                            ),
                            _DebugTile(
                              icon: Icons.lock_open_rounded,
                              label: 'Débloquer tous les dos',
                              onTap: _debugUnlockAll,
                            ),
                            _CardDivider(
                              color: Colors.orange.withValues(alpha: 0.2),
                            ),
                            _DebugTile(
                              icon: Icons.replay_rounded,
                              label: 'Reset onboarding (relancer app)',
                              onTap: () async {
                                await OnboardingService.resetForDebug();
                                if (!context.mounted) return;
                                final l = AppLocalizations.of(context)!;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      l.settingsDebugOnboardingReset,
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                      ],

                      // ── Version ────────────────────────────────────
                      Center(
                        child: Text(
                          l10n.settingsVersionLabel,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Section label — texte small caps discret
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDebug;

  const _SectionLabel({required this.label, this.isDebug = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: isDebug
              ? Colors.orange.withValues(alpha: 0.85)
              : AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Carte settings — surface blanche flottante
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  final bool isDebug;

  const _SettingsCard({required this.children, this.isDebug = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.stickerWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: isDebug
            ? Border.all(
                color: Colors.orange.withValues(alpha: 0.3),
                width: 1.2,
              )
            : null,
        boxShadow: AppShadows.floating,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Séparateur interne de carte
// ─────────────────────────────────────────────────────────────────────────────

class _CardDivider extends StatelessWidget {
  final Color? color;

  const _CardDivider({this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      color: color ?? AppColors.stickerWarm,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Toggle tile — son / vibrations
// ─────────────────────────────────────────────────────────────────────────────

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
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          // Icône dans cercle coloré discret
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
            child: Icon(icon, color: AppColors.orange, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          // Label + sous-titre
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Toggle custom
          _ModernSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Switch moderne — pill orange/gris, style cohérent
// ─────────────────────────────────────────────────────────────────────────────

class _ModernSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ModernSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 28,
        decoration: BoxDecoration(
          color: value
              ? AppColors.orange
              : AppColors.stickerWarm,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppShadows.soft,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: AppColors.stickerWhite,
                shape: BoxShape.circle,
                boxShadow: AppShadows.soft,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nav tile — profils, tutoriel, privacy
// ─────────────────────────────────────────────────────────────────────────────

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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      splashColor: AppColors.orange.withValues(alpha: 0.08),
      highlightColor: AppColors.orange.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            // Icône
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.violet.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: Icon(icon, color: AppColors.violet, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            // Label
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Chevron dans cercle discret
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.stickerWarm,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Debug tile
// ─────────────────────────────────────────────────────────────────────────────

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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      splashColor: Colors.orange.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: Icon(icon, color: Colors.orange, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stickers décoratifs fond — discrets, bords uniquement
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsBackgroundStickers extends StatelessWidget {
  const _SettingsBackgroundStickers();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        // Sapin haut-droite
        Positioned(
          right: -w * 0.05,
          top: h * 0.04,
          child: Transform.rotate(
            angle: 0.08,
            child: Image.asset(
              'assets/images/sticker_pine_tree.png',
              width: w * 0.18,
              opacity: const AlwaysStoppedAnimation(0.40),
            ),
          ),
        ),
        // Pomme de pin bas-gauche
        Positioned(
          left: w * 0.01,
          top: h * 0.72,
          child: Transform.rotate(
            angle: -0.18,
            child: Image.asset(
              'assets/images/sticker_pine_cone.png',
              width: w * 0.10,
              opacity: const AlwaysStoppedAnimation(0.35),
            ),
          ),
        ),
        // Cabane bas-droite
        Positioned(
          right: -w * 0.02,
          top: h * 0.80,
          child: Transform.rotate(
            angle: 0.06,
            child: Image.asset(
              'assets/images/sticker_cabin.png',
              width: w * 0.15,
              opacity: const AlwaysStoppedAnimation(0.35),
            ),
          ),
        ),
      ],
    );
  }
}
