import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/game/game_state.dart';
import '../../core/models/card_type.dart';
import '../../core/models/game_card.dart';
import '../../core/models/player_state.dart';
import '../../core/models/result_screen_args.dart';
import '../../core/navigation/app_router.dart';
import '../../core/navigation/navigation_guard.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/game_save_service.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/progression_service.dart';
import '../../core/services/wakelock_service.dart';
import '../../core/services/stats_service.dart';
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

  /// Guard contre les appels asynchrones post-dispose.
  bool _disposed = false;

  bool _isAnimating = false;
  String _effectText = '';
  GameCard? _revealedCard;

  late final ValueNotifier<List<GameplayOverlayAnimation>> _animationsNotifier;
  late final GameplayOverlayCoordinator _overlayCoordinator;

  final GlobalKey _deckKey = GlobalKey();
  final Map<int, GlobalKey> _playerKeys = {};
  final Map<int, GlobalKey> _foodZoneKeys = {};
  final Map<int, GlobalKey> _fridgeZoneKeys = {};
  final GlobalKey _rootStackKey = GlobalKey();
  int? _lastResolvedPlayerId;

  bool _showingBanditOverlay = false;
  List<PlayerState> _banditTargets = [];
  bool _quitDialogOpen = false;

  late final AnimationController _flipController;
  late final AnimationController _slideController;

  bool _resultScreenOpened = false;

  // ── Navigation guards ──────────────────────────────────────────────────────

  /// Vrai pendant une animation critique où le retour Android doit être bloqué.
  bool get _isCriticalAnimationRunning =>
      _flipController.isAnimating ||
      _slideController.isAnimating ||
      _showingBanditOverlay;

  /// Empêche les double-pop et navigations simultanées.
  bool _navigationInProgress = false;

  static const double _cardWidth = 180;
  static const double _cardHeight = 260;
  static const double _cardRadius = 24;
  static const String _tag = 'GameScreen';

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _animationsNotifier = ValueNotifier<List<GameplayOverlayAnimation>>([]);
    _overlayCoordinator = GameplayOverlayCoordinator(_animationsNotifier);
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 275),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(WakelockService.disable());
    _flipController.dispose();
    _slideController.dispose();
    _animationsNotifier.value = [];
    _animationsNotifier.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _restoreOrInitGame();
    }
  }

  // ── Init ───────────────────────────────────────────────────────────────────

  void _restoreOrInitGame() {
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is GameState) {
      _gameState = args;
      NavigationGuard.log(_tag, 'init — nouvelle partie, ${_gameState.players.length} joueurs');
    } else {
      final save = GameSaveService.current;
      if (save != null) {
        _gameState = GameState.fromSave(save);
        NavigationGuard.log(
          _tag,
          'init — reprise depuis sauvegarde, '
          'joueur: ${_gameState.currentPlayerIndex}, '
          'deck: ${_gameState.remainingCards} cartes',
        );
      } else {
        NavigationGuard.log(_tag, 'init — pas de sauvegarde, redirection home');
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => false,
        );
        return;
      }
    }

    _isAnimating = false;
    _showingBanditOverlay = false;
    _banditTargets = [];
    _pendingBanditCallback = null;
    _revealedCard = null;
    _effectText = '';
    _resultScreenOpened = false;
    _quitDialogOpen = false;
    _lastResolvedPlayerId = null;
    _navigationInProgress = false;

    _initialized = true;
    unawaited(WakelockService.enable());
  }

  // ── Sauvegarde automatique ─────────────────────────────────────────────────

  void _autoSave() {
    if (_gameState.isGameOver) return;
    if (_showingBanditOverlay) return;
    if (_disposed) return;
    unawaited(GameSaveService.save(_gameState.toSave()));
  }

  // ── Nettoyage overlays avant navigation ────────────────────────────────────

  void _cleanupBeforeNavigation() {
    NavigationGuard.log(_tag, 'cleanupBeforeNavigation');
    if (!_disposed) {
      _animationsNotifier.value = [];
    }
    _flipController.stop();
    _slideController.stop();
    _showingBanditOverlay = false;
    _banditTargets = [];
    _pendingBanditCallback = null;
    _quitDialogOpen = false;
  }

  // ── Quit confirmation ──────────────────────────────────────────────────────

  Future<bool> _showQuitDialog() async {
    if (_isCriticalAnimationRunning) {
      NavigationGuard.log(_tag, 'navigation blocked — animation critique en cours');
      return false;
    }
    if (_quitDialogOpen) {
      NavigationGuard.log(_tag, 'dialog opened — déjà ouvert, bloqué');
      return false;
    }

    NavigationGuard.log(_tag, 'dialog opened — quit confirmation');
    setState(() => _quitDialogOpen = true);

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A1F3D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Quitter la partie ?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'La partie en cours sera perdue.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Annuler',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent,
            ),
            child: const Text(
              'Quitter',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (!mounted) {
      NavigationGuard.log(_tag, 'dialog closed — widget démonté');
      return false;
    }

    NavigationGuard.log(
      _tag,
      'dialog closed — résultat: ${confirmed == true ? "quitter" : "annuler"}',
    );
    setState(() => _quitDialogOpen = false);
    return confirmed ?? false;
  }

  Future<void> _quitToHome() async {
    if (_navigationInProgress) {
      NavigationGuard.log(_tag, 'quitToHome — bloqué: navigation déjà en cours');
      return;
    }
    if (!mounted) return;

    _navigationInProgress = true;
    NavigationGuard.log(_tag, 'gameplay exited — quit to home');

    _cleanupBeforeNavigation();

    await GameSaveService.clear();
    if (!mounted) {
      _navigationInProgress = false;
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (route) => false,
    );
  }

  // ── Back button Android ────────────────────────────────────────────────────

  /// Gestionnaire unique du retour Android.
  ///
  /// Ordre de vérification :
  /// 1. Animation critique → bloqué
  /// 2. Dialog déjà ouvert → bloqué (anti double-dialog)
  /// 3. Navigation en cours → bloqué (anti double-pop)
  /// 4. Sinon → confirmation quitter
  Future<void> _onBackPressed() async {
    NavigationGuard.log(_tag, 'back pressed');

    if (_isCriticalAnimationRunning) {
      NavigationGuard.log(_tag, 'navigation blocked — animation critique');
      return;
    }
    if (_quitDialogOpen) {
      NavigationGuard.log(_tag, 'navigation blocked — dialog déjà ouvert');
      return;
    }
    if (_navigationInProgress) {
      NavigationGuard.log(_tag, 'navigation blocked — navigation en cours');
      return;
    }

    final confirmed = await _showQuitDialog();
    if (confirmed && mounted) await _quitToHome();
  }

  // ── Game logic ─────────────────────────────────────────────────────────────

  Future<void> _drawCard() async {
    if (_isAnimating || _showingBanditOverlay || _gameState.isGameOver) return;

    HapticService.trigger(HapticType.light);
    AudioService.instance.playSfx(SoundEffect.draw);

    setState(() {
      _isAnimating = true;
      _effectText = '';
    });

    _lastResolvedPlayerId = _gameState.currentPlayer.id;
    final foodCountBeforeDraw = _gameState.currentPlayer.foodCount;

    final result = _gameState.drawCard();
    final card = _gameState.revealedCard;

    setState(() {
      _revealedCard = card;
    });

    await _flipController.forward(from: 0);
    _playCardFeedback(card, result);

    if (result.needsTargetSelection) {
      await _handleBanditTargetSelection(card);
      return;
    }

    _playOverlayAnimations(card, result, foodCountBeforeDraw: foodCountBeforeDraw);

    setState(() {
      _effectText = result.message;
    });

    _autoSave();

    final bool isRaccoonEffect =
        card?.type == CardType.raccoon && !result.trashDestroyed && foodCountBeforeDraw > 0;
    await _finishCardAnimation(extraDelay: isRaccoonEffect ? 600 : 0);
  }

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

    if (!mounted || _disposed) return;

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

    _autoSave();
    await _finishCardAnimation();
  }

  void _playBanditStealAnimation({
    required int? thiefId,
    required int targetId,
  }) {
    final fromTarget = _playerFoodCenter(targetId);
    final toThief = _playerFoodCenter(thiefId ?? -1);

    if (fromTarget == Offset.zero || toThief == Offset.zero) return;
    _overlayCoordinator.playFoodSteal(
      fromTarget: fromTarget,
      toThief: toThief,
    );
  }

  Future<void> _finishCardAnimation({int extraDelay = 0}) async {
    final waitMs = 700 + extraDelay;
    await Future<void>.delayed(Duration(milliseconds: waitMs));

    if (!mounted || _disposed) return;

    await _slideController.forward(from: 0);

    if (!mounted || _disposed) return;

    setState(() {
      _revealedCard = null;
      _isAnimating = false;
    });

    _flipController.reset();
    _slideController.reset();

    if (_gameState.isGameOver && mounted && !_resultScreenOpened) {
      _resultScreenOpened = true;
      _navigationInProgress = true;
      NavigationGuard.log(_tag, 'gameplay exited — game over, vers result screen');

      _cleanupBeforeNavigation();

      final navigator = Navigator.of(context);

      final newUnlocks = await ProgressionService.registerCompletedGame();
      await StatsService.registerGame(_gameState);

      await GameSaveService.clear();
      HapticService.trigger(HapticType.heavy);
      AudioService.instance.playSfx(SoundEffect.gameOver);

      if (!mounted || _disposed) return;

      unawaited(
        navigator.pushReplacementNamed(
          AppRoutes.result,
          arguments: ResultScreenArgs(
            gameState: _gameState,
            newUnlocks: newUnlocks,
          ),
        ),
      );
    }
  }

  void Function(PlayerState)? _pendingBanditCallback;

  Offset _widgetCenter(GlobalKey key, {double? verticalBias}) {
    final ctx = key.currentContext;
    if (ctx == null) return Offset.zero;

    final renderObject = ctx.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize) {
      return Offset.zero;
    }

    final renderBox = renderObject;
    final overlay = Overlay.of(ctx).context.findRenderObject();
    if (overlay is! RenderBox || !overlay.hasSize) {
      return Offset.zero;
    }

    var center = renderBox.localToGlobal(
      Offset(renderBox.size.width / 2, renderBox.size.height / 2),
      ancestor: overlay,
    );

    if (verticalBias != null) {
      center = Offset(center.dx, center.dy + verticalBias);
    }

    final overlaySize = overlay.size;
    return Offset(
      center.dx.clamp(36.0, overlaySize.width - 36.0),
      center.dy.clamp(36.0, overlaySize.height - 36.0),
    );
  }

  double _playerVerticalBias(int playerIndex) {
    final screenHeight = MediaQuery.of(context).size.height;
    final unit = screenHeight * 0.04;
    final totalPlayers = _gameState.players.length;

    switch (totalPlayers) {
      case 2:
        return -unit * 0.5;
      case 3:
        if (playerIndex <= 1) return -unit * 0.5;
        return -unit * 1.5;
      case 4:
        if (playerIndex <= 1) return -unit * 0.5;
        return -unit * 1.5;
      default:
        return 0;
    }
  }

  Offset _playerFoodCenter(int playerId) {
    final idx = _gameState.players.indexWhere((p) => p.id == playerId);
    if (idx < 0) return Offset.zero;
    final key = _foodZoneKeys[playerId] ?? _playerKeys[playerId];
    if (key == null) return Offset.zero;
    return _widgetCenter(key, verticalBias: _playerVerticalBias(idx));
  }

  Offset _playerFridgeCenter(int playerId) {
    final idx = _gameState.players.indexWhere((p) => p.id == playerId);
    if (idx < 0) return Offset.zero;
    final key = _fridgeZoneKeys[playerId] ?? _playerKeys[playerId];
    if (key == null) return Offset.zero;
    return _widgetCenter(key, verticalBias: _playerVerticalBias(idx));
  }

  void _playOverlayAnimations(
    GameCard? card,
    CardResolution result, {
    int foodCountBeforeDraw = 0,
  }) {
    if (card == null) return;

    final start = _widgetCenter(_deckKey);
    if (start == Offset.zero) return;

    final currentPlayerId = _lastResolvedPlayerId;
    if (currentPlayerId == null) return;

    final playerCenter = _playerFoodCenter(currentPlayerId);
    final fridgeCenter = _playerFridgeCenter(currentPlayerId);

    switch (card.type) {
      case CardType.food:
        _overlayCoordinator.playFoodGain(start: start, end: playerCenter);
        break;

      case CardType.trash:
        _overlayCoordinator.playFridgeDeposit(start: start, end: fridgeCenter);
        break;

      case CardType.raccoon:
        if (result.trashDestroyed) {
          _overlayCoordinator.playFridgeImpact(center: fridgeCenter);
          break;
        }
        if (foodCountBeforeDraw > 0) {
          _overlayCoordinator.playRaccoonDevour(
            playerCenter: playerCenter,
            cardCenter: start,
            foodCount: foodCountBeforeDraw,
          );
        }
        break;

      case CardType.bandit:
        if (result.targetPlayerId != null) {
          _playBanditStealAnimation(
            thiefId: currentPlayerId,
            targetId: result.targetPlayerId!,
          );
        }
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

  // ── UI builders ────────────────────────────────────────────────────────────

  Widget _buildPlayerCard(int index) {
    final player = _gameState.players[index];
    final active = index == _gameState.currentPlayerIndex;

    _playerKeys.putIfAbsent(player.id, GlobalKey.new);
    _foodZoneKeys.putIfAbsent(player.id, GlobalKey.new);
    _fridgeZoneKeys.putIfAbsent(player.id, GlobalKey.new);

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
          const SizedBox(height: 2),
          Wrap(
            key: _foodZoneKeys[player.id],
            alignment: WrapAlignment.center,
            spacing: 2,
            children: [
              ...List.generate(player.foodCount, (_) => const Text('🍎')),
            ],
          ),
          const SizedBox(height: 2),
          Wrap(
            key: _fridgeZoneKeys[player.id],
            alignment: WrapAlignment.center,
            spacing: 2,
            children: [
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
        {'top': 52.0, 'left': 12.0},
        {'top': 52.0, 'right': 12.0},
      ],
      3: [
        {'top': 52.0, 'left': 12.0},
        {'top': 52.0, 'right': 12.0},
        {'bottom': 12.0, 'right': 12.0},
      ],
      4: [
        {'top': 52.0, 'left': 12.0},
        {'top': 52.0, 'right': 12.0},
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

  Widget _buildCardBackWidget() {
    final id = ProgressionService.progression.selectedCardBackId;
    final assetPath = AppAssets.cardBackAsset(id);

    if (assetPath != null) {
      return Image.asset(assetPath, fit: BoxFit.fill);
    }
    return ColoredBox(color: AppAssets.cardBackFallbackColor(id));
  }

  Widget _buildDeckCard({required bool backgroundCard}) {
    final deckExhausted = _gameState.remainingCards == 0 && _revealedCard == null;

    return GestureDetector(
      onTap: backgroundCard || deckExhausted ? null : _drawCard,
      child: AnimatedBuilder(
        animation: Listenable.merge([_flipController, _slideController]),
        builder: (context, child) {
          final flip = _flipController.value;
          final slide = _slideController.value;
          final angle = flip * math.pi;
          final showFront = angle > math.pi / 2;
          final isBack = !deckExhausted && !(showFront && _revealedCard != null);

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
                            ? _buildCardBackWidget()
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
                              deckExhausted
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
              if (showBackgroundCard)
                Transform.translate(
                  offset: const Offset(0, 6),
                  child: Opacity(
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

  Widget _buildGameplayControlsBar() {
    // Désactivé pendant toute animation ET overlay Bandit.
    final bool quitEnabled = !_isAnimating && !_showingBanditOverlay;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: quitEnabled
                ? () async {
                    final confirmed = await _showQuitDialog();
                    if (confirmed && mounted) await _quitToHome();
                  }
                : null,
            icon: const Icon(Icons.exit_to_app, size: 18),
            label: const Text('Quitter'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
              disabledForegroundColor: Colors.white24,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.white24),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return PopScope(
      // canPop: false → on intercepte TOUJOURS le retour Android.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        NavigationGuard.log(_tag, 'back pressed (PopScope)');
        await _onBackPressed();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1B1525),
        body: SafeArea(
          child: Stack(
            key: _rootStackKey,
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Stack(
                      children: [
                        ..._buildPlayerPositions(),
                        Center(child: _buildCenterArea()),
                      ],
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildGameplayControlsBar(),
              ),

              Positioned.fill(
                child: GameplayOverlayAnimationManager(
                  animationsNotifier: _animationsNotifier,
                ),
              ),

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
      ),
    );
  }
}
