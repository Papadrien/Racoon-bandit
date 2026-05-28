import 'package:flutter/material.dart';

import '../core/services/audio_service.dart';
import '../core/services/haptic_service.dart';
import '../core/ui/app_colors.dart';
import '../core/ui/app_spacing.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OrangeButton — bouton orange unifié, style cohérent avec le bouton Jouer.
//
// Dégradé [orangeLight → orange → orangeDark], contour blanc, glow bas,
// radius fort. Remplace PrimaryButton orange, TutorialNextButton, _RewardAdButton.
//
// Usage :
//   OrangeButton(label: 'JOUER', onPressed: _start)
//   OrangeButton(label: 'SUIVANT', onPressed: _next, height: 62)
//   OrangeButton(label: 'SUIVANT', icon: Icons.play_arrow, onPressed: _next)
// ─────────────────────────────────────────────────────────────────────────────

class OrangeButton extends StatelessWidget {
  const OrangeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = AppSpacing.buttonHeight,
    this.fontSize = 20,
    this.letterSpacing = 2.0,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final double fontSize;
  final double letterSpacing;
  final bool isLoading;

  static const _radius = AppSpacing.radiusXLarge; // 28

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: _OrangeButtonInk(
        enabled: enabled,
        radius: _radius,
        onTap: enabled
            ? () {
                HapticService.trigger(HapticType.selection);
                AudioService.instance.playSfx(SoundEffect.button);
                onPressed!();
              }
            : null,
        child: _ButtonContent(
          label: label,
          icon: icon,
          isLoading: isLoading,
          fontSize: fontSize,
          letterSpacing: letterSpacing,
          enabled: enabled,
        ),
      ),
    );
  }
}

// ── Ink + décoration dégradé ──────────────────────────────────────────────────

class _OrangeButtonInk extends StatelessWidget {
  const _OrangeButtonInk({
    required this.enabled,
    required this.radius,
    required this.onTap,
    required this.child,
  });

  final bool enabled;
  final double radius;
  final VoidCallback? onTap;
  final Widget child;

  static const _gradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.orangeLight, AppColors.orange, AppColors.orangeDark],
    stops: [0.0, 0.55, 1.0],
  );

  static const _gradientDisabled = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFD4A47A), Color(0xFFBD8555), Color(0xFFA86838)],
    stops: [0.0, 0.55, 1.0],
  );


  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);

    return Material(
      color: Colors.transparent,
      borderRadius: br,
      child: Ink(
        decoration: BoxDecoration(
          gradient: enabled ? _gradient : _gradientDisabled,
          borderRadius: br,
          border: Border.all(
            color: enabled
                ? const Color(0xCCFFFFFF)
                : const Color(0x55FFFFFF),
            width: 4.0,
          ),
          boxShadow: null,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: br,
          splashColor: Colors.white24,
          highlightColor: Colors.white10,
          child: child,
        ),
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.enabled,
    required this.fontSize,
    required this.letterSpacing,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final IconData? icon;
  final bool isLoading;
  final bool enabled;
  final double fontSize;
  final double letterSpacing;

  static const _textStyle = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w900,
    shadows: [
      Shadow(
        color: Color(0x55000000),
        offset: Offset(0, 2),
        blurRadius: 3,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: fontSize + 2),
            const SizedBox(width: 8),
          ],
          Text(
            label.toUpperCase(),
            style: _textStyle.copyWith(
              fontSize: fontSize,
              letterSpacing: letterSpacing,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PrimaryButton — alias de compatibilité → OrangeButton avec fontSize réduit.
//
// Conservé pour ne pas casser les imports existants (lobby, result).
// ─────────────────────────────────────────────────────────────────────────────

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor,  // ignoré — conservé pour compatibilité API
    this.foregroundColor,  // ignoré — conservé pour compatibilité API
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return OrangeButton(
      label: label,
      onPressed: onPressed,
      height: AppSpacing.buttonHeightSecondary,
      fontSize: 15,
      letterSpacing: 2,
    );
  }
}
