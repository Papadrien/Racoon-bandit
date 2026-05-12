import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game/game_state.dart';
import '../../core/models/card_type.dart';
import '../../core/navigation/app_router.dart';
import '../../core/theme/app_theme.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameState _gameState;
  bool _initialized = false;
  bool _isAnimating = false;
  String _effectText = '';
  Offset _trashOffset = Offset.zero;

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

    setState(() {
      _isAnimating = true;
      _effectText = '';
    });

    HapticFeedback.lightImpact();

    await Future<void>.delayed(const Duration(milliseconds: 400));

    final result = _gameState.drawCard();

    setState(() {
      _effectText = result.message;
      _trashOffset = result.trashDestroyed
          ? const Offset(120, 120)
          : result.foodStolen
              ? const Offset(-120, -60)
              : Offset.zero;
    });

    await Future<void>.delayed(const Duration(milliseconds: 1400));

    setState(() {
      _trashOffset = Offset.zero;
      _isAnimating = false;
    });

    if (_gameState.isGameOver && mounted) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.result,
        arguments: _gameState,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const SizedBox.shrink();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────
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

              // ── Liste des joueurs ──────────────────────────────
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
                                  opacity: player.hasTrash ? 1 : 0.2,
                                  child: const Icon(
                                    Icons.delete,
                                    size: 34,
                                    color: Colors.greenAccent,
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

              // ── Texte effet ────────────────────────────────────
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _effectText.isEmpty ? 0 : 1,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _effectText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // ── Zone carte révélée (centre) ────────────────────
              SizedBox(
                height: 186,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 360),
                    transitionBuilder: (child, animation) {
                      final slide = Tween<Offset>(
                        begin: const Offset(0, 0.4),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ));
                      return SlideTransition(
                        position: slide,
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: _gameState.revealedCard != null
                        ? _buildRevealedCard()
                        : _buildEmptyCenter(),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ── Pile de cartes ─────────────────────────────────
              _buildPile(),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Carte révélée ─────────────────────────────────────────────

  Widget _buildRevealedCard() {
    return Container(
      key: ValueKey(_gameState.revealedCard?.id ?? -1),
      width: 148,
      height: 186,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, AppTheme.accent],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _cardLabel(),
              style: const TextStyle(fontSize: 44),
            ),
            const SizedBox(height: 8),
            Text(
              _gameState.revealedCard?.name ?? '',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                _gameState.revealedCard?.description ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCenter() {
    return Container(
      key: const ValueKey(-1),
      width: 148,
      height: 186,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white12, width: 1.5),
      ),
      child: const Center(
        child: Text(
          'Appuie sur\nla pile',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white24, fontSize: 13, height: 1.6),
        ),
      ),
    );
  }

  // ── Pile de cartes ────────────────────────────────────────────

  Widget _buildPile() {
    final empty = _gameState.remainingCards == 0;

    return GestureDetector(
      onTap: empty || _isAnimating ? null : _drawCard,
      child: SizedBox(
        width: 118,
        height: 158,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Couche 3 – fond
            if (!empty && _gameState.remainingCards > 2)
              Positioned(
                top: 8,
                left: 8,
                right: -8,
                bottom: -8,
                child: _pileLayer(0.22),
              ),
            // Couche 2 – milieu
            if (!empty && _gameState.remainingCards > 1)
              Positioned(
                top: 4,
                left: 4,
                right: -4,
                bottom: -4,
                child: _pileLayer(0.50),
              ),
            // Couche 1 – carte du dessus (interactive)
            Positioned.fill(
              child: AnimatedSlide(
                offset: _isAnimating ? const Offset(0, -0.10) : Offset.zero,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: AnimatedScale(
                  scale: _isAnimating ? 1.05 : 1.0,
                  duration: const Duration(milliseconds: 220),
                  child: _buildTopCard(empty),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCard(bool empty) {
    return Container(
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
            ? const Icon(Icons.layers_clear, color: Colors.white24, size: 30)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.style, size: 30, color: Colors.white),
                  const SizedBox(height: 6),
                  Text(
                    '${_gameState.remainingCards}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'cartes',
                    style: TextStyle(fontSize: 10, color: Colors.white70),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _pileLayer(double opacity) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary.withOpacity(opacity),
            AppTheme.accent.withOpacity(opacity),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }

  // ── Label emoji ───────────────────────────────────────────────

  String _cardLabel() {
    switch (_gameState.revealedCard?.type) {
      case CardType.food:
        return '🍎';
      case CardType.trash:
        return '🗑️';
      case CardType.raccoon:
        return '🦝';
      case CardType.bandit:
        return '🥷';
      default:
        return '?';
    }
  }
}
