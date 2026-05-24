import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Logo « RACCOON / BANDIT » rendu entièrement en Flutter.
///
/// Effet sticker cartoon :
///   • Police Righteous personnalisée
///   • Contour blanc épais autour du MOT entier (pas lettre par lettre)
///   • Arc smile sur les deux mots (lettres du centre plus hautes)
///   • Légère inclinaison de chaque lettre
///   • Ombre portée douce
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
    // RACCOON — violet, smile (lettres du centre plus hautes → arcCurve positif)
    _drawWord(
      canvas: canvas,
      size: size,
      word: 'RACCOON',
      fillColor: primaryColor,
      yFraction: 0.30,
      arcCurve: 0.55,        // positif = smile (centre monte)
      fontSizeFraction: 0.170,
    );

    // BANDIT — orange, smile également, plus proche de RACCOON
    _drawWord(
      canvas: canvas,
      size: size,
      word: 'BANDIT',
      fillColor: accentColor,
      yFraction: 0.72,
      arcCurve: 0.55,
      fontSizeFraction: 0.190,
    );
  }

  // ── Dessin d'un mot avec contour global ──────────────────────────────────

  void _drawWord({
    required Canvas canvas,
    required Size size,
    required String word,
    required Color fillColor,
    required double yFraction,
    required double arcCurve,   // positif = smile (centre plus haut)
    required double fontSizeFraction,
  }) {
    final fontSize = size.width * fontSizeFraction;
    final outlineWidth = fontSize * 0.18; // épaisseur contour global
    final chars = word.split('');

    final fillStyle = TextStyle(
      fontFamily: 'Righteous',
      fontSize: fontSize,
      color: fillColor,
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

    // ── Calcul des positions arc ──────────────────────────────────────────

    // Pour chaque lettre : position canvas, arcY, tilt
    final positions = <({double cx, double cy, double tilt, double cw, double chH})>[];

    double wordX = 0;
    double canvasX = (size.width - totalW) / 2;

    for (int i = 0; i < chars.length; i++) {
      final tp = fillPainters[i];
      final cw = tp.size.width;
      final chH = tp.size.height;

      final charCenterInWord = wordX + cw / 2;
      final t = mid > 0 ? (charCenterInWord - mid) / mid : 0.0;

      // Smile : centre monte (arcY négatif quand t ≈ 0)
      // parabole inversée : arcY = -curve * (1 - t²) * amplitude
      final arcY = -arcCurve * (1.0 - t * t) * fontSize * 0.22;

      // Inclinaison tangente
      final tilt = arcCurve * t * 0.09;

      positions.add((
        cx: canvasX + cw / 2,
        cy: yCenter + arcY,
        tilt: tilt,
        cw: cw,
        chH: chH,
      ));

      wordX += cw;
      canvasX += cw;
    }

    // ── 1. Ombre portée douce ─────────────────────────────────────────────

    final shadowStyle = TextStyle(
      fontFamily: 'Righteous',
      fontSize: fontSize,
      foreground: Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0x55000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    for (int i = 0; i < chars.length; i++) {
      final ch = chars[i];
      final p = positions[i];
      canvas.save();
      canvas.translate(p.cx + 3, p.cy + 8);
      canvas.rotate(p.tilt);
      final dx = -p.cw / 2;
      final dy = -p.chH * 0.60;
      TextPainter(
        text: TextSpan(text: ch, style: shadowStyle),
        textDirection: TextDirection.ltr,
      )
        ..layout()
        ..paint(canvas, Offset(dx, dy));
      canvas.restore();
    }

    // ── 2. Contour blanc global via ImageFilter.dilate ────────────────────
    //
    // On enregistre les lettres dans un Picture, puis on le redessine
    // avec un ColorFilter blanc + ImageFilter.dilate pour obtenir
    // un halo autour du mot entier (pas lettre par lettre).

    final recorder = ui.PictureRecorder();
    final offCanvas = Canvas(recorder);

    for (int i = 0; i < chars.length; i++) {
      final ch = chars[i];
      final p = positions[i];
      offCanvas.save();
      offCanvas.translate(p.cx, p.cy);
      offCanvas.rotate(p.tilt);
      final dx = -p.cw / 2;
      final dy = -p.chH * 0.60;
      TextPainter(
        text: TextSpan(
          text: ch,
          style: TextStyle(
            fontFamily: 'Righteous',
            fontSize: fontSize,
            color: Colors.black, // couleur neutre, sera remplacée
          ),
        ),
        textDirection: TextDirection.ltr,
      )
        ..layout()
        ..paint(offCanvas, Offset(dx, dy));
      offCanvas.restore();
    }

    final picture = recorder.endRecording();

    // Bounds du layer (légèrement agrandi pour le halo)
    final halo = outlineWidth + 4;
    final layerRect = Rect.fromLTWH(
      -halo,
      -halo,
      size.width + halo * 2,
      size.height + halo * 2,
    );

    // Dessiner le halo blanc
    final haloPaint = Paint()
      ..colorFilter = const ColorFilter.mode(Colors.white, BlendMode.srcIn)
      ..imageFilter = ui.ImageFilter.dilate(
        radiusX: outlineWidth,
        radiusY: outlineWidth,
      );

    canvas.saveLayer(layerRect, haloPaint);
    canvas.drawPicture(picture);
    canvas.restore();

    // ── 3. Lettres colorées ───────────────────────────────────────────────

    for (int i = 0; i < chars.length; i++) {
      final p = positions[i];
      final tp = fillPainters[i];
      canvas.save();
      canvas.translate(p.cx, p.cy);
      canvas.rotate(p.tilt);
      final dx = -p.cw / 2;
      final dy = -p.chH * 0.60;
      tp.paint(canvas, Offset(dx, dy));
      canvas.restore();
    }
  }

  // ── Repaint ───────────────────────────────────────────────────────────────

  @override
  bool shouldRepaint(covariant _LogoPainter old) =>
      old.primaryColor != primaryColor || old.accentColor != accentColor;
}
