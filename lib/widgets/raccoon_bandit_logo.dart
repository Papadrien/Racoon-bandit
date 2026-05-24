import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Logo « RACCOON / BANDIT » — contour net via Picture → toImage (DPR-aware) → dilate.
class RaccoonBanditLogo extends StatefulWidget {
  const RaccoonBanditLogo({super.key});

  @override
  State<RaccoonBanditLogo> createState() => _RaccoonBanditLogoState();
}

class _RaccoonBanditLogoState extends State<RaccoonBanditLogo> {
  ui.Image? _raccoonImg;
  ui.Image? _banditImg;
  Size? _lastSize;
  double? _lastDpr;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final screenH = MediaQuery.sizeOf(context).height;
    final heightScale = screenH < 600 ? 0.85 : 1.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = w * 0.50 * heightScale;
        final logicalSize = Size(w, h);

        if (_lastSize != logicalSize || _lastDpr != dpr) {
          _lastSize = logicalSize;
          _lastDpr = dpr;
          _buildImages(logicalSize, dpr);
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
              dpr: dpr,
            ),
          ),
        );
      },
    );
  }

  Future<void> _buildImages(Size logicalSize, double dpr) async {
    final physW = (logicalSize.width * dpr).ceil();
    final physH = (logicalSize.height * dpr).ceil();

    final r = await _renderWordToImage(
      word: 'RACCOON',
      fillColor: AppTheme.primary,
      logicalSize: logicalSize,
      physW: physW,
      physH: physH,
      dpr: dpr,
      yFraction: 0.33,
      arcCurve: 0.55,
      fontSizeFraction: 0.170,
    );
    final b = await _renderWordToImage(
      word: 'BANDIT',
      fillColor: AppTheme.accent,
      logicalSize: logicalSize,
      physW: physW,
      physH: physH,
      dpr: dpr,
      yFraction: 0.67,
      arcCurve: 0.55,
      fontSizeFraction: 0.190,
    );
    if (mounted) {
      setState(() {
        _raccoonImg?.dispose();
        _banditImg?.dispose();
        _raccoonImg = r;
        _banditImg = b;
      });
    }
  }

  static Future<ui.Image> _renderWordToImage({
    required String word,
    required Color fillColor,
    required Size logicalSize,
    required int physW,
    required int physH,
    required double dpr,
    required double yFraction,
    required double arcCurve,
    required double fontSizeFraction,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    // Scale par le DPR : on dessine en coords logiques → bitmap physique net
    canvas.scale(dpr, dpr);
    _paintWord(
      canvas: canvas,
      size: logicalSize,
      word: word,
      fillColor: fillColor,
      yFraction: yFraction,
      arcCurve: arcCurve,
      fontSizeFraction: fontSizeFraction,
    );
    final picture = recorder.endRecording();
    return picture.toImage(physW, physH);
  }

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
    required this.dpr,
  });

  final Color primaryColor;
  final Color accentColor;
  final ui.Image? raccoonImg;
  final ui.Image? banditImg;
  final double dpr;

  /// Matrice 4×4 colonne-majeure qui divise x et y par [dpr].
  /// Permet d'afficher le bitmap physique à taille logique.
  Float64List _scaleDown() {
    final s = 1.0 / dpr;
    return Float64List.fromList([
      s, 0, 0, 0,
      0, s, 0, 0,
      0, 0, 1, 0,
      0, 0, 0, 1,
    ]);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (raccoonImg == null || banditImg == null) return;
    _drawWithOutline(canvas, size, raccoonImg!);
    _drawWithOutline(canvas, size, banditImg!);
  }

  void _drawWithOutline(Canvas canvas, Size size, ui.Image img) {
    // Le contour en pixels physiques — épais pour couvrir les interstices
    final outlineR = size.width * dpr * 0.032;
    final logicalRect = Offset.zero & size;
    final sd = _scaleDown();

    // 1. Ombre portée floue
    canvas.save();
    canvas.translate(4, 9);
    canvas.saveLayer(logicalRect, Paint());
    canvas.transform(sd);
    canvas.drawImage(
      img,
      Offset.zero,
      Paint()
        ..colorFilter = const ColorFilter.mode(Color(0x55000000), BlendMode.srcIn)
        ..imageFilter = ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
    );
    canvas.restore(); // saveLayer
    canvas.restore(); // translate

    // 2. Contour blanc arrondi et net :
    //    dilate (épaissit) → blur léger (arrondit les coins) → threshold (re-solidifie)
    //
    //    Le ColorMatrix threshold : alpha = clamp(alpha * 10 - 1, 0, 1)
    //    Tout pixel avec alpha > ~0.1 devient opaque → bord net, angles arrondis.
    const thresholdMatrix = ColorFilter.matrix(<double>[
      // R    G    B    A   +
         0,   0,   0,   0, 255, // R → blanc
         0,   0,   0,   0, 255, // G → blanc
         0,   0,   0,   0, 255, // B → blanc
         0,   0,   0,  18,  -1, // A : ×18 − 1 (seuil ~6% alpha)
    ]);

    canvas.saveLayer(
      logicalRect,
      Paint()
        ..colorFilter = thresholdMatrix
        ..imageFilter = ui.ImageFilter.compose(
          // d'abord dilate, puis blur pour arrondir
          outer: ui.ImageFilter.blur(sigmaX: outlineR * 0.55, sigmaY: outlineR * 0.55),
          inner: ui.ImageFilter.dilate(radiusX: outlineR * 0.7, radiusY: outlineR * 0.7),
        ),
    );
    canvas.transform(sd);
    canvas.drawImage(img, Offset.zero, Paint());
    canvas.restore();

    // 3. Lettres colorées (bitmap à taille logique)
    canvas.save();
    canvas.transform(sd);
    canvas.drawImage(img, Offset.zero, Paint());
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LogoPainter old) =>
      old.raccoonImg != raccoonImg ||
      old.banditImg != banditImg ||
      old.dpr != dpr ||
      old.primaryColor != primaryColor ||
      old.accentColor != accentColor;
}
