import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game/game_state.dart';
import '../../core/models/game_card.dart';
import '../../core/navigation/app_router.dart';
import '../../core/theme/app_theme.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin {
  // ── Game state ──────────────────────────────────────────────────
  late GameState _gameState;
  bool _initialized = false;
  bool _isAnimating = false;
  String _effectText = '';
  Offset _trashOffset = Offset.zero;

  // ── Card animation ──────────────────────────────────────────────
  // _flipCtrl  : 0 → 1, drives the 3-D flip (back face → front face)
  // _slideCtrl : 0 → 1, drives the slide-out after reveal
  late final AnimationController _flipCtrl;
  late final AnimationController _slideCtrl;

  // Card currently being revealed (null = pile shows back face / empty)
  GameCard? _localRevealedCard;

  // ── Lifecycle ───────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    _slideCtrl.dispose();
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

  // ── Draw logic ──────────────────────────────────────────────────

  Future<void> _drawCard() async {
    if (_isAnimating || _gameState.isGameOver) return;

    setState(() {
      _isAnimating = true;
      _effectText = '';
    });

    HapticFeedback.lightImpact();

    // Apply effect immediately so game state is ready before the animation
    final result = _gameState.drawCard();

    setState(() {
      _localRevealedCard = _gameState.revealedCard;
      _trashOffset = result.trashDestroyed
          ? const Offset(120, 120)
          : result.foodStolen
              ? const Offset(-120, -60)
              : Offset.zero;
    });

    // 1) Flip animation (back → front)
    _flipCtrl.reset();
    await _flipCtrl.forward();

    // 2) Show effect text once the card face is fully visible
    setState(() => _effectText = result.message);

    // 3) Hold the revealed card for ~900 ms
    await Future<void>.delayed(const Duration(milliseconds: 900));

    // 4) Slide the card off downward
    _slideCtrl.reset();
    await _slideCtrl.forward();

    // 5) Reset everything for the next draw
    if (!mounted) return;
    setState(() {
      _localRevealedCard = null;
      _effectText = '';
      _trashOffset = Offset.zero;
      _isAnimating = false;
    });
    _flipCtrl.reset();
    _slideCtrl.reset();

    if (_gameState.isGameOver && mounted) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.result,
        arguments: _gameState,
      );
    }
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const SizedBox.shrink();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────
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
                    style: const TextStyle(color: AppTheme.textMuted),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                'Tour de ${_gameState.currentPlayer.name}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              // ── Player list ──────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  itemCount: _gameState.players.length,
                  itemBuilder: (context, index) {
                    final player = _gameState.players[index];
                    final active = index == _gameState.currentPlayerIndex;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: active
                            ? AppTheme.primary.withOpacity(0.22)
                            : Colors.white10,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: active ? AppTheme.primary : Colors.white12,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Name + food dots
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  player.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: List.generate(
                                    player.foodCount,
                                    (i) => AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 400),
                                      margin: const EdgeInsets.only(right: 4),
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: AppTheme.accent,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Food count + trash icon
                          Column(
                            children: [
                              Text('🍎 ${player.foodCount}'),
                              const SizedBox(height: 12),
                              AnimatedSlide(
                                duration: const Duration(milliseconds: 500),
                                offset: player.hasTrash
                                    ? Offset.zero
                                    : _trashOffset,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 400),
                                  opacity: player.hasTrash ? 1.0 : 0.2,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.delete,
                                        size: 34,
                                        color: Colors.greenAccent,
                                      ),
                                      if (player.trashCount > 1)
                                        Text(
                                          '×${player.trashCount}',
                                          style: const TextStyle(
                                            color: Colors.greenAccent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ── Effect text (above the pile) ─────────────────────
              AnimatedOpacity(
                duration: const Duration(milliseconds: 280),
                opacity: _effectText.isEmpty ? 0.0 : 1.0,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    _effectText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),

              // ── Single draw pile ─────────────────────────────────
              _buildPile(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Pile widget ──────────────────────────────────────────────────

  Widget _buildPile() {
    // "visually empty" only once all animation has completed
    final isDeckEmpty =
        _gameState.remainingCards == 0 && _localRevealedCard == null;

    return GestureDetector(
      onTap: (isDeckEmpty || _isAnimating) ? null : _drawCard,
      child: AnimatedBuilder(
        animation: Listenable.merge([_flipCtrl, _slideCtrl]),
        builder: (context, _) {
          final fv = _flipCtrl.value; // 0 → 1
          final sv = _slideCtrl.value; // 0 → 1 (slide-out)

          // ── Flip geometry ───────────────────────────────────────
          // [0, 0.5) : back face rotating away  (  0   → π/2 )
          // [0.5, 1] : front face rotating in   ( -π/2 → 0   )
          final showFront = fv >= 0.5 && _localRevealedCard != null;
          final angle = fv < 0.5 ? fv * math.pi : (fv - 1.0) * math.pi;

          // ── Slide-out ────────────────────────────────────────────
          final slideOffsetY = sv * 280.0;
          final cardOpacity = (1.0 - sv).clamp(0.0, 1.0);

          final Widget face = showFront
              ? _buildFrontFace(_localRevealedCard!)
              : _buildBackFace(empty: isDeckEmpty);

          return Opacity(
            opacity: isDeckEmpty ? 0.35 : cardOpacity,
            child: Transform.translate(
              offset: Offset(0, slideOffsetY),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // perspective
                  ..rotateY(angle),
                child: face,
              ),
            ),
          );
        },
      ),
    );
  }

  // Back face of the pile card (face-down / empty state)
  Widget _buildBackFace({required bool empty}) {
    return Container(
      width: 110,
      height: 150,
      decoration: BoxDecoration(
        gradient: empty
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primary, AppTheme.accent],
              ),
        color: empty ? Colors.transparent : null,
        borderRadius: BorderRadius.circular(18),
        border: empty
            ? Border.all(color: Colors.white24, width: 1.5)
            : null,
        boxShadow: empty
            ? null
            : const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 12,
                  offset: Offset(0, 5),
                ),
              ],
      ),
      child: Center(
        child: empty
            ? const Icon(Icons.layers_clear, color: Colors.white24, size: 32)
            : const Text(
                '?',
                style: TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  // Front face of the pile card (revealed)
  Widget _buildFrontFace(GameCard card) {
    return Container(
      width: 110,
      height: 150,
      decoration: BoxDecoration(
        color: card.color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(card.emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                card.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
