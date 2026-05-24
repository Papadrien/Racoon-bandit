import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Logo « RACCOON / BANDIT » — contour net via Picture → toImage → dilate.
class RaccoonBanditLogo extends StatefulWidget {
  const RaccoonBanditLogo({super.key});

  @override
  State<RaccoonBanditLogo> createState() => _RaccoonBanditLogoState();
}

class _RaccoonBanditLogoState extends State<RaccoonBanditLogo> {
  ui.Image? _raccoonImg;
  ui.Image? _banditImg;
  Size? _lastSize;

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    final heightScale = screenH < 600 ? 0.85 : 1.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = w * 0.50 * heightScale;
        final sz = Size(w, h);

        // Regénère les images si la taille change
        if (_lastSize != sz) {
          _lastSize = sz;
          _buildImages(sz);
        }

        return SizedBox(
          width: w,
          height: h,
          child: CustomPaint(
            painter: _LogoPainter(
              primaryColor: AppTheme.primary,
              accentColor: AppTheme.accent,
              raccoonImg: _raccoonImg,
              banditImg: _banditImg,
            ),
          ),
        );
      },
    );
  }

  Future<void> _buildImages(Size size) async {
    final r = await _renderWordToImage(
      word: 'RACCOON',
      fillColor: AppTheme.primary,
      size: size,
      yFraction: 0.33,
      arcCurve: 0.55,
      fontSizeFraction: 0.170,
    );
    final b = await _renderWordToImage(
      word: 'BANDIT',
      fillColor: AppTheme.accent,
      size: size,
      yFraction: 0.67,
      arcCurve: 0.55,
      fontSizeFraction: 0.190,
    );
    if (mounted) {
      setState(() {
        _raccoonImg = r;
        _banditImg = b;
      });
    }
  }

  /// Rend un mot dans une ui.Image de la taille du canvas.
  static Future<ui.Image> _renderWordToImage({
    required String word,
    required Color fillColor,
    required Size size,
    required double yFraction,
    required double arcCurve,
    required double fontSizeFraction,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    _paintWord(
      canvas: canvas,
      size: size,
      word: word,
      fillColor: fillColor,
      yFraction: yFraction,
      arcCurve: arcCurve,
      fontSizeFraction: fontSizeFraction,
    );
    final picture = recorder.endRecording();
    return picture.toImage(size.width.ceil(), size.height.ceil());
  }

  // ── Logique de dessin d'un mot (positions + arc) ──────────────────────────

  static void _paintWord({
    required Canvas canvas,
    required Size size,
    required String word,
    required Color fillColor,
    required double yFraction,
    required double arcCurve,
    required double fontSizeFraction,
  }) {
    final fontSize = size.width * fontSizeFraction;
    final chars = word.split('');

    final style = TextStyle(
      fontFamily: 'Righteous',
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      letterSpacing: fontSize * 0.04,
      color: fillColor,
    );

    final painters = <TextPainter>[];
    for (final ch in chars) {
      painters.add(
        TextPainter(
          text: TextSpan(text: ch, style: style),
          textDirection: TextDirection.ltr,
        )..layout(),
      );
    }

    final totalW = painters.fold(0.0, (s, tp) => s + tp.size.width);
    final mid = totalW / 2;
    final yCenter = size.height * yFraction;

    double wordX = 0;
    double canvasX = (size.width - totalW) / 2;

    for (int i = 0; i < chars.length; i++) {
      final tp = painters[i];
      final cw = tp.size.width;
      final chH = tp.size.height;

      final t = mid > 0 ? (wordX + cw / 2 - mid) / mid : 0.0;
      final arcY = -arcCurve * (1.0 - t * t) * fontSize * 0.22;
      final tilt = arcCurve * t * 0.09;

      canvas.save();
      canvas.translate(canvasX + cw / 2, yCenter + arcY);
      canvas.rotate(tilt);
      tp.paint(canvas, Offset(-cw / 2, -chH * 0.60));
      canvas.restore();

      wordX += cw;
      canvasX += cw;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _LogoPainter extends CustomPainter {
  const _LogoPainter({
    required this.primaryColor,
    required this.accentColor,
    required this.raccoonImg,
    required this.banditImg,
  });

  final Color primaryColor;
  final Color accentColor;
  final ui.Image? raccoonImg;
  final ui.Image? banditImg;

  @override
  void paint(Canvas canvas, Size size) {
    if (raccoonImg == null || banditImg == null) return;

    _drawWithOutline(canvas, size, raccoonImg!);
    _drawWithOutline(canvas, size, banditImg!);
  }

  void _drawWithOutline(Canvas canvas, Size size, ui.Image img) {
    final outlineR = size.width * 0.012; // rayon du contour net

    final rect = Offset.zero & size;

    // 1. Ombre portée
    canvas.saveLayer(rect, Paint());
    canvas.drawImage(
      img,
      Offset.zero,
      Paint()
        ..colorFilter = const ColorFilter.mode(Color(0x55000000), BlendMode.srcIn)
        ..imageFilter = ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
    );
    canvas.restore();
    // décalage ombre — on refait avec translate
    canvas.save();
    canvas.translate(3, 7);
    canvas.saveLayer(rect, Paint());
    canvas.drawImage(
      img,
      Offset.zero,
      Paint()
        ..colorFilter = const ColorFilter.mode(Color(0x44000000), BlendMode.srcIn)
        ..imageFilter = ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
    );
    canvas.restore();
    canvas.restore();

    // 2. Contour blanc net via dilate sur le bitmap
    canvas.saveLayer(rect,
      Paint()
        ..colorFilter = const ColorFilter.mode(Colors.white, BlendMode.srcIn)
        ..imageFilter = ui.ImageFilter.dilate(radiusX: outlineR, radiusY: outlineR),
    );
    canvas.drawImage(img, Offset.zero, Paint());
    canvas.restore();

    // 3. Lettres colorées par-dessus
    canvas.drawImage(img, Offset.zero, Paint());
  }

  @override
  bool shouldRepaint(covariant _LogoPainter old) =>
      old.raccoonImg != raccoonImg || old.banditImg != banditImg ||
      old.primaryColor != primaryColor || old.accentColor != accentColor;
}
