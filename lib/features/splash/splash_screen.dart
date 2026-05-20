import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/navigation/app_router.dart';

/// Splash screen vidéo.
///
/// Joue [assets/videos/splash.mp4] une fois, fond couleur identique
/// à la vidéo (#612e95). La vidéo est ancrée en bas de l'écran quelle
/// que soit la taille d'affichage.
/// À la fin (ou si erreur), navigue vers HomeScreen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final VideoPlayerController _controller;
  bool _navigated = false;

  // Couleur de fond extraite de la vidéo
  static const _bgColor = Color(0xFF612e95);

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/splash.mp4')
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _controller.play();
        // Naviguer à la fin de la vidéo
        _controller.addListener(_onVideoProgress);
      }).catchError((_) => _navigateHome());
  }

  void _onVideoProgress() {
    if (_navigated) return;
    final pos = _controller.value.position;
    final dur = _controller.value.duration;
    if (dur > Duration.zero && pos >= dur - const Duration(milliseconds: 100)) {
      _navigateHome();
    }
  }

  void _navigateHome() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoProgress);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: _controller.value.isInitialized
          ? _VideoAnchored(controller: _controller)
          : const SizedBox.expand(), // Fond uni pendant init
    );
  }
}

/// Affiche la vidéo ancrée en bas de l'écran.
///
/// La vidéo garde son ratio natif et sa largeur est calée sur la largeur
/// de l'écran. Le bas de la vidéo est toujours collé au bas de l'écran,
/// quelle que soit la hauteur disponible.
class _VideoAnchored extends StatelessWidget {
  final VideoPlayerController controller;

  const _VideoAnchored({required this.controller});

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final screenH = MediaQuery.sizeOf(context).height;
    final videoSize = controller.value.size;

    // Hauteur de la vidéo proportionnelle à sa largeur native
    final videoH = videoSize.height == 0
        ? screenH
        : screenW * videoSize.height / videoSize.width;

    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SizedBox(
            width: screenW,
            height: videoH,
            child: VideoPlayer(controller),
          ),
        ),
      ],
    );
  }
}
