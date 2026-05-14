import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/game/game_state.dart';
import '../../core/models/card_type.dart';
import '../../core/models/game_card.dart';
import '../../core/models/player_state.dart';
import '../../core/navigation/app_router.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/haptic_service.dart';
import '../../widgets/player_avatar.dart';
import 'widgets/bandit_target_overlay.dart';
import 'widgets/gameplay_overlay_animation_manager.dart';

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
  final List<GameplayOverlayAnimation> _overlayAnimations = [];
  late final GameplayOverlayCoordinator _overlayCoordinator;
  final GlobalKey _deckKey = GlobalKey();
  final Map<int, GlobalKey> _playerKeys = {};
  int? _lastResolvedPlayerId;

  /// Vrai quand le popup Bandit est affiché : bloque les interactions.
  bool _showingBanditOverlay = false;

  /// Cibles valides pour le Bandit, remplies avant d'afficher le popup.
  List<PlayerState> _banditTargets = [];

  late final AnimationController _flipController;
  late final AnimationController _slideController;

  static const double _cardWidth = 180;
  static const double _cardHeight = 260;
  static const double _cardRadius = 24;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _overlayCoordinator = GameplayOverlayCoordinator(_addOverlayAnimation);
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
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
    if (_isAnimating || _showingBanditOverlay || _gameState.isGameOver) return;

    HapticService.trigger(HapticType.light);
    AudioService.instance.playSfx(SoundEffect.draw);

    setState(() {
      _isAnimating = true;
      _effectText = '';
    });

    _lastResolvedPlayerId = _gameState.currentPlayer.id;

    // Snapshot nourriture AVANT résolution (pour l'animation raton)
    final foodCountBeforeDraw = _gameState.currentPlayer.foodCount;

    final result = _gameState.drawCard();
    final card = _gameState.revealedCard;

    setState(() {
      _revealedCard = card;
    });

    await _flipController.forward(from: 0);
    _playCardFeedback(card, result);

    // ── Cas Bandit : sélection de cible nécessaire ────────────────────────
    if (result.needsTargetSelection) {
      await _handleBanditTargetSelection(card);
      return;
    }

    // ── Animations overlay ────────────────────────────────────────────────
    _playOverlayAnimations(card, result, foodCountBeforeDraw: foodCountBeforeDraw);

    setState(() {
      _effectText = result.message;
    });

    // Délai adapté : raton nécessite plus de temps pour les particules
    final bool isRaccoonEffect =
        card?.type == CardType.raccoon && !result.trashDestroyed && foodCountBeforeDraw > 0;
    await _finishCardAnimation(extraDelay: isRaccoonEffect ? 600 : 0);
  }

  /// Affiche le popup de sélection de cible Bandit,
  /// puis résout le vol et enchaîne l'animation.
  Future<void> _handleBanditTargetSelection(GameCard? card) async {
    final targets = _gameState.banditValidTargets();

    setState(() {
      _banditTargets = targets;
      _showingBanditOverlay = true;
    });

    final completer = Completer<PlayerState>();

    void onChosen(PlayerState target) {
      if (!completer.isCompleted) completer.complete(target);
    }

    setState(() {
      _pendingBanditCallback = onChosen;
    });

    final target = await completer.future;

    final resolution = _gameState.resolveBandit(target);

    setState(() {
      _showingBanditOverlay = false;
      _banditTargets = [];
      _pendingBanditCallback = null;
      _effectText = resolution.message;
    });

    _playBanditStealAnimation(
      thiefId: _lastResolvedPlayerId,
      targetId: target.id,
    );

    await _finishCardAnimation();
  }

  /// Animation de vol nourriture : de la cible vers le voleur.
  void _playBanditStealAnimation({
    required int? thiefId,
    required int targetId,
  }) {
    final targetKey = _playerKeys[targetId];
    final thiefKey = _playerKeys[thiefId];
    if (targetKey == null || thiefKey == null) return;

    final fromTarget = _widgetCenter(targetKey);
    final toThief = _widgetCenter(thiefKey);
    _overlayCoordinator.playFoodSteal(
      fromTarget: fromTarget,
      toThief: toThief,
    );
  }

  /// Slide-out + reset commun à tous les cas de fin de carte.
  Future<void> _finishCardAnimation({int extraDelay = 0}) async {
    final waitMs = 700 + extraDelay;
    await Future<void>.delayed(Duration(milliseconds: waitMs));
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

  /// Callback vers lequel pointe [BanditTargetOverlay] via setState.
  void Function(PlayerState)? _pendingBanditCallback;

  void _addOverlayAnimation(GameplayOverlayAnimation animation) {
    setState(() {
      _overlayAnimations.add(animation);
    });

    Future<void>.delayed(animation.duration + animation.delay, () {
      if (!mounted) return;
      setState(() {
        _overlayAnimations.removeWhere((item) => item.id == animation.id);
      });
    });
  }

  Offset _widgetCenter(GlobalKey key) {
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) {
      return const Offset(200, 300);
    }

    final origin = renderBox.localToGlobal(Offset.zero);

    return Offset(
      origin.dx + (renderBox.size.width / 2) - 36,
      origin.dy + (renderBox.size.height / 2) - 36,
    );
  }

  void _playOverlayAnimations(
    GameCard? card,
    CardResolution result, {
    int foodCountBeforeDraw = 0,
  }) {
    if (card == null) return;

    final start = _widgetCenter(_deckKey);
    final currentPlayerId = _lastResolvedPlayerId;
    final targetKey = _playerKeys[currentPlayerId];

    if (targetKey == null) return;

    final playerCenter = _widgetCenter(targetKey);

    switch (card.type) {
      case CardType.food:
        _overlayCoordinator.playFoodGain(start: start, end: playerCenter);
        break;

      case CardType.trash:
        _overlayCoordinator.playFridgeDeposit(start: start, end: playerCenter);
        break;

      case CardType.raccoon:
        // Raton bloqué par frigo → pas d'animation nourriture
        if (result.trashDestroyed) break;

        // Raton mange → aspirer la nourriture vers la carte
        if (foodCountBeforeDraw > 0) {
          _overlayCoordinator.playRaccoonDevour(
            playerCenter: playerCenter,
            cardCenter: start, // la carte est au centre du deck
            foodCount: foodCountBeforeDraw,
          );
        }
        break;

      case CardType.bandit:
        // Bandit à cible unique : géré dans _handleBanditTargetSelection
        // Bandit sans cible valide : rien
        break;
    }
  }

  void _playCardFeedback(GameCard? card, CardResolution result) {
    if (card == null) return;

    switch (card.type) {
      case CardType.trash:
        HapticService.trigger(HapticType.medium);
        AudioService.instance.playSfx(SoundEffect.trash);
        break;
      case CardType.raccoon:
        HapticService.trigger(HapticType.medium);
        AudioService.instance.playSfx(
          result.trashDestroyed ? SoundEffect.trash : SoundEffect.steal,
        );
        break;
      case CardType.bandit:
        HapticService.trigger(HapticType.medium);
        AudioService.instance.playSfx(SoundEffect.steal);
        break;
      case CardType.food:
        HapticService.trigger(HapticType.light);
        AudioService.instance.playSfx(SoundEffect.cardPlayed);
        break;
    }
  }

  Widget _buildPlayerCard(int index) {
    final player = _gameState.players[index];
    final active = index == _gameState.currentPlayerIndex;

    _playerKeys.putIfAbsent(player.id, GlobalKey.new);

    return Container(
      key: _playerKeys[player.id],
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: active
            ? player.profileColor.withValues(alpha: 0.18)
            : Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: active ? player.profileColor : Colors.white24,
          width: active ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlayerAvatar(
            emoji: player.emoji,
            color: player.profileColor,
            size: 40,
          ),
          const SizedBox(height: 6),
          Text(
            player.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 2,
            children: [
              ...List.generate(player.foodCount, (_) => const Text('🍎')),
              ...List.generate(player.trashCount, (_) => const Text('🧊')),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPlayerPositions() {
    const positions = {
      2: [
        {'top': 12.0, 'left': 12.0},
        {'top': 12.0, 'right': 12.0},
      ],
      3: [
        {'top': 12.0, 'left': 12.0},
        {'top': 12.0, 'right': 12.0},
        {'bottom': 12.0, 'right': 12.0},
      ],
      4: [
        {'top': 12.0, 'left': 12.0},
        {'top': 12.0, 'right': 12.0},
        {'bottom': 12.0, 'left': 12.0},
        {'bottom': 12.0, 'right': 12.0},
      ],
    };

    final layout = positions[_gameState.players.length]!;

    return List.generate(_gameState.players.length, (index) {
      final pos = layout[index];
      return Positioned(
        top: pos['top'],
        left: pos['left'],
        right: pos['right'],
        bottom: pos['bottom'],
        child: _buildPlayerCard(index),
      );
    });
  }

  Widget _buildDeckCard({required bool backgroundCard}) {
    final empty = _gameState.remainingCards == 0;

    return GestureDetector(
      onTap: backgroundCard || empty ? null : _drawCard,
      child: AnimatedBuilder(
        animation: Listenable.merge([_flipController, _slideController]),
        builder: (context, child) {
          final flip = _flipController.value;
          final slide = _slideController.value;
          final angle = flip * math.pi;
          final showFront = angle > math.pi / 2;
          final isBack = !empty && !(showFront && _revealedCard != null);

          return Transform.translate(
            offset: backgroundCard
                ? const Offset(0, 0)
                : Offset(0, slide * 600),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(backgroundCard ? 0 : angle),
              child: SizedBox(
                width: _cardWidth,
                height: _cardHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_cardRadius),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned.fill(
                        child: isBack || backgroundCard
                            ? Image.asset(
                                AppAssets.cardBackPurple,
                                fit: BoxFit.fill,
                              )
                            : ColoredBox(
                                color: _revealedCard?.color ?? Colors.deepPurple,
                              ),
                      ),
                      if (!backgroundCard)
                        Center(
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..rotateY(showFront ? math.pi : 0),
                            child: Text(
                              empty
                                  ? ''
                                  : showFront && _revealedCard != null
                                      ? _revealedCard!.emoji
                                      : '',
                              style: const TextStyle(fontSize: 68),
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

  Widget _buildCenterArea() {
    // Carte du dessous visible uniquement si ≥ 2 cartes restantes
    // ET qu'on n'est pas en train d'animer la dernière carte.
    final showBackgroundCard = _gameState.remainingCards > 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Tour de ${_gameState.currentPlayer.name}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          key: _deckKey,
          width: _cardWidth + 16,
          height: _cardHeight + 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Carte fantôme dessous : visible dès 2 cartes, disparaît proprement
              if (showBackgroundCard)
                Transform.translate(
                  offset: const Offset(0, 6),
                  child: Opacity(
                    // Opacité plus forte pour mieux simuler une vraie pile
                    opacity: 0.65,
                    child: _buildDeckCard(backgroundCard: true),
                  ),
                ),
              _buildDeckCard(backgroundCard: false),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            _gameState.remainingCards == 0
                ? ''
                : '${_gameState.remainingCards} carte${_gameState.remainingCards > 1 ? 's' : ''}',
            key: ValueKey(_gameState.remainingCards),
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: Text(
            _effectText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      child: TextButton(
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.home,
                          (route) => false,
                        ),
                        child: const Text('Accueil'),
                      ),
                    ),
                    ..._buildPlayerPositions(),
                    Center(child: _buildCenterArea()),
                  ],
                ),
              ),
            ),
            GameplayOverlayAnimationManager(animations: _overlayAnimations),

            // ── Popup Bandit : sélection de cible ─────────────────────────
            if (_showingBanditOverlay && _pendingBanditCallback != null)
              Positioned.fill(
                child: BanditTargetOverlay(
                  targets: _banditTargets,
                  onTargetSelected: _pendingBanditCallback!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
