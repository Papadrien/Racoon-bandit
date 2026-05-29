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
import '../../core/ui/app_colors.dart';
import '../../core/ui/app_decorations.dart';
import '../../core/ui/app_shadows.dart';
import '../../core/ui/app_spacing.dart';
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
  // Nom du joueur affiché pendant l'animation (pour ne pas sauter visuellement)
  String? _displayPlayerName;

  bool _showingPinceOverlay = false;
  List<PlayerState> _pinceTargets = [];
  bool _quitDialogOpen = false;

  late final AnimationController _flipController;
  late final AnimationController _slideController;
  // Animation d'apparition subtile (remontée + fade) quand une carte arrive
  late final AnimationController _appearController;
  late final Animation<double> _appearOffset;
  late final Animation<double> _appearOpacity;
  // Animation pulse sticker joueur actuel
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  static const Map<CardType, AssetImage> _cardFaceProviders = {
    CardType.raccoon: AssetImage('assets/images/card_front_raccoon.png'),
    CardType.trash: AssetImage('assets/images/card_front_trash.png'),
    CardType.food: AssetImage('assets/images/card_front_food.png'),
    CardType.pince: AssetImage('assets/images/card_front_pince.png'),
    CardType.vacuum: AssetImage('assets/images/card_front_vacuum.png'),
  };

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
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 1.0, end: 1.07).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(WakelockService.disable());
    _flipController.dispose();
    _slideController.dispose();
    _appearController.dispose();
    _pulseController.dispose();
    // Vide la liste avant dispose pour éviter listeners dangling
    _animationsNotifier.value = [];
    _animationsNotifier.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Précache les faces des cartes pour éviter le délai lors du retournement.
    precacheImage(const AssetImage('assets/images/card_front_raccoon.png'), context);
    precacheImage(const AssetImage('assets/images/card_front_trash.png'), context);
    precacheImage(const AssetImage('assets/images/card_front_food.png'), context);
    precacheImage(const AssetImage('assets/images/card_front_pince.png'), context);
    precacheImage(const AssetImage('assets/images/card_front_vacuum.png'), context);
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

    _displayPlayerName = null;
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
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.stickerWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
            boxShadow: AppShadows.floating,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icône
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.exit_to_app_rounded,
                  color: AppColors.orange,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Titre
              Text(
                l10n.gameQuitDialogTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Contenu
              Text(
                l10n.gameQuitDialogContent,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              // Boutons
              Row(
                children: [
                  // Annuler
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        AudioService.instance.playButtonSound();
                        Navigator.of(ctx).pop(false);
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                          border: Border.all(
                            color: AppColors.shadowSoft,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            l10n.gameQuitCancel,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Quitter
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        AudioService.instance.playButtonSound();
                        Navigator.of(ctx).pop(true);
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.orange,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                          boxShadow: AppShadows.subtleGlow(AppColors.orange),
                        ),
                        child: Center(
                          child: Text(
                            l10n.gameQuitConfirm,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
    // Capturer le nom avant l'avancée du tour pour l'afficher pendant l'animation
    final String currentPlayerNameSnapshot = _gameState.currentPlayer.name;
    final foodCountBeforeDraw = _gameState.currentPlayer.foodCount;

    final result = _gameState.drawCard();
    final card = _gameState.revealedCard;

    setState(() {
      _revealedCard = card;
      _displayPlayerName = currentPlayerNameSnapshot;
    });

    // Précharger agressivement les faces avant avant le flip
    // afin d'éviter tout délai visible pendant la rotation.
    if (card != null && _cardFaceProviders.containsKey(card.type)) {
      await precacheImage(_cardFaceProviders[card.type]!, context);
    }

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
      _displayPlayerName = null;
    });

    _flipController.reset();
    _slideController.reset();

    // Animation d'apparition : la nouvelle carte remonte légèrement du paquet
    // quand elle devient disponible pour la prochaine pioche.
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
      // Son joué ici uniquement s'il n'y a pas de popup de déblocage.
      // Si des dos sont débloqués, c'est la popup qui joue le son.
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
        if (_gameState.chaosMode) {
          // Mode pagaille : le joueur actif perd 2 nourritures
          _overlayCoordinator.playRaccoonDevour(playerCenter: playerCenter, cardCenter: start, foodCount: 2);
        } else if (result.targetPlayerId != null) {
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

  /// Construit la carte joueur nouvelle architecture :
  /// avatar rond flottant au-dessus + carte sticker blanche + ressources dessous.
  ///
  /// La hauteur TOTALE est toujours la même (stable), grâce à des zones
  /// à hauteur fixe pour la carte et pour les ressources.
  Widget _buildPlayerCard(int index, {double maxWidth = 150}) {
    final player = _gameState.players[index];
    final animatingPlayerId = _displayPlayerName != null ? _lastResolvedPlayerId : null;
    final active = animatingPlayerId != null
        ? player.id == animatingPlayerId
        : index == _gameState.currentPlayerIndex;

    _playerKeys.putIfAbsent(player.id, GlobalKey.new);
    _foodZoneKeys.putIfAbsent(player.id, GlobalKey.new);
    _fridgeZoneKeys.putIfAbsent(player.id, GlobalKey.new);

    final isCompact = maxWidth < 115;
    final avatarSize = isCompact ? 36.0 : 45.6;
    final avatarRingSize = avatarSize + 6.0;
    final nameFontSize = isCompact ? 10.0 : 12.0;
    final resourceIconSize = isCompact ? 18.0 : 20.0;

    // ── Zones à hauteur fixe pour stabiliser le layout ──────────────
    // Zone ressources : 2 runs max × (iconSize + runSpacing) + spacing inter-section
    final resourceZoneHeight = (resourceIconSize * 2 + 4) * 2 + 6.0;

    // Chevauchement avatar/carte
    const double avatarOverlap = 8.0;

    // Hauteur de la carte sticker (fixe, indépendante du contenu)
    final cardInnerHeight = isCompact ? 32.0 : 38.0;

    return SizedBox(
      width: maxWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Avatar flottant ──────────────────────────────────────────
          Container(
            width: avatarRingSize,
            height: avatarRingSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.stickerWhite,
              border: active
                  ? Border.all(color: player.profileColor, width: 2.5)
                  : null,
              boxShadow: active
                  ? AppShadows.subtleGlow(player.profileColor)
                  : AppShadows.floating,
            ),
            child: Center(
              child: PlayerAvatar(
                emoji: player.emoji,
                color: player.profileColor,
                size: avatarSize,
              ),
            ),
          ),

          // ── Carte sticker (hauteur fixe, avatar chevauche le haut) ──
          Transform.translate(
            offset: const Offset(0, -avatarOverlap),
            child: Container(
              key: _playerKeys[player.id],
              width: maxWidth,
              height: cardInnerHeight + avatarOverlap + (isCompact ? 4 : 6),
              padding: EdgeInsets.fromLTRB(
                isCompact ? 4 : 6,
                avatarOverlap + 2,
                isCompact ? 4 : 6,
                isCompact ? 3 : 5,
              ),
              decoration: BoxDecoration(
                color: AppColors.stickerWhite,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: active
                    ? Border.all(color: player.profileColor, width: 2)
                    : null,
                boxShadow: AppShadows.sticker,
              ),
              child: Center(
                child: Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: nameFontSize,
                  ),
                ),
              ),
            ),
          ),

          // ── Zone ressources FIXE sous la carte ──────────────────────
          // La hauteur est fixe pour éviter tout redimensionnement de layout.
          Transform.translate(
            offset: const Offset(0, -avatarOverlap + 2),
            child: SizedBox(
              width: maxWidth,
              height: resourceZoneHeight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Nourriture
                  SizedBox(
                    key: _foodZoneKeys[player.id],
                    width: maxWidth,
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 3,
                      runSpacing: 3,
                      children: player.foodCount > 0
                          ? List.generate(
                              player.foodCount.clamp(0, 8),
                              (_) => Container(
                                width: resourceIconSize,
                                height: resourceIconSize,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(2),
                                child: Image.asset(
                                  'assets/images/icon_food.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            )
                          : const [],
                    ),
                  ),
                  if (player.trashCount > 0) ...[
                    const SizedBox(height: 2),
                    SizedBox(
                      key: _fridgeZoneKeys[player.id],
                      width: maxWidth,
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 3,
                        runSpacing: 3,
                        children: List.generate(
                          player.trashCount.clamp(0, 6),
                          (_) => Container(
                            width: resourceIconSize,
                            height: resourceIconSize,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(2),
                            child: Image.asset(
                              'assets/images/icon_trash.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else
                    SizedBox(key: _fridgeZoneKeys[player.id]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPlayerPositions(BoxConstraints constraints) {
    final sw = constraints.maxWidth;
    final sh = constraints.maxHeight;

    // Marge horizontale légèrement plus grande pour ne pas coller au bord.
    const double hMargin = 4.0;

    // Offset vertical : on part juste en dessous de la top bar (controls).
    // 48px = hauteur approximative de _buildGameplayControlsBar.
    final double topOffset = sh * 0.01 + 48.0;

    // Offset bas : espace confortable au-dessus du bord inférieur SafeArea.
    final double bottomOffset = sh * 0.01 + 4.0;

    // Largeur max de carte — réduite pour laisser de la place au centre.
    // Sur petits écrans (<340), on compresse davantage.
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
          final nearEdge = !backgroundCard &&
              angle > math.pi / 2 - 0.08 &&
              angle < math.pi / 2 + 0.08;

          // Animation d'apparition
          final isFlipping = flip > 0.0;
          final appearDy = (backgroundCard || isFlipping) ? 0.0 : _appearOffset.value * 10.0;
          final appearAlpha = (backgroundCard || isFlipping) ? 1.0 : _appearOpacity.value;

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
              child: Container(
                width: _cardWidth,
                height: _cardHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_cardRadius),
                  border: Border.all(
                    color: Colors.white,
                    width: 7.0,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_cardRadius - 7.0),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned.fill(
                        child: isBack || backgroundCard
                            ? _buildCardBackWidget()
                            : (showFront && _revealedCard?.type == CardType.raccoon)
                                ? Image(image: _cardFaceProviders[CardType.raccoon]!, fit: BoxFit.cover, gaplessPlayback: true, filterQuality: FilterQuality.high)
                                : (showFront && _revealedCard?.type == CardType.trash)
                                    ? Image(image: _cardFaceProviders[CardType.trash]!, fit: BoxFit.cover, gaplessPlayback: true, filterQuality: FilterQuality.high)
                                    : (showFront && _revealedCard?.type == CardType.food)
                                        ? Image(image: _cardFaceProviders[CardType.food]!, fit: BoxFit.cover, gaplessPlayback: true, filterQuality: FilterQuality.high)
                                        : ((showFront && _revealedCard?.type == CardType.pince) || (showFront && _revealedCard?.type == CardType.vacuum))
                                            ? Image(image: _cardFaceProviders[_revealedCard!.type]!, fit: BoxFit.cover, gaplessPlayback: true, filterQuality: FilterQuality.high)
                                            : ColoredBox(
                                                color: _revealedCard?.color ?? Colors.deepPurple,
                                              ),
                      ),
                      if (!backgroundCard &&
                          !(showFront && (_revealedCard?.type == CardType.raccoon || _revealedCard?.type == CardType.trash || _revealedCard?.type == CardType.food || _revealedCard?.type == CardType.pince || _revealedCard?.type == CardType.vacuum)))
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
                      // Sticker joueur actuel — visible uniquement sur le dos de la carte à piocher
                      if (!backgroundCard && !showFront && !deckExhausted)
                        Positioned.fill(
                          child: Center(
                            child: ScaleTransition(
                              scale: _pulseScale,
                              child: _buildCurrentPlayerSticker(_gameState.currentPlayer),
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

  Widget _buildCurrentPlayerSticker(PlayerState player) {
    final color = player.profileColor;
    const double size = 48.4;
    return Container(
      width: size + 6,
      height: size + 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.stickerWhite,
        border: Border.all(color: color, width: 2.5),
        boxShadow: AppShadows.subtleGlow(color),
      ),
      child: Center(
        child: PlayerAvatar(
          emoji: player.emoji,
          color: color,
          size: size,
        ),
      ),
    );
  }

  Widget _buildCenterArea(BoxConstraints constraints) {
    _computeCardSize(constraints);

    final showBackgroundCard =
        _isAnimating ? _gameState.remainingCards > 0 : _gameState.remainingCards > 1;
    final titleFontSize = (constraints.maxWidth * 0.062).clamp(14.0, 22.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tour du joueur — sticker blanc flottant
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: AppDecorations.floatingStickerR(AppSpacing.radiusLarge),
          child: Text(
            AppLocalizations.of(context)!.gameTurnOf(
              _displayPlayerName ?? _gameState.currentPlayer.name,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textDark,
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
        const SizedBox(height: 18),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 36, maxHeight: 48),
          child: Text(
            _effectText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w700,
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
          // Bouton Quitter — sticker blanc flottant
          GestureDetector(
            onTap: quitEnabled
                ? () async {
                    AudioService.instance.playButtonSound();
                    final confirmed = await _showQuitDialog();
                    if (confirmed && mounted) await _quitToHome();
                  }
                : null,
            child: Opacity(
              opacity: quitEnabled ? 1.0 : 0.4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.stickerWhite,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  boxShadow: AppShadows.floating,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.exit_to_app, size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 5),
                    Text(
                      AppLocalizations.of(context)!.gameQuitConfirm,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          // Compteur cartes restantes — aligné à droite
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _gameState.remainingCards == 0
                ? const SizedBox.shrink()
                : Container(
                    key: ValueKey(_gameState.remainingCards),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.stickerWhite,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                      boxShadow: AppShadows.floating,
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.gameRemainingCards(_gameState.remainingCards),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
          ),
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
        backgroundColor: AppColors.background,
        body: SafeArea(
          minimum: const EdgeInsets.only(top: 4, left: 4, right: 4, bottom: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                key: _rootStackKey,
                children: [
                  // ── Stickers décoratifs fond ──────────────────────────
                  const Positioned.fill(
                    child: _GameBackgroundStickers(),
                  ),

                  // ── Fond gameplay ─────────────────────────────────────
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

                  // ── Top bar (toujours visible) ────────────────────────
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _buildGameplayControlsBar(),
                  ),

                  // ── Animations overlay ────────────────────────────────
                  Positioned.fill(
                    child: GameplayOverlayAnimationManager(
                      animationsNotifier: _animationsNotifier,
                    ),
                  ),

                  // ── Bandit target overlay ─────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
// Stickers décoratifs Game Screen — bords et coins uniquement
// ─────────────────────────────────────────────────────────────────────────────

class _GameBackgroundStickers extends StatelessWidget {
  const _GameBackgroundStickers();

  static const _pine  = 'assets/images/sticker_pine_tree.png';
  static const _cone  = 'assets/images/sticker_pine_cone.png';
  static const _cabin = 'assets/images/sticker_cabin.png';

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        // Sapin haut-gauche — ancré dans le coin, petit pour ne pas gêner les joueurs
        _GameSticker(
          asset: _pine,
          size: w * 0.18,
          left: -w * 0.04,
          top: h * 0.06,
          angle: -0.10,
          opacity: 0.55,
        ),

        // Cabane haut-droite — discrète, coin seulement
        _GameSticker(
          asset: _cabin,
          size: w * 0.14,
          right: -w * 0.02,
          top: h * 0.08,
          angle: 0.07,
          opacity: 0.45,
        ),

        // Pomme de pin gauche milieu-bas — petite, ne touche pas le centre
        _GameSticker(
          asset: _cone,
          size: w * 0.08,
          left: w * 0.02,
          top: h * 0.52,
          angle: -0.15,
          opacity: 0.40,
        ),

        // Sapin droite milieu — rogné, bord droit uniquement
        _GameSticker(
          asset: _pine,
          size: w * 0.17,
          right: -w * 0.05,
          top: h * 0.42,
          angle: 0.06,
          opacity: 0.40,
        ),

        // Sapin bas-gauche
        _GameSticker(
          asset: _pine,
          size: w * 0.16,
          left: -w * 0.03,
          top: h * 0.76,
          angle: -0.05,
          opacity: 0.50,
        ),

        // Pomme de pin bas-droite
        _GameSticker(
          asset: _cone,
          size: w * 0.09,
          right: w * 0.03,
          top: h * 0.80,
          angle: 0.20,
          opacity: 0.40,
        ),
      ],
    );
  }
}

class _GameSticker extends StatelessWidget {
  final String asset;
  final double size;
  final double? left;
  final double? right;
  final double? top;
  final double angle;
  final double opacity;

  const _GameSticker({
    required this.asset,
    required this.size,
    this.left,
    this.right,
    this.top,
    this.angle = 0.0,
    this.opacity = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      child: Transform.rotate(
        angle: angle,
        child: Image.asset(
          asset,
          width: size,
          height: size,
          fit: BoxFit.contain,
          opacity: AlwaysStoppedAnimation(opacity),
        ),
      ),
    );
  }
}
