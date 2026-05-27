import 'package:flutter/material.dart';
import 'package:raccoon_bandit/l10n/app_localizations.dart';

import '../../core/ui/app_colors.dart';
import '../../core/ui/app_shadows.dart';
import '../../core/ui/app_spacing.dart';
import 'widgets/settings_secondary_header.dart';

/// Écran politique de confidentialité — refonte UI étape 6.1A.
/// Style cohérent avec le Home Screen : casual premium, beige, stickers discrets.
/// Le contenu juridique n'est PAS modifié.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sw = MediaQuery.sizeOf(context).width;
    final hPad = sw < 360 ? AppSpacing.hPadNarrow : AppSpacing.hPadNormal;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Stickers décoratifs fond ─────────────────────────────────────
          const Positioned.fill(child: _PrivacyBackgroundStickers()),

          // ── Contenu ─────────────────────────────────────────────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header secondaire unifié ─────────────────────────────
                SettingsSecondaryHeader(title: l10n.privacyTitle),

                // ── Scrollable ───────────────────────────────────────────
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      hPad,
                      AppSpacing.lg,
                      hPad,
                      AppSpacing.xxl,
                    ),
                    children: [
                      // ── Hero icon + titre ────────────────────────────
                      _PrivacyHero(
                        heading: l10n.privacyHeading,
                        appName: l10n.privacyAppName,
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // ── Carte contenu légal ──────────────────────────
                      _PolicyCard(
                        children: [
                          _PolicySection(
                            icon: Icons.storage_outlined,
                            title: l10n.privacySection1Title,
                            content: l10n.privacySection1Content,
                          ),
                          const _PolicyDivider(),
                          _PolicySection(
                            icon: Icons.ad_units_outlined,
                            title: l10n.privacySection2Title,
                            content: l10n.privacySection2Content,
                          ),
                          const _PolicyDivider(),
                          _PolicySection(
                            icon: Icons.mail_outline_rounded,
                            title: l10n.privacySection3Title,
                            content: l10n.privacySection3Content,
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // ── Note placeholder ─────────────────────────────
                      Center(
                        child: Text(
                          l10n.privacyComingSoon,
                          style: TextStyle(
                            color: AppColors.textMuted.withValues(alpha: 0.6),
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),
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
// Hero — icône centrale + titre
// ─────────────────────────────────────────────────────────────────────────────

class _PrivacyHero extends StatelessWidget {
  final String heading;
  final String appName;

  const _PrivacyHero({required this.heading, required this.appName});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.md),
        // Icône sticker
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.stickerWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            boxShadow: AppShadows.floating,
          ),
          child: const Icon(
            Icons.privacy_tip_outlined,
            color: AppColors.violet,
            size: 36,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Titre
        Text(
          heading,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        // Sous-titre app name
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.violet.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          ),
          child: Text(
            appName,
            style: const TextStyle(
              color: AppColors.violet,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Carte légal — surface blanche flottante
// ─────────────────────────────────────────────────────────────────────────────

class _PolicyCard extends StatelessWidget {
  final List<Widget> children;

  const _PolicyCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.stickerWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
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
// Section légale — icône + titre + contenu
// ─────────────────────────────────────────────────────────────────────────────

class _PolicySection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _PolicySection({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icône
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.violet.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
            child: Icon(icon, color: AppColors.violet, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          // Texte
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  content,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    height: 1.55,
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
// Séparateur interne de carte
// ─────────────────────────────────────────────────────────────────────────────

class _PolicyDivider extends StatelessWidget {
  const _PolicyDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      color: AppColors.stickerWarm,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stickers décoratifs fond — discrets
// ─────────────────────────────────────────────────────────────────────────────

class _PrivacyBackgroundStickers extends StatelessWidget {
  const _PrivacyBackgroundStickers();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        // Sapin haut-gauche
        Positioned(
          left: -w * 0.04,
          top: h * 0.06,
          child: Transform.rotate(
            angle: -0.1,
            child: Image.asset(
              'assets/images/sticker_pine_tree.png',
              width: w * 0.16,
              opacity: const AlwaysStoppedAnimation(0.35),
            ),
          ),
        ),
        // Pomme de pin bas-droite
        Positioned(
          right: w * 0.02,
          top: h * 0.74,
          child: Transform.rotate(
            angle: 0.20,
            child: Image.asset(
              'assets/images/sticker_pine_cone.png',
              width: w * 0.09,
              opacity: const AlwaysStoppedAnimation(0.30),
            ),
          ),
        ),
      ],
    );
  }
}
