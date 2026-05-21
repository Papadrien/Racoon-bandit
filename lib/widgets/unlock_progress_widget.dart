import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

import '../core/models/card_back_config.dart';
import '../core/services/progression_service.dart';
import '../core/theme/app_theme_provider.dart';

/// Widget de progression vers le prochain dos de carte.
///
/// Affiche :
/// - à gauche : le dernier dos débloqué (état actif)
/// - au centre : barre de progression animée + texte
/// - à droite : le prochain dos verrouillé (grisé, cadenas)
///
/// Si tous les dos sont débloqués, affiche un message de félicitations.
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
      duration: const Duration(milliseconds: 600),
    );
    _barAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    // Délai léger pour que la barre s'anime après l'apparition de l'écran
    Future.delayed(const Duration(milliseconds: 300), () {
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
    return ListenableBuilder(
      listenable: AppThemeProvider.instance,
      builder: (context, _) {
        final accent = AppThemeProvider.instance.accent;
        final progression = ProgressionService.progression;
        final totalGames = progression.totalGamesPlayed;
        final unlockedIds = progression.unlockedCardBackIds;
        final allBacks = ProgressionService.cardBacks;

        // Dernier dos débloqué (le plus avancé dans la liste)
        final unlockedBacks = allBacks
            .where((cb) => unlockedIds.contains(cb.id))
            .toList();
        final lastUnlocked = unlockedBacks.last;

        // Prochain dos à débloquer
        final nextBack = allBacks
            .where((cb) => !unlockedIds.contains(cb.id))
            .cast<CardBackConfig?>()
            .firstOrNull;

        // Tous débloqués
        if (nextBack == null) {
          return _AllUnlockedBadge(accent: accent, lastUnlocked: lastUnlocked);
        }

        // Calcul progression entre le dernier palier et le prochain
        final fromGames = lastUnlocked.requiredGames;
        final toGames = nextBack.requiredGames;
        final range = toGames - fromGames;
        final progress = range > 0
            ? ((totalGames - fromGames) / range).clamp(0.0, 1.0)
            : 1.0;
        final remaining = (toGames - totalGames).clamp(0, toGames);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accent.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre
              Row(
                children: [
                  Icon(Icons.local_activity_rounded,
                      size: 14, color: accent.withValues(alpha: 0.8)),
                  const SizedBox(width: 5),
                  Text(
                    AppLocalizations.of(context)!.unlockProgressNext,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: accent.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Corps : dos gauche + barre + dos droit
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Dos débloqué (gauche) ────────────────────────────────
                  _CardBackPreview(
                    config: lastUnlocked,
                    isLocked: false,
                    accent: accent,
                  ),
                  const SizedBox(width: 10),

                  // ── Barre de progression centrale ─────────────────────────
                  Expanded(
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: _barAnimation,
                          builder: (context, _) {
                            return _ProgressBar(
                              progress: progress * _barAnimation.value,
                              accent: accent,
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        Text(
                          remaining == 0
                              ? '$totalGames / $toGames parties'
                              : '$remaining partie${remaining > 1 ? 's' : ''} restante${remaining > 1 ? 's' : ''}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFFB0B0C8),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$totalGames / $toGames',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // ── Prochain dos verrouillé (droite) ─────────────────────
                  _CardBackPreview(
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
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Barre de progression
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
          height: 8,
          width: constraints.maxWidth,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: constraints.maxWidth * progress,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: LinearGradient(
                  colors: [
                    accent.withValues(alpha: 0.7),
                    accent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.5),
                    blurRadius: 6,
                    spreadRadius: 0,
                  ),
                ],
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

class _CardBackPreview extends StatelessWidget {
  const _CardBackPreview({
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
    return Column(
      children: [
        SizedBox(
          width: _w,
          height: _h,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image (désaturée si verrouillée)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ColorFiltered(
                  colorFilter: isLocked
                      ? const ColorFilter.matrix([
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0, 0, 0, 0.38, 0,
                        ])
                      : const ColorFilter.mode(
                          Colors.transparent, BlendMode.multiply),
                  child: Image.asset(
                    config.assetPath,
                    fit: BoxFit.cover,
                    width: _w,
                    height: _h,
                    errorBuilder: (_, a, b) => Container(
                      decoration: BoxDecoration(
                        color: config.themeColor
                            .withValues(alpha: isLocked ? 0.3 : 0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),

              // Overlay sombre + cadenas si verrouillé
              if (isLocked)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.15),
                          Colors.black.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.lock_rounded,
                        color: Colors.white.withValues(alpha: 0.85),
                        size: 20,
                      ),
                    ),
                  ),
                ),

              // Badge débloqué (coche)
              if (!isLocked)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ],
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
        const SizedBox(height: 5),
        // Nombre cible ou nom
        Text(
          targetGames != null ? '$targetGames' : config.name,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isLocked
                ? Colors.white.withValues(alpha: 0.45)
                : accent,
          ),
        ),
        if (targetGames != null)
          Text(
            AppLocalizations.of(context)!.requiredGames(2).split(' ').last,
            style: TextStyle(
              fontSize: 8,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          )
        else
          Text(
            config.requiredGames == 0 ? AppLocalizations.of(context)!.defaultLabel : AppLocalizations.of(context)!.requiredGames(config.requiredGames),
            style: TextStyle(
              fontSize: 8,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge "tout débloqué"
// ─────────────────────────────────────────────────────────────────────────────

class _AllUnlockedBadge extends StatelessWidget {
  const _AllUnlockedBadge({
    required this.accent,
    required this.lastUnlocked,
  });

  final Color accent;
  final CardBackConfig lastUnlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.stars_rounded, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Collection complète !',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Tous les dos de cartes sont débloqués.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFB0B0C8),
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
