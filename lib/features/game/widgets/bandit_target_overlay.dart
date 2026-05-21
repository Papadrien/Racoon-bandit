import 'package:flutter/material.dart';

import '../../../core/models/player_state.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/player_avatar.dart';

/// Overlay de sélection de cible pour la carte Bandit.
///
/// Affiche un backdrop semi-transparent + une carte modale centrée
/// listant les cibles valides. L'appelant fournit [targets] et reçoit
/// la cible choisie via [onTargetSelected].
///
/// Architecture réutilisable : ce widget peut servir de base pour
/// toute future popup gameplay (récompenses, confirmations, événements).
class BanditTargetOverlay extends StatefulWidget {
  const BanditTargetOverlay({
    super.key,
    required this.targets,
    required this.onTargetSelected,
  });

  final List<PlayerState> targets;
  final void Function(PlayerState target) onTargetSelected;

  @override
  State<BanditTargetOverlay> createState() => _BanditTargetOverlayState();
}

class _BanditTargetOverlayState extends State<BanditTargetOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  /// Empêche le double-tap : true dès qu'une cible est choisie.
  bool _chosen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _select(PlayerState target) async {
    if (_chosen) return;
    _chosen = true;

    HapticService.trigger(HapticType.medium);
    AudioService.instance.playButtonSound();

    // Fermeture animée avant de notifier l'appelant
    await _controller.reverse();
    widget.onTargetSelected(target);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Material(
        color: Colors.black.withValues(alpha: 0.65),
        child: SafeArea(
          child: Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: _buildCard(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Hauteur max disponible (ex : petit téléphone avec clavier logiciel)
        final maxCardHeight = MediaQuery.of(context).size.height * 0.78;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          constraints: BoxConstraints(maxHeight: maxCardHeight),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          decoration: BoxDecoration(
            color: const Color(0xFF241C36),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF7C4DFF).withValues(alpha: 0.55),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C4DFF).withValues(alpha: 0.25),
                blurRadius: 32,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── En-tête ─────────────────────────────────────────────────
              const Text(
                '🥷',
                style: TextStyle(fontSize: 36),
              ),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context)!.banditChooseTarget,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                AppLocalizations.of(context)!.banditWhoToSteal,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),

              // ── Liste des cibles (scrollable si trop haute) ─────────────
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: widget.targets
                        .map((target) => _buildTargetTile(target))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTargetTile(PlayerState target) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _select(target),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: target.profileColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: target.profileColor.withValues(alpha: 0.45),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              PlayerAvatar(
                emoji: target.emoji,
                color: target.profileColor,
                size: 44,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      target.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(context)!.banditFoodAvailable(target.foodCount),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: target.profileColor.withValues(alpha: 0.7),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
