import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Logo « RACCOON / BANDIT » rendu entièrement en Flutter.
///
/// Effet sticker cartoon :
///   • Police Righteous personnalisée
///   • Contour blanc épais + coins arrondis
///   • Arc subtil (frown sur RACCOON, smile sur BANDIT)
///   • Légère inclinaison de chaque lettre
///   • Ombre portée douce
///
/// Sans aucune image bitmap — 100 % vectoriel / scalable.
class RaccoonBanditLogo extends StatelessWidget {
  const RaccoonBanditLogo({super.key});

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    final heightScale = screenH < 600 ? 0.85 : 1.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = w * 0.50 * heightScale;

        return SizedBox(
          width: w,
          height: h,
          child: CustomPaint(
            painter: _LogoPainter(
              primaryColor: AppTheme.primary,
              accentColor: AppTheme.accent,
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _LogoPainter extends CustomPainter {
  const _LogoPainter({
    required this.primaryColor,
    required this.accentColor,
  });

  final Color primaryColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    // RACCOON — violet, arche vers le haut (frown)
    _drawWord(
      canvas: canvas,
      size: size,
      word: 'RACCOON',
      fillColor: primaryColor,
      yFraction: 0.28,
      arcCurve: -0.65,
      fontSizeFraction: 0.170,
    );

    // BANDIT — couleur accent, arche vers le bas (smile)
    _drawWord(
      canvas: canvas,
      size: size,
      word: 'BANDIT',
      fillColor: accentColor,
      yFraction: 0.78,
      arcCurve: 0.65,
      fontSizeFraction: 0.190,
    );
  }

  // ── Dessin d'un mot le long d'un arc ─────────────────────────────────────

  void _drawWord({
    required Canvas canvas,
    required Size size,
    required String word,
    required Color fillColor,
    required double yFraction,
    required double arcCurve,   // négatif = frown, positif = smile
    required double fontSizeFraction,
  }) {
    final fontSize = size.width * fontSizeFraction;
    final outlineHalf = fontSize * 0.13; // demi-épaisseur du stroke blanc
    final chars = word.split('');

    // ── Styles ────────────────────────────────────────────────────────────

    final fillStyle = TextStyle(
      fontFamily: 'Righteous',
      fontSize: fontSize,
      color: fillColor,
    );

    final outlineStyle = TextStyle(
      fontFamily: 'Righteous',
      fontSize: fontSize,
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = outlineHalf * 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = Colors.white,
    );

    final shadowStyle = TextStyle(
      fontFamily: 'Righteous',
      fontSize: fontSize,
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = outlineHalf * 2
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0x48301050)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // ── Mesure des caractères ─────────────────────────────────────────────

    final fillPainters = <TextPainter>[];
    for (final ch in chars) {
      fillPainters.add(
        TextPainter(
          text: TextSpan(text: ch, style: fillStyle),
          textDirection: TextDirection.ltr,
        )..layout(),
      );
    }

    final totalW = fillPainters.fold(0.0, (s, tp) => s + tp.size.width);
    final mid = totalW / 2;
    final yCenter = size.height * yFraction;

    // wordX : avancement dans le mot (0..totalW)
    double wordX = 0;
    // canvasX : position de départ sur le canvas
    double canvasX = (size.width - totalW) / 2;

    for (int i = 0; i < chars.length; i++) {
      final ch = chars[i];
      final tp = fillPainters[i];
      final cw = tp.size.width;
      final ch_h = tp.size.height;

      // t ∈ [-1, 1] : position du centre de la lettre dans le mot
      final charCenterInWord = wordX + cw / 2;
      final t = mid > 0 ? (charCenterInWord - mid) / mid : 0.0;

      // Arc parabolique : y = curve * t² * amplitude
      final arcY = arcCurve * t * t * fontSize * 0.22;

      // Inclinaison : tangente de la parabole = 2 * curve * t * amplitude / mid
      final tilt = -arcCurve * t * 0.09; // en radians

      canvas.save();
      canvas.translate(canvasX + cw / 2, yCenter + arcY);
      canvas.rotate(tilt);

      // Offset pour centrer la glyphe sur l'origine du canvas sauvegardé
      final dx = -cw / 2;
      final dy = -ch_h * 0.60; // ~centre optique pour les capitales

      // 1. Ombre (légèrement décalée, floutée)
      TextPainter(
        text: TextSpan(text: ch, style: shadowStyle),
        textDirection: TextDirection.ltr,
      )
        ..layout()
        ..paint(canvas, Offset(dx + 2.0, dy + 6.0));

      // 2. Contour blanc
      TextPainter(
        text: TextSpan(text: ch, style: outlineStyle),
        textDirection: TextDirection.ltr,
      )
        ..layout()
        ..paint(canvas, Offset(dx, dy));

      // 3. Remplissage coloré
      tp.paint(canvas, Offset(dx, dy));

      canvas.restore();

      wordX += cw;
      canvasX += cw;
    }
  }

  // ── Repaint ───────────────────────────────────────────────────────────────

  @override
  bool shouldRepaint(covariant _LogoPainter old) =>
      old.primaryColor != primaryColor || old.accentColor != accentColor;
}
