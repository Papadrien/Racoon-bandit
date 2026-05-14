import 'package:flutter/material.dart';

import '../core/models/reward_unlock.dart';
import '../core/services/progression_service.dart';
import '../core/theme/app_theme.dart';

/// Popup plein écran affichée lors du déblocage d'un nouveau dos de carte.
///
/// Appeler via [RewardUnlockDialog.show] pour enchaîner plusieurs récompenses
/// si nécessaire.
///
/// Bouton "Essayer"  → équipe immédiatement le dos et ferme la popup.
/// Bouton "Plus tard" → ferme la popup sans changer l'équipement.
class RewardUnlockDialog extends StatefulWidget {
  const RewardUnlockDialog({
    super.key,
    required this.reward,
    required this.onTryNow,
    required this.onLater,
  });

  final RewardUnlock reward;
  final VoidCallback onTryNow;
  final VoidCallback onLater;

  /// Affiche la popup et attend la réponse du joueur.
  ///
  /// Retourne `true` si "Essayer" a été choisi, `false` sinon.
  static Future<bool> show(
    BuildContext context,
    RewardUnlock reward,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => RewardUnlockDialog(
        reward: reward,
        onTryNow: () => Navigator.of(ctx).pop(true),
        onLater: () => Navigator.of(ctx).pop(false),
      ),
    );
    return result ?? false;
  }

  /// Affiche les popups pour chaque récompense en séquence et équipe
  /// immédiatement si le joueur choisit "Essayer".
  static Future<void> showAll(
    BuildContext context,
    List<RewardUnlock> rewards,
  ) async {
    for (final reward in rewards) {
      if (!context.mounted) return;
      final tryNow = await show(context, reward);
      if (tryNow) {
        await ProgressionService.selectCardBack(reward.id);
      }
    }
  }

  @override
  State<RewardUnlockDialog> createState() => _RewardUnlockDialogState();
}

class _RewardUnlockDialogState extends State<RewardUnlockDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Center(
        child: ScaleTransition(
          scale: _scale,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2E),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.25),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Badge titre
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.accent.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Text(
                          '🎉 Nouveau déblocage !',
                          style: TextStyle(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Aperçu du dos de carte
                      _CardPreview(reward: widget.reward),

                      const SizedBox(height: 20),

                      // Nom du dos
                      Text(
                        widget.reward.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Description courte
                      Text(
                        _descriptionFor(widget.reward),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Bouton Essayer
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: widget.onTryNow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          child: const Text('ESSAYER'),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Bouton Plus tard
                      TextButton(
                        onPressed: widget.onLater,
                        child: const Text(
                          'Plus tard',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _descriptionFor(RewardUnlock reward) {
    switch (reward.type) {
      case RewardType.cardBack:
        final hint = reward.unlockHint;
        if (hint != null && hint.isNotEmpty) {
          return '$hint\nPersonnalisez votre deck dès maintenant !';
        }
        return 'Nouveau dos de carte débloqué !\nPersonnalisez votre deck dès maintenant !';
    }
  }
}

/// Aperçu visuel du dos de carte dans la popup.
class _CardPreview extends StatelessWidget {
  const _CardPreview({required this.reward});

  final RewardUnlock reward;

  @override
  Widget build(BuildContext context) {
    final assetPath = reward.assetPath;

    return Container(
      width: 100,
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: assetPath != null
          ? Image.asset(
              assetPath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _Placeholder(reward: reward),
            )
          : _Placeholder(reward: reward),
    );
  }
}

/// Placeholder coloré quand il n'y a pas d'asset image.
class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.reward});

  final RewardUnlock reward;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primary.withValues(alpha: 0.2),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.style_rounded, color: AppTheme.primary, size: 36),
            const SizedBox(height: 6),
            Text(
              reward.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
