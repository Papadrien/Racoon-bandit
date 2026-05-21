import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/game/game_state.dart';
import '../../core/models/card_type.dart';
import '../../core/models/game_card.dart';
import '../../core/models/player_state.dart';
import '../../core/models/result_screen_args.dart';
import '../../core/navigation/app_router.dart';
import '../../core/navigation/navigation_guard.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/progression_service.dart';
import '../../core/services/wakelock_service.dart';
import '../../core/services/stats_service.dart';
import 'package:raccoon_bandit/l10n/app_localizations.dart';
import '../../widgets/player_avatar.dart';
import 'widgets/pince_target_overlay.dart';
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

  bool _showingPinceOverlay = false;
  List<PlayerState> _pinceTargets = [];
  bool _quitDialogOpen = false;

  late final AnimationController _flipController;
  late final AnimationController _slideController;
  // Animation d'apparition subtile (remontée + fade) quand une carte arrive
  late final AnimationController _appearController;
  late final Animation<double> _appearOffset;
  late final Animation<double> _appearOpacity;

  bool _resultScreenOpened = false;

  // ── Navigation guards ──────────────────────────────────────────────────────

  bool get _isCriticalAnimationRunning =>
      _flipController.isAnimating ||
      _slideController.isAnimating ||
      _showingPinceOverlay;

  bool _navigationInProgress = false;

  // Tailles de cartes adaptatives
  double _cardWidth = 160;
  double _cardHeight = 230;
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
    // Animation d'apparition de carte : 180ms, très rapide et premium
    _appearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _appearOffset = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _appearController, curve: Curves.easeOut),
    );
    _appearOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _appearController, curve: Curves.easeOut),
    );
    // Initialiser à 1 (carte visible) — on jouera l'animation à chaque pioche
    _appearController.value = 1.0;
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(WakelockService.disable());
    _flipController.dispose();
    _slideController.dispose();
    _appearController.dispose();
    // Vide la liste avant dispose pour éviter listeners dangling
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
      NavigationGuard.log(_tag, 'init — pas de GameState, redirection home');
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (route) => false,
      );
      return;
    }

    _isAnimating = false;
    _showingPinceOverlay = false;
    _pinceTargets = [];
    _pendingPinceCallback = null;
    _revealedCard = null;
    _effectText = '';
    _resultScreenOpened = false;
    _quitDialogOpen = false;
    _lastResolvedPlayerId = null;
    _navigationInProgress = false;

    _initialized = true;
    unawaited(WakelockService.enable());
  }

  // ── Nettoyage overlays avant navigation ────────────────────────────────────

  void _cleanupBeforeNavigation() {
    NavigationGuard.log(_tag, 'cleanupBeforeNavigation');
    if (!_disposed) {
      _animationsNotifier.value = [];
    }
    _flipController.stop();
    _slideController.stop();
    _showingPinceOverlay = false;
    _pinceTargets = [];
    _pendingPinceCallback = null;
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

    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A1F3D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          l10n.gameQuitDialogTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          l10n.gameQuitDialogContent,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              AudioService.instance.playButtonSound();
              Navigator.of(ctx).pop(false);
            },
            child: Text(
              l10n.gameQuitCancel,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              AudioService.instance.playButtonSound();
              Navigator.of(ctx).pop(true);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent,
            ),
            child: Text(
              l10n.gameQuitConfirm,
              style: const TextStyle(fontWeight: FontWeight.bold),
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
    if (_isAnimating || _showingPinceOverlay || _gameState.isGameOver) return;

    HapticService.trigger(HapticType.light);
    AudioService.instance.playSfx(SoundEffect.piocheCarte);

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

    // Animation d'apparition subtile : la carte remonte légèrement du paquet
    unawaited(_appearController.forward(from: 0));

    await _flipController.forward(from: 0);
    _playCardFeedback(card, result);

    if (result.needsTargetSelection) {
      await _handleTargetSelection(card, result.pendingTargetCardType ?? CardType.pince);
      return;
    }

    _playOverlayAnimations(card, result, foodCountBeforeDraw: foodCountBeforeDraw);

    setState(() {
      _effectText = result.message;
    });

    final bool isRaccoonEffect =
        card?.type == CardType.raccoon && !result.trashDestroyed && foodCountBeforeDraw > 0;
    await _finishCardAnimation(extraDelay: isRaccoonEffect ? 600 : 0);
  }

  Future<void> _handleTargetSelection(GameCard? card, CardType targetCardType) async {
    final targets = _gameState.pinceValidTargets();

    setState(() {
      _pinceTargets = targets;
      _showingPinceOverlay = true;
    });

    final completer = Completer<PlayerState>();

    void onChosen(PlayerState target) {
      if (!completer.isCompleted) completer.complete(target);
    }

    setState(() {
      _pendingPinceCallback = onChosen;
    });

    final target = await completer.future;

    if (!mounted || _disposed) return;

    final resolution = targetCardType == CardType.pince
        ? _gameState.resolvePince(target)
        : _gameState.resolveTargetedSpecial(targetCardType, target);

    setState(() {
      _showingPinceOverlay = false;
      _pinceTargets = [];
      _pendingPinceCallback = null;
      _effectText = resolution.message;
    });

    // Son bandit joué uniquement en cas de vol effectif
    if (resolution.foodStolen) {
      AudioService.instance.playSfx(SoundEffect.pince);
    }

    _playPinceStealAnimation(
      thiefId: _lastResolvedPlayerId,
      targetId: target.id,
    );

    await _finishCardAnimation();
  }

  void _playPinceStealAnimation({
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

      // Analytics — partie terminée
      final ranking = _gameState.ranking;
      final winner = ranking.isNotEmpty ? ranking.first : null;
      unawaited(AnalyticsService.instance.logGameFinished(
        nombreJoueurs: _gameState.players.length,
        modePagailleActif: _gameState.chaosMode,
        vainqueur: winner?.name ?? 'inconnu',
        dureePartieEstimee: _gameState.sessionStats.cardsPlayed * 8,
      ));

      HapticService.trigger(HapticType.heavy);
      AudioService.instance.playSfx(SoundEffect.popupRecompense);

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

  void Function(PlayerState)? _pendingPinceCallback;

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

    return switch (totalPlayers) {
      2 => (-unit * 0.5) - 6,
      3 => playerIndex <= 1 ? (-unit * 0.5) - 6 : (-unit * 1.5) - 4,
      4 => playerIndex <= 1 ? (-unit * 0.5) - 6 : (-unit * 1.5) - 4,
      _ => 0.0,
    };
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
        return;
      case CardType.trash:
        _overlayCoordinator.playFridgeDeposit(start: start, end: fridgeCenter);
        return;
      case CardType.raccoon:
        if (result.trashDestroyed) {
          _overlayCoordinator.playFridgeImpact(center: fridgeCenter);
        } else if (foodCountBeforeDraw > 0) {
          _overlayCoordinator.playRaccoonDevour(playerCenter: playerCenter, cardCenter: start, foodCount: foodCountBeforeDraw);
        }
        return;
      case CardType.pince:
        if (result.targetPlayerId != null) {
          _playPinceStealAnimation(thiefId: currentPlayerId, targetId: result.targetPlayerId!);
        }
        return;
      case CardType.banquet:
        _overlayCoordinator.playFoodGain(start: start, end: playerCenter);
        Future.delayed(const Duration(milliseconds: 120), () {
          if (mounted) {
            _overlayCoordinator.playFoodGain(start: start, end: playerCenter);
          }
        });
        return;
      case CardType.babyRaccoon:
        if (result.targetPlayerId != null) {
          final targetCenter = _playerFoodCenter(result.targetPlayerId!);
          _overlayCoordinator.playRaccoonDevour(playerCenter: targetCenter, cardCenter: start, foodCount: 2);
        }
        return;
      case CardType.vacuum:
        for (final player in _gameState.players) {
          if (player.id == currentPlayerId || player.foodCount <= 0) continue;
          final targetCenter = _playerFoodCenter(player.id);
          _overlayCoordinator.playFoodSteal(fromTarget: targetCenter, toThief: playerCenter);
        }
        return;
    }
  }

  void _playCardFeedback(GameCard? card, CardResolution result) {
    if (card == null) return;

    switch (card.type) {
      case CardType.trash:
        HapticService.trigger(HapticType.medium);
        AudioService.instance.playSfx(SoundEffect.frigo);
        return;
      case CardType.raccoon:
        HapticService.trigger(HapticType.medium);
        if (result.trashDestroyed) {
          AudioService.instance.playSfx(SoundEffect.fridgeBlock);
        } else {
          AudioService.instance.playSfx(SoundEffect.raccoon);
        }
        return;
      case CardType.pince:
        HapticService.trigger(HapticType.medium);
        if (!result.needsTargetSelection && result.foodStolen) {
          AudioService.instance.playSfx(SoundEffect.pince);
        }
        return;
      case CardType.food:
        HapticService.trigger(HapticType.light);
        AudioService.instance.playSfx(SoundEffect.gainNourriture);
        return;
      case CardType.banquet:
        HapticService.trigger(HapticType.medium);
        AudioService.instance.playBanquetSound();
        return;
      case CardType.babyRaccoon:
        HapticService.trigger(HapticType.medium);
        AudioService.instance.playBabyRaccoonSound();
        return;
      case CardType.vacuum:
        HapticService.trigger(HapticType.heavy);
        AudioService.instance.playVacuumSound();
        return;
    }
  }

  // ── UI builders ──────────────────────────────────────────────────────────

  void _computeCardSize(BoxConstraints constraints) {
    final maxH = constraints.maxHeight * 0.52;
    final maxW = constraints.maxWidth * 0.55;

    _cardHeight = maxH.clamp(180.0, 260.0);
    _cardWidth = (_cardHeight * 0.70).clamp(130.0, 185.0).clamp(0.0, maxW);
  }

  Widget _buildPlayerCard(int index, {double maxWidth = 150}) {
    final player = _gameState.players[index];
    final active = index == _gameState.currentPlayerIndex;

    _playerKeys.putIfAbsent(player.id, GlobalKey.new);
    _foodZoneKeys.putIfAbsent(player.id, GlobalKey.new);
    _fridgeZoneKeys.putIfAbsent(player.id, GlobalKey.new);

    final isCompact = maxWidth < 115;
    final avatarSize = isCompact ? 28.0 : 38.0;
    final nameFontSize = isCompact ? 10.0 : 12.0;
    final emojiFontSize = isCompact ? 12.0 : 15.0;
    final hPad = isCompact ? 5.0 : 9.0;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        key: _playerKeys[player.id],
        padding: EdgeInsets.symmetric(
          horizontal: hPad,
          vertical: 8,
        ),
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
              size: avatarSize,
            ),
            const SizedBox(height: 4),
            Text(
              player.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: nameFontSize,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              key: _foodZoneKeys[player.id],
              alignment: WrapAlignment.center,
              spacing: 1,
              runSpacing: 1,
              children: List.generate(
                player.foodCount,
                (_) => Text('🍎', style: TextStyle(fontSize: emojiFontSize)),
              ),
            ),
            const SizedBox(height: 2),
            Wrap(
              key: _fridgeZoneKeys[player.id],
              alignment: WrapAlignment.center,
              spacing: 1,
              runSpacing: 1,
              children: List.generate(
                player.trashCount,
                (_) => Image.asset(
                  'assets/images/icon_trash.png',
                  width: emojiFontSize * 1.4,
                  height: emojiFontSize * 1.75,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPlayerPositions(BoxConstraints constraints) {
    final sw = constraints.maxWidth;
    final sh = constraints.maxHeight;

    const hMargin = 8.0;
    final topOffset = sh * 0.01 + 44.0;
    final bottomOffset = sh * 0.01;

    final cardMaxW = (sw * 0.38).clamp(100.0, 150.0);

    final positions = {
      2: [
        <String, double>{'top': topOffset, 'left': hMargin},
        <String, double>{'top': topOffset, 'right': hMargin},
      ],
      3: [
        <String, double>{'top': topOffset, 'left': hMargin},
        <String, double>{'top': topOffset, 'right': hMargin},
        <String, double>{'bottom': bottomOffset, 'right': hMargin},
      ],
      4: [
        <String, double>{'top': topOffset, 'left': hMargin},
        <String, double>{'top': topOffset, 'right': hMargin},
        <String, double>{'bottom': bottomOffset, 'left': hMargin},
        <String, double>{'bottom': bottomOffset, 'right': hMargin},
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
        child: _buildPlayerCard(index, maxWidth: cardMaxW),
      );
    });
  }

  Widget _buildCardBackWidget() {
    final id = ProgressionService.progression.selectedCardBackId;
    final assetPath = AppAssets.cardBackAsset(id);
    return Image.asset(
      assetPath,
      fit: BoxFit.fill,
      errorBuilder: (_, a, b) =>
          ColoredBox(color: AppAssets.cardBackFallbackColor(id)),
    );
  }

  Widget _buildDeckCard({required bool backgroundCard}) {
    final deckExhausted = _gameState.remainingCards == 0 && _revealedCard == null;

    return GestureDetector(
      onTap: backgroundCard || deckExhausted ? null : _drawCard,
      child: AnimatedBuilder(
        animation: Listenable.merge([_flipController, _slideController, _appearController]),
        builder: (context, child) {
          final flip = _flipController.value;
          final slide = _slideController.value;
          final angle = flip * math.pi;
          final showFront = angle > math.pi / 2;
          final isBack = !deckExhausted && !(showFront && _revealedCard != null);

          // Masquer la carte lorsqu'elle est presque de profil (angle ≈ π/2)
          // pour éviter le flash de backface visible pendant la rotation 3D.
          final nearEdge = !backgroundCard &&
              angle > math.pi / 2 - 0.08 &&
              angle < math.pi / 2 + 0.08;

          // Animation d'apparition : légère remontée depuis le paquet
          // Appliquée uniquement à la carte principale (pas backgroundCard)
          final appearDy = backgroundCard ? 0.0 : _appearOffset.value * 10.0;
          final appearAlpha = backgroundCard ? 1.0 : _appearOpacity.value;

          return Opacity(
            opacity: nearEdge ? 0.0 : appearAlpha,
            child: Transform.translate(
            offset: backgroundCard
                ? const Offset(0, 0)
                : Offset(0, slide * 600 + appearDy),
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
                            : (showFront && _revealedCard?.type == CardType.raccoon)
                                ? Image.asset(
                                    'assets/images/card_front_raccoon.png',
                                    fit: BoxFit.cover,
                                  )
                                : (showFront && _revealedCard?.type == CardType.trash)
                                    ? Image.asset(
                                        'assets/images/card_front_trash.png',
                                        fit: BoxFit.cover,
                                      )
                                    : (showFront && _revealedCard?.type == CardType.food)
                                        ? Image.asset(
                                            'assets/images/card_front_food.png',
                                            fit: BoxFit.cover,
                                          )
                                        : (showFront && _revealedCard?.type == CardType.pince)
                                            ? Image.asset(
                                                'assets/images/card_front_pince.png',
                                                fit: BoxFit.cover,
                                              )
                                            : ColoredBox(
                                                color: _revealedCard?.color ?? Colors.deepPurple,
                                              ),
                      ),
                      if (!backgroundCard &&
                          !(showFront && (_revealedCard?.type == CardType.raccoon || _revealedCard?.type == CardType.trash || _revealedCard?.type == CardType.food || _revealedCard?.type == CardType.pince)))
                        Center(
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..rotateY(showFront ? math.pi : 0),
                            child: FittedBox(
                              child: Text(
                                deckExhausted
                                    ? ''
                                    : showFront && _revealedCard != null
                                        ? _revealedCard!.emoji
                                        : '',
                                style: TextStyle(
                                  fontSize: (_cardHeight * 0.26).clamp(42.0, 68.0),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ));
        },
      ),
    );
  }

  Widget _buildCenterArea(BoxConstraints constraints) {
    _computeCardSize(constraints);

    final showBackgroundCard = _gameState.remainingCards > 1;
    final titleFontSize = (constraints.maxWidth * 0.062).clamp(14.0, 22.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            AppLocalizations.of(context)!.gameTurnOf(_gameState.currentPlayer.name),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
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
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            _gameState.remainingCards == 0
                ? ''
                : AppLocalizations.of(context)!.gameRemainingCards(_gameState.remainingCards),
            key: ValueKey(_gameState.remainingCards),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 36, maxHeight: 48),
          child: Text(
            _effectText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameplayControlsBar() {
    final bool quitEnabled = !_isAnimating && !_showingPinceOverlay;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: quitEnabled
                ? () async {
                    AudioService.instance.playButtonSound();
                    final confirmed = await _showQuitDialog();
                    if (confirmed && mounted) await _quitToHome();
                  }
                : null,
            icon: const Icon(Icons.exit_to_app, size: 18),
            label: Text(AppLocalizations.of(context)!.gameQuitConfirm),
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
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        NavigationGuard.log(_tag, 'back pressed (PopScope)');
        await _onBackPressed();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1B1525),
        body: SafeArea(
          minimum: const EdgeInsets.only(top: 4, left: 4, right: 4, bottom: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                key: _rootStackKey,
                children: [
                  // ── Fond gameplay ─────────────────────────────────────────
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Stack(
                          children: [
                            ..._buildPlayerPositions(constraints),
                            Center(
                              child: _buildCenterArea(constraints),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Top bar (toujours visible) ────────────────────────────
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _buildGameplayControlsBar(),
                  ),

                  // ── Animations overlay ────────────────────────────────────
                  Positioned.fill(
                    child: GameplayOverlayAnimationManager(
                      animationsNotifier: _animationsNotifier,
                    ),
                  ),

                  // ── Bandit target overlay ─────────────────────────────────
                  if (_showingPinceOverlay && _pendingPinceCallback != null)
                    Positioned.fill(
                      child: PinceTargetOverlay(
                        targets: _pinceTargets,
                        onTargetSelected: _pendingPinceCallback!,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
