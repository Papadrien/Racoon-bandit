import 'package:flutter/material.dart';

import '../core/ui/app_colors.dart';
import '../core/ui/app_decorations.dart';
import '../core/ui/app_spacing.dart';

/// Indicateur d'état de partie — concept "Partie prête" / "Nouvelle partie dans".
///
/// Remplace visuellement l'ancien LivesIndicator (cœurs + timer).
/// La logique backend (LifeSystemService) reste entièrement inchangée.
///
/// Cas 1 — partie disponible  : affiche "Partie prête" avec une icône douce.
/// Cas 2 — aucune disponible  : affiche "Nouvelle partie dans\nMM:SS" sur 2 lignes.
class GameReadyIndicator extends StatelessWidget {
  /// Nombre de parties (vies) restantes.
  final int lives;

  /// Durée avant recharge. Null ou zero si une partie est disponible.
  final Duration remainingDuration;

  const GameReadyIndicator({
    super.key,
    required this.lives,
    required this.remainingDuration,
  });

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  bool get _hasGame => lives > 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: AppDecorations.whiteSticker,
      child: _hasGame ? _ReadyState() : _WaitingState(remainingDuration),
    );
  }
}

// ── État positif : "Partie prête" ─────────────────────────────────────────────

class _ReadyState extends StatelessWidget {
  const _ReadyState();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icône douce — étoile/soleil cozy, sans référence à des vies/cœurs
        Icon(
          Icons.auto_awesome_rounded,
          size: 16,
          color: AppColors.orange.withValues(alpha: 0.85),
        ),
        const SizedBox(width: AppSpacing.xs + 2),
        Text(
          'Partie prête',
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// ── État d'attente : "Nouvelle partie dans\nMM:SS" ────────────────────────────

class _WaitingState extends StatelessWidget {
  final Duration remaining;

  const _WaitingState(this.remaining);

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Nouvelle partie dans',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
        Text(
          _formatDuration(remaining),
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}
