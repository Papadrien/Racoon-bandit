import 'package:flutter/material.dart';

import '../../../core/models/player_state.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/ui/app_colors.dart';
import '../../../core/ui/app_shadows.dart';
import '../../../core/ui/app_spacing.dart';
import 'package:raccoon_bandit/l10n/app_localizations.dart';
import '../../../widgets/player_avatar.dart';

/// Overlay de sélection de cible pour la carte Pince (et assimilés).
///
/// Popup floating card moderne, cohérente avec le HUD gameplay :
/// fond beige chaud, ombres douces AppShadows, coins arrondis AppSpacing.
///
/// La logique gameplay (callback onTargetSelected) est inchangée.
class PinceTargetOverlay extends StatefulWidget {
  const PinceTargetOverlay({
    super.key,
    required this.targets,
    required this.onTargetSelected,
  });

  final List<PlayerState> targets;
  final void Function(PlayerState target) onTargetSelected;

  @override
  State<PinceTargetOverlay> createState() => _PinceTargetOverlayState();
}

class _PinceTargetOverlayState extends State<PinceTargetOverlay>
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
      // Backdrop transparent — ombres portées sur la card suffisent
      child: Material(
        color: Colors.transparent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Tap outside to dismiss (optional: could be removed)
            GestureDetector(
              onTap: () {}, // absorb taps on backdrop
              behavior: HitTestBehavior.opaque,
            ),
            Center(
              child: SafeArea(
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildCard(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxCardHeight = screenHeight * 0.80;

    // Responsive horizontal margin : plus serré sur petits écrans
    final hMargin = screenWidth < 360 ? 16.0 : 24.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: hMargin),
      constraints: BoxConstraints(maxHeight: maxCardHeight),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 32,
            spreadRadius: 4,
            offset: Offset(0, 12),
          ),
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            _buildDivider(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.targets
                      .map((target) => _buildTargetTile(context, target))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// En-tête de la popup : emoji + titre + sous-titre.
  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo pince sans vignette ronde — image pleine taille
          Image.asset(
            'assets/images/card_front_pince.png',
            fit: BoxFit.contain,
            width: 72,
            height: 72,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.pinceChooseTarget,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.pinceWhoToSteal,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1.5,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.stickerWarm,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildTargetTile(BuildContext context, PlayerState target) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isNarrow = screenWidth < 360;

    // Taille avatar responsive
    final avatarSize = isNarrow ? 40.0 : 48.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GestureDetector(
        onTap: () => _select(target),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isNarrow ? AppSpacing.md : AppSpacing.lg,
            vertical: isNarrow ? AppSpacing.sm : AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.stickerWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            border: Border.all(
              color: target.profileColor.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: AppShadows.floating,
          ),
          child: Row(
            children: [
              // Avatar joueur
              PlayerAvatar(
                emoji: target.emoji,
                color: target.profileColor,
                size: avatarSize,
              ),
              const SizedBox(width: AppSpacing.md),

              // Nom + ressources
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      target.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: isNarrow ? 14.0 : 15.0,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _buildFoodBadge(context, target),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              // Chevron dans un cercle coloré
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: target.profileColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: target.profileColor,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Badge nourriture : icône + texte, style pill sticker.
  Widget _buildFoodBadge(BuildContext context, PlayerState target) {
    final l10n = AppLocalizations.of(context)!;
    final foodText = l10n.pinceFoodAvailable(target.foodCount);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Petite icône nourriture
        Image.asset(
          'assets/images/icon_food.png',
          width: 14,
          height: 14,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 4),
        Text(
          foodText,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
