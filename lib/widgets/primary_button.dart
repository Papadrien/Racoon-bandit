import 'package:flutter/material.dart';

import '../core/services/audio_service.dart';
import '../core/services/haptic_service.dart';
import '../core/ui/app_colors.dart';
import '../core/ui/app_spacing.dart';

/// Bouton primaire standard — style ElevatedButton cohérent avec le thème.
///
/// Pour le bouton Jouer (style sticker avec coupe diagonale), utiliser
/// [_StickerPlayButton] dans home_screen.dart.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  /// Couleur de fond — par défaut [AppColors.orange].
  final Color? backgroundColor;

  /// Couleur du texte — par défaut [Colors.white].
  final Color? foregroundColor;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: double.infinity,
        height: AppSpacing.buttonHeightSecondary,
        child: ElevatedButton(
          onPressed: onPressed == null
              ? null
              : () {
                  HapticService.trigger(HapticType.selection);
                  AudioService.instance.playSfx(SoundEffect.button);
                  onPressed!();
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? AppColors.orange,
            foregroundColor: foregroundColor ?? Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(AppSpacing.radiusMedium),
              ),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}
