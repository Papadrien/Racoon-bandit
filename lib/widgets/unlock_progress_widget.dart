import 'package:flutter/material.dart';
import 'package:raccoon_bandit/l10n/app_localizations.dart';

import '../core/models/card_back_config.dart';
import '../core/services/progression_service.dart';
import '../core/ui/app_colors.dart';
import '../core/ui/app_shadows.dart';
import '../core/ui/app_spacing.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UnlockProgressWidget — progression vers le prochain dos de carte
// ─────────────────────────────────────────────────────────────────────────────
//
// Affiché dans ResultScreen. Style sticker blanc cassé, cohérent avec
// les autres cartes de l'écran. Fond clair (pas sombre).
//
// Disposition :
//   - En-tête : icône 🎴 + titre
//   - Corps : [dos actif] [barre animée + compte] [prochain dos verrouillé]
//   - Cas "tous débloqués" : badge celebration plein écran de la carte.

class UnlockProgressWidget extends StatefulWidget {
  const UnlockProgressWidget({super.key});

  @override
  State<UnlockProgressWidget> createState() => _UnlockProgressWidgetState();
}

class _UnlockProgressWidgetState extends State<UnlockProgressWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _barAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _barAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFF6D00);
    final progression = ProgressionService.progression;
        final totalGames = progression.totalGamesPlayed;
        final unlockedIds = progression.unlockedCardBackIds;
        final allBacks = ProgressionService.cardBacks;

        final unlockedBacks =
            allBacks.where((cb) => unlockedIds.contains(cb.id)).toList();
        final lastUnlocked = unlockedBacks.last;

        final nextBack = allBacks
            .where((cb) => !unlockedIds.contains(cb.id))
            .cast<CardBackConfig?>()
            .firstOrNull;

        // ── Tous débloqués ────────────────────────────────────────────────
        if (nextBack == null) {
          return _AllUnlockedCard(
            accent: accent,
            lastUnlocked: lastUnlocked,
          );
        }

        // ── Calcul progression ────────────────────────────────────────────
        final fromGames = lastUnlocked.requiredGames;
        final toGames = nextBack.requiredGames;
        final range = toGames - fromGames;
        final progress = range > 0
            ? ((totalGames - fromGames) / range).clamp(0.0, 1.0)
            : 1.0;
        final remaining = (toGames - totalGames).clamp(0, toGames);

        return _ProgressCard(
          accent: accent,
          lastUnlocked: lastUnlocked,
          nextBack: nextBack,
          progress: progress,
          barAnimation: _barAnimation,
          totalGames: totalGames,
          toGames: toGames,
          remaining: remaining,
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Carte de progression principale
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.accent,
    required this.lastUnlocked,
    required this.nextBack,
    required this.progress,
    required this.barAnimation,
    required this.totalGames,
    required this.toGames,
    required this.remaining,
  });

  final Color accent;
  final CardBackConfig lastUnlocked;
  final CardBackConfig nextBack;
  final double progress;
  final Animation<double> barAnimation;
  final int totalGames;
  final int toGames;
  final int remaining;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.stickerWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        boxShadow: AppShadows.floating,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── En-tête ───────────────────────────────────────────────────────
          Row(
            children: [
              const Text('🎴', style: TextStyle(fontSize: 16)),
              const SizedBox(width: AppSpacing.xs),
              Text(
                l10n.unlockProgressNext,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Corps : dos + barre + dos ─────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Dos actif (gauche)
              _CardPreview(
                config: lastUnlocked,
                isLocked: false,
                accent: accent,
              ),
              const SizedBox(width: AppSpacing.sm),

              // Barre centrale
              Expanded(
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: barAnimation,
                      builder: (context, _) => _ProgressBar(
                        progress: progress * barAnimation.value,
                        accent: accent,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      remaining == 0
                          ? '$totalGames / $toGames parties'
                          : '$remaining partie${remaining > 1 ? 's' : ''} restante${remaining > 1 ? 's' : ''}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$totalGames / $toGames',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        color: AppColors.textMuted.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Prochain dos verrouillé (droite)
              _CardPreview(
                config: nextBack,
                isLocked: true,
                accent: accent,
                targetGames: nextBack.requiredGames,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Barre de progression — style clair
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress, required this.accent});

  final double progress;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 10,
          width: constraints.maxWidth,
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.shadowSoft,
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.75),
                        accent,
                      ],
                    ),
                    boxShadow: AppShadows.subtleGlow(accent),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Preview d'un dos de carte (débloqué ou verrouillé)
// ─────────────────────────────────────────────────────────────────────────────

class _CardPreview extends StatelessWidget {
  const _CardPreview({
    required this.config,
    required this.isLocked,
    required this.accent,
    this.targetGames,
  });

  final CardBackConfig config;
  final bool isLocked;
  final Color accent;
  final int? targetGames;

  static const double _w = 52;
  static const double _h = 72;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Image de la carte
        Container(
          width: _w,
          height: _h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
            boxShadow: isLocked ? AppShadows.soft : AppShadows.subtleGlow(accent),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image (désaturée si verrouillée)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall - 2),
                child: ColorFiltered(
                  colorFilter: isLocked
                      ? const ColorFilter.matrix([
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0,      0,      0,      0.45, 0,
                        ])
                      : const ColorFilter.mode(
                          Colors.transparent, BlendMode.multiply),
                  child: Image.asset(
                    config.assetPath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, _) => Container(
                      decoration: BoxDecoration(
                        color: config.themeColor
                            .withValues(alpha: isLocked ? 0.25 : 0.75),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSmall),
                      ),
                    ),
                  ),
                ),
              ),

              // Overlay + cadenas si verrouillé
              if (isLocked)
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSmall - 2),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.08),
                          Colors.black.withValues(alpha: 0.42),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          color: AppColors.textMuted,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),

              // Badge coche si débloqué
              if (!isLocked)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.subtleGlow(accent),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 8,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

        // Label
        Text(
          targetGames != null ? '$targetGames' : config.name,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isLocked ? AppColors.textMuted : accent,
          ),
        ),
        if (targetGames != null)
          Text(
            l10n.requiredGames(2).split(' ').last,
            style: const TextStyle(
              fontSize: 8,
              color: AppColors.textMuted,
            ),
          )
        else
          Text(
            config.requiredGames == 0
                ? l10n.defaultLabel
                : l10n.requiredGames(config.requiredGames),
            style: const TextStyle(
              fontSize: 8,
              color: AppColors.textMuted,
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge "collection complète"
// ─────────────────────────────────────────────────────────────────────────────

class _AllUnlockedCard extends StatelessWidget {
  const _AllUnlockedCard({
    required this.accent,
    required this.lastUnlocked,
  });

  final Color accent;
  final CardBackConfig lastUnlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.stickerWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(
          color: accent.withValues(alpha: 0.30),
          width: 1.5,
        ),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius:
                  BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: const Text(
              '⭐',
              style: TextStyle(fontSize: 22),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Collection complète !',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Tous les dos de cartes sont débloqués.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
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
