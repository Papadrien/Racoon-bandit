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
  color: card.color,
  borderRadius: BorderRadius.circular(18),
  boxShadow: const [
    BoxShadow(
      color: Colors.black54,
      blurRadius: 12,
      offset: Offset(0, 5),
    ),
  ],
      boxShadow: const [
        BoxShadow(
          color: Colors.black54,
          blurRadius: 12,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: const Center(
      child: Text(
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
