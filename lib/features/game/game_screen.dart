import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/game/card_resolution_message.dart';
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
import '../../core/services/stats_service.dart';
import '../../core/services/wakelock_service.dart';
import '../../core/ui/app_colors.dart';
import 'package:raccoon_bandit/l10n/app_localizations.dart';
import 'dialogs/quit_game_dialog.dart';
import 'widgets/game_background_stickers.dart';
import 'widgets/game_center_area.dart';
import 'widgets/game_controls_bar.dart';
import 'widgets/game_player_card.dart';
import 'widgets/gameplay_overlay_animation_manager.dart';
import 'widgets/pince_target_overlay.dart';

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
  // Nom du joueur affiché pendant l'animation (pour ne pas sauter visuellement)
  String? _displayPlayerName;
  // Joueur affiché sur le sticker de la carte à piocher (ne change qu'après le slide)
  PlayerState? _deckStickerPlayer;

  bool _showingPinceOverlay = false;
  List<PlayerState> _pinceTargets = [];

  /// Snapshot des stocks (nourriture + poubelles) capturés avant drawCard/resolve.
  /// Utilisés pour afficher les anciennes valeurs pendant les particules,
  /// jusqu'au début du slide de retrait de la carte.
  Map<int, int> _snapshotFoodCounts = {};
  Map<int, int> _snapshotTrashCounts = {};
  bool _useStockSnapshot = false;
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
      duration: const Duration(milliseconds: 420),
    );
    _animationsNotifier = ValueNotifier<List<GameplayOverlayAnimation>>([]);
    _overlayCoordinator = GameplayOverlayCoordinator(_animationsNotifier);
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 330),
    );
    // Animation d'apparition de carte : 216ms (+20%)
    _appearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 216),
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
    // Précache les icônes sticker des faces de cartes.
    for (final type in CardType.values) {
      precacheImage(AssetImage(AppAssets.cardFrontIcon(type)), context);
    }
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
    _snapshotFoodCounts = {};
    _snapshotTrashCounts = {};
    _useStockSnapshot = false;
    _pendingPinceCallback = null;
    _revealedCard = null;
    _effectText = '';
    _resultScreenOpened = false;
    _quitDialogOpen = false;
    _lastResolvedPlayerId = null;
    _navigationInProgress = false;

    _displayPlayerName = null;
    _deckStickerPlayer = null;
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

    final confirmed = await showQuitGameDialog(context);

    if (!mounted) {
      NavigationGuard.log(_tag, 'dialog closed — widget démonté');
      return false;
    }

    NavigationGuard.log(
      _tag,
      'dialog closed — résultat: ${confirmed ? "quitter" : "annuler"}',
    );
    setState(() => _quitDialogOpen = false);
    return confirmed;
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

  String _resolveEffectMessage(CardEffectMessage msg) {
    final l10n = AppLocalizations.of(context)!;
    switch (msg.key) {
      case CardEffectKey.gameOver:
        return l10n.gameEffectGameOver;
      case CardEffectKey.foodGained:
        return l10n.gameEffectFoodGained(msg.playerName ?? '');
      case CardEffectKey.trashSecured:
        return l10n.gameEffectTrashSecured(msg.playerName ?? '');
      case CardEffectKey.raccoonBlocked:
        return l10n.gameEffectRaccoonBlocked;
      case CardEffectKey.raccoonDevours:
        return l10n.gameEffectRaccoonDevours(msg.playerName ?? '');
      case CardEffectKey.banquet:
        return l10n.gameEffectBanquet(msg.playerName ?? '');
      case CardEffectKey.babyRaccoonDevours:
        return l10n.gameEffectBabyRaccoonDevours(msg.count ?? 0, msg.targetName ?? '');
      case CardEffectKey.babyRaccoonEmpty:
        return l10n.gameEffectBabyRaccoonEmpty;
      case CardEffectKey.vacuumSteals:
        return l10n.gameEffectVacuumSteals(msg.playerName ?? '', msg.count ?? 0);
      case CardEffectKey.vacuumEmpty:
        return l10n.gameEffectVacuumEmpty;
      case CardEffectKey.pinceNoTarget:
        return l10n.gameEffectPinceNoTarget(msg.playerName ?? '');
      case CardEffectKey.pinceSteal:
        return l10n.gameEffectPinceSteal(msg.playerName ?? '', msg.targetName ?? '');
      case CardEffectKey.none:
        return '';
    }
  }

  Future<void> _drawCard() async {
    if (_isAnimating || _showingPinceOverlay || _gameState.isGameOver) return;

    HapticService.trigger(HapticType.light);
    AudioService.instance.playSfx(SoundEffect.piocheCarte);

    setState(() {
      _isAnimating = true;
      _effectText = '';
    });

    _lastResolvedPlayerId = _gameState.currentPlayer.id;
    final String currentPlayerNameSnapshot = _gameState.currentPlayer.name;
    final foodCountBeforeDraw = _gameState.currentPlayer.foodCount;
    final PlayerState currentPlayerSnapshot = _gameState.currentPlayer;

    final Map<int, int> foodSnapshot = {
      for (final p in _gameState.players) p.id: p.foodCount,
    };
    final Map<int, int> trashSnapshot = {
      for (final p in _gameState.players) p.id: p.trashCount,
    };

    final result = _gameState.drawCard();
    final card = _gameState.revealedCard;

    final bool shouldFreezeStocks = _shouldFreezeStocksForCard(card, result);

    setState(() {
      _revealedCard = card;
      _displayPlayerName = currentPlayerNameSnapshot;
      _deckStickerPlayer = currentPlayerSnapshot;
      if (shouldFreezeStocks) {
        _snapshotFoodCounts = foodSnapshot;
        _snapshotTrashCounts = trashSnapshot;
        _useStockSnapshot = true;
      }
    });

    if (card != null) {
      await precacheImage(AssetImage(AppAssets.cardFrontIcon(card.type)), context);
    }

    await _flipController.forward(from: 0);
    _playCardFeedback(card, result);

    if (result.needsTargetSelection) {
      await _handleTargetSelection(card, result.pendingTargetCardType ?? CardType.pince);
      return;
    }

    _playOverlayAnimations(card, result, foodCountBeforeDraw: foodCountBeforeDraw);

    setState(() {
      _effectText = _resolveEffectMessage(result.effectMessage);
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

    final Map<int, int> foodSnapshot = {
      for (final p in _gameState.players) p.id: p.foodCount,
    };
    final Map<int, int> trashSnapshot = {
      for (final p in _gameState.players) p.id: p.trashCount,
    };

    final resolution = targetCardType == CardType.pince
        ? _gameState.resolvePince(target)
        : _gameState.resolveTargetedSpecial(targetCardType, target);

    setState(() {
      _showingPinceOverlay = false;
      _pinceTargets = [];
      _pendingPinceCallback = null;
      _effectText = _resolveEffectMessage(resolution.effectMessage);
      if (resolution.foodStolen) {
        _snapshotFoodCounts = foodSnapshot;
        _snapshotTrashCounts = trashSnapshot;
        _useStockSnapshot = true;
      }
    });

    if (resolution.foodStolen) {
      AudioService.instance.playSfx(SoundEffect.pince);
    }

    _playPinceStealAnimation(
      thiefId: _lastResolvedPlayerId,
      targetId: target.id,
    );

    await _finishCardAnimation();
  }

  /// Détermine si on doit figer les stocks pendant les particules.
  bool _shouldFreezeStocksForCard(GameCard? card, CardResolution result) {
    if (card == null) return false;
    switch (card.type) {
      case CardType.food:
      case CardType.trash:
      case CardType.banquet:
        return true;
      case CardType.vacuum:
        return result.foodStolen;
      case CardType.pince:
        return !result.needsTargetSelection && result.foodStolen;
      case CardType.raccoon:
      case CardType.babyRaccoon:
        return false;
    }
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
    final waitMs = 840 + (extraDelay * 1.2).round();
    await Future<void>.delayed(Duration(milliseconds: waitMs));

    if (!mounted || _disposed) return;

    if (_useStockSnapshot) {
      setState(() {
        _useStockSnapshot = false;
        _snapshotFoodCounts = {};
        _snapshotTrashCounts = {};
      });
    }

    await _slideController.forward(from: 0);

    if (!mounted || _disposed) return;

    setState(() {
      _revealedCard = null;
      _isAnimating = false;
      _displayPlayerName = null;
      _deckStickerPlayer = null;
    });

    _flipController.reset();
    _slideController.reset();

    if (!_gameState.isGameOver) {
      unawaited(_appearController.forward(from: 0));
    }

    if (_gameState.isGameOver && mounted && !_resultScreenOpened) {
      _resultScreenOpened = true;
      _navigationInProgress = true;
      NavigationGuard.log(_tag, 'gameplay exited — game over, vers result screen');

      _cleanupBeforeNavigation();

      final navigator = Navigator.of(context);

      final newUnlocks = await ProgressionService.registerCompletedGame();
      await StatsService.registerGame(_gameState);

      final ranking = _gameState.ranking;
      final winner = ranking.isNotEmpty ? ranking.first : null;
      unawaited(AnalyticsService.instance.logGameFinished(
        nombreJoueurs: _gameState.players.length,
        modePagailleActif: _gameState.chaosMode,
        vainqueur: winner?.name ?? 'inconnu',
        dureePartieEstimee: _gameState.sessionStats.cardsPlayed * 8,
      ));

      HapticService.trigger(HapticType.heavy);
      if (newUnlocks.isEmpty) {
        AudioService.instance.playSfx(SoundEffect.popupRecompense);
      }

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
        AudioService.instance.playSfx(SoundEffect.gainNourriture);
        return;
      case CardType.babyRaccoon:
        HapticService.trigger(HapticType.medium);
        AudioService.instance.playSfx(SoundEffect.raccoon);
        return;
      case CardType.vacuum:
        HapticService.trigger(HapticType.heavy);
        AudioService.instance.playSfx(SoundEffect.pince);
        return;
    }
  }

  // ── Overlay animations & coordinate helpers ────────────────────────────────

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
    final screenHeight = MediaQuery.sizeOf(context).height;
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
          _overlayCoordinator.playRaccoonDevour(
            playerCenter: playerCenter,
            cardCenter: start,
            foodCount: foodCountBeforeDraw,
          );
        }
        return;
      case CardType.pince:
        if (result.targetPlayerId != null) {
          _playPinceStealAnimation(
            thiefId: currentPlayerId,
            targetId: result.targetPlayerId!,
          );
        }
        return;
      case CardType.banquet:
        _overlayCoordinator.playFoodGain(start: start, end: playerCenter);
        Future.delayed(const Duration(milliseconds: 144), () {
          if (mounted) {
            _overlayCoordinator.playFoodGain(start: start, end: playerCenter);
          }
        });
        return;
      case CardType.babyRaccoon:
        if (_gameState.chaosMode) {
          _overlayCoordinator.playRaccoonDevour(
            playerCenter: playerCenter,
            cardCenter: start,
            foodCount: 2,
          );
        } else if (result.targetPlayerId != null) {
          final targetCenter = _playerFoodCenter(result.targetPlayerId!);
          _overlayCoordinator.playRaccoonDevour(
            playerCenter: targetCenter,
            cardCenter: start,
            foodCount: 2,
          );
        }
        return;
      case CardType.vacuum:
        for (final player in _gameState.players) {
          if (player.id == currentPlayerId || player.foodCount <= 0) continue;
          final targetCenter = _playerFoodCenter(player.id);
          _overlayCoordinator.playFoodSteal(
            fromTarget: targetCenter,
            toThief: playerCenter,
          );
        }
        return;
    }
  }

  // ── UI builders ────────────────────────────────────────────────────────────

  void _computeCardSize(BoxConstraints constraints) {
    final maxH = constraints.maxHeight * 0.52;
    final maxW = constraints.maxWidth * 0.55;

    _cardHeight = maxH.clamp(180.0, 260.0);
    _cardWidth = (_cardHeight * 0.70).clamp(130.0, 185.0).clamp(0.0, maxW);
  }

  List<Widget> _buildPlayerPositions(BoxConstraints constraints) {
    final sw = constraints.maxWidth;
    final sh = constraints.maxHeight;

    const double hMargin = 4.0;
    final double topOffset = sh * 0.01 + 48.0;
    final double bottomOffset = sh * 0.01 + 4.0;
    final double cardMaxW = (sw * 0.34).clamp(82.0, 132.0);

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
        <String, double>{'bottom': bottomOffset, 'right': hMargin},
        <String, double>{'bottom': bottomOffset, 'left': hMargin},
      ],
    };

    final layout = positions[_gameState.players.length]!;

    return List.generate(_gameState.players.length, (index) {
      final player = _gameState.players[index];
      _playerKeys.putIfAbsent(player.id, GlobalKey.new);
      _foodZoneKeys.putIfAbsent(player.id, GlobalKey.new);
      _fridgeZoneKeys.putIfAbsent(player.id, GlobalKey.new);

      final animatingPlayerId = _displayPlayerName != null ? _lastResolvedPlayerId : null;
      final active = animatingPlayerId != null
          ? player.id == animatingPlayerId
          : index == _gameState.currentPlayerIndex;

      final int displayFoodCount = _useStockSnapshot
          ? (_snapshotFoodCounts[player.id] ?? player.foodCount)
          : player.foodCount;
      final int displayTrashCount = _useStockSnapshot
          ? (_snapshotTrashCounts[player.id] ?? player.trashCount)
          : player.trashCount;

      final pos = layout[index];
      return Positioned(
        top: pos['top'],
        left: pos['left'],
        right: pos['right'],
        bottom: pos['bottom'],
        child: GamePlayerCard(
          player: player,
          active: active,
          displayFoodCount: displayFoodCount,
          displayTrashCount: displayTrashCount,
          playerKey: _playerKeys[player.id]!,
          foodZoneKey: _foodZoneKeys[player.id]!,
          fridgeZoneKey: _fridgeZoneKeys[player.id]!,
          maxWidth: cardMaxW,
        ),
      );
    });
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
        backgroundColor: AppColors.background,
        body: SafeArea(
          minimum: const EdgeInsets.only(top: 4, left: 4, right: 4, bottom: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              _computeCardSize(constraints);
              return Stack(
                key: _rootStackKey,
                children: [
                  // Stickers décoratifs fond
                  const Positioned.fill(
                    child: GameBackgroundStickers(),
                  ),

                  // Fond gameplay
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Stack(
                          children: [
                            ..._buildPlayerPositions(constraints),
                            Center(
                              child: GameCenterArea(
                                deckKey: _deckKey,
                                constraints: constraints,
                                displayPlayerName: _displayPlayerName,
                                currentPlayerName: _gameState.currentPlayer.name,
                                effectText: _effectText,
                                isAnimating: _isAnimating,
                                remainingCards: _gameState.remainingCards,
                                revealedCard: _revealedCard,
                                deckStickerPlayer: _deckStickerPlayer,
                                currentPlayer: _gameState.currentPlayer,
                                cardWidth: _cardWidth,
                                cardHeight: _cardHeight,
                                cardRadius: _cardRadius,
                                flipController: _flipController,
                                slideController: _slideController,
                                appearController: _appearController,
                                appearOffset: _appearOffset,
                                appearOpacity: _appearOpacity,
                                onDrawCard: _drawCard,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Top bar
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: GameControlsBar(
                      remainingCards: _gameState.remainingCards,
                      quitEnabled: !_isAnimating && !_showingPinceOverlay,
                      onQuitPressed: () async {
                        AudioService.instance.playButtonSound();
                        final confirmed = await _showQuitDialog();
                        if (confirmed && mounted) await _quitToHome();
                      },
                    ),
                  ),

                  // Animations overlay
                  Positioned.fill(
                    child: GameplayOverlayAnimationManager(
                      animationsNotifier: _animationsNotifier,
                    ),
                  ),

                  // Bandit target overlay
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
