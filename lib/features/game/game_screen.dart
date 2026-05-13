import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/game/game_state.dart';
import '../../core/models/card_type.dart';
import '../../core/models/game_card.dart';
import '../../core/navigation/app_router.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/haptic_service.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin {
  late GameState _gameState;
  bool _initialized = false;
  bool _isAnimating = false;
  String _effectText = '';
  GameCard? _revealedCard;

  late final AnimationController _flipController;
  late final AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _gameState = ModalRoute.of(context)!.settings.arguments as GameState;
      _initialized = true;
    }
  }

  Future<void> _drawCard() async {
    if (_isAnimating || _gameState.isGameOver) return;

    HapticService.trigger(HapticType.light);
    AudioService.instance.playSfx(SoundEffect.draw);

    setState(() {
      _isAnimating = true;
      _effectText = '';
    });

    final result = _gameState.drawCard();
    final card = _gameState.revealedCard;

    setState(() {
      _revealedCard = card;
    });

    await _flipController.forward(from: 0);

    // Son + haptic selon l'effet de la carte
    _playCardFeedback(card, result);

    setState(() {
      _effectText = result.message;
    });

    await Future<void>.delayed(const Duration(seconds: 1));

    await _slideController.forward(from: 0);

    if (!mounted) return;

    setState(() {
      _revealedCard = null;
      _isAnimating = false;
    });

    _flipController.reset();
    _slideController.reset();

    if (_gameState.isGameOver && mounted) {
      HapticService.trigger(HapticType.heavy);
      AudioService.instance.playSfx(SoundEffect.gameOver);
      unawaited(
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.result,
          arguments: _gameState,
        ),
      );
    }
  }

  void _playCardFeedback(GameCard? card, CardResolution result) {
    if (card == null) return;

    switch (card.type) {
      case CardType.trash:
        HapticService.trigger(HapticType.medium);
        AudioService.instance.playSfx(SoundEffect.trash);
      case CardType.raccoon:
        HapticService.trigger(HapticType.medium);
        if (result.trashDestroyed) {
          AudioService.instance.playSfx(SoundEffect.trash);
        } else {
          AudioService.instance.playSfx(SoundEffect.steal);
        }
      case CardType.bandit:
        HapticService.trigger(HapticType.medium);
        AudioService.instance.playSfx(SoundEffect.steal);
      case CardType.food:
        HapticService.trigger(HapticType.light);
        AudioService.instance.playSfx(SoundEffect.cardPlayed);
    }
  }

  Widget _buildPlayerCard(int index) {
    final player = _gameState.players[index];
    final active = index == _gameState.currentPlayerIndex;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: active
            ? Colors.deepPurple.withValues(alpha: 0.35)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? Colors.deepPurpleAccent : Colors.white24,
          width: active ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: player.avatarColor,
            child: Icon(player.avatarIcon, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    ...List.generate(
                      player.foodCount,
                      (_) => const Text('🍎'),
                    ),
                    ...List.generate(
                      player.trashCount,
                      (_) => const Text('🗑️'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Dimensions de la carte — une seule source de vérité
  static const double _cardWidth = 240;
  static const double _cardHeight = 340;
  static const double _cardRadius = 24;

  Widget _buildDeck() {
    final empty = _gameState.remainingCards == 0;

    return GestureDetector(
      onTap: empty ? null : _drawCard,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _flipController,
          _slideController,
        ]),
        builder: (context, child) {
          final flip = _flipController.value;
          final slide = _slideController.value;

          final angle = flip * math.pi;
          final showFront = angle > math.pi / 2;
          final isBack = !empty && !(showFront && _revealedCard != null);

          return Transform.translate(
            offset: Offset(0, slide * 300),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: SizedBox(
                width: _cardWidth,
                height: _cardHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_cardRadius),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Dos de carte : image officielle violette
                      if (isBack)
                        Image.asset(
                          AppAssets.cardBackPurple,
                          fit: BoxFit.cover,
                          width: _cardWidth,
                          height: _cardHeight,
                        )
                      else
                        // Face de carte ou état vide (deck épuisé)
                        ColoredBox(
                          color: empty
                              ? Colors.grey.shade800
                              : _revealedCard?.color ?? Colors.deepPurple,
                        ),
                      // Contenu centré (emoji ou X) — contre-rotation pour rester lisible
                      Center(
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..rotateY(showFront ? math.pi : 0),
                          child: Text(
                            empty
                                ? '✕'
                                : showFront && _revealedCard != null
                                    ? _revealedCard!.emoji
                                    : '',
                            style: const TextStyle(fontSize: 72),
                          ),
                        ),
                      ),
                      // Bordure par-dessus tout
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(_cardRadius),
                          border: Border.all(
                            color: Colors.white24,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1B1525),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.home,
                      (route) => false,
                    ),
                    child: const Text('Accueil'),
                  ),
                  Text(
                    '${_gameState.remainingCards} cartes',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Tour de ${_gameState.currentPlayer.name}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: _gameState.players.length,
                  itemBuilder: (context, index) => _buildPlayerCard(index),
                ),
              ),
              SizedBox(
                height: 40,
                child: Center(
                  child: Text(
                    _effectText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildDeck(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
