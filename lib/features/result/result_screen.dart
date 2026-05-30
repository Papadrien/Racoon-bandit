import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:raccoon_bandit/l10n/app_localizations.dart';

import '../../core/game/game_state.dart';
import '../../core/models/player_state.dart';
import '../../core/models/result_screen_args.dart';
import '../../core/navigation/app_router.dart';
import '../../core/navigation/navigation_guard.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/life_system_service.dart';
import '../../core/services/rewarded_ad_service.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/app_shadows.dart';
import '../../core/ui/app_spacing.dart';
import '../../widgets/player_avatar.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/reward_unlock_dialog.dart';
import '../../widgets/unlock_progress_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ResultScreen
// ─────────────────────────────────────────────────────────────────────────────

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pageCtrl;
  late final AnimationController _winnerCtrl;
  late final AnimationController _starsCtrl;

  bool _navigationInProgress = false;
  bool _isRewardLoading = false;
  final LifeSystemService _lifeSystemService = LifeSystemService();

  static const String _tag = 'ResultScreen';

  @override
  void initState() {
    super.initState();

    _pageCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _winnerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _winnerCtrl.forward();
    });

    _starsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) => _showRewardPopups());
    _lifeSystemService.load().then((_) {
      if (_lifeSystemService.currentLives <= 0) {
        RewardedAdService.instance.preloadAd();
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _winnerCtrl.dispose();
    _starsCtrl.dispose();
    super.dispose();
  }

  Future<void> _showRewardPopups() async {
    if (!mounted) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! ResultScreenArgs) return;
    if (args.newUnlocks.isEmpty) return;

    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    await RewardUnlockDialog.showAll(context, args.newUnlocks);
  }

  GameState _getGameState(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is ResultScreenArgs) return args.gameState;
    return args as GameState;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gameState = _getGameState(context);
    final ranking = gameState.ranking;
    final winner = ranking.first;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        NavigationGuard.log(_tag, 'back pressed — retour home');
        _goHome();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: FadeTransition(
          opacity: CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut),
          child: Stack(
            children: [
              // ── Fond décoratif ────────────────────────────────────────────
              const _ResultBackground(),

              // ── Stickers décoratifs ───────────────────────────────────────
              _DecorativeStickers(starsCtrl: _starsCtrl),

              // ── Contenu principal ─────────────────────────────────────────
              SafeArea(
                minimum: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 4,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 360;
                    final hPad = isNarrow
                        ? AppSpacing.hPadNarrow
                        : AppSpacing.hPadNormal;

                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: hPad,
                        vertical: AppSpacing.sm,
                      ),
                      child: Column(
                        children: [
                          // ── Hero gagnant ──────────────────────────────────
                          _WinnerHero(
                            winner: winner,
                            l10n: l10n,
                            controller: _winnerCtrl,
                            constraints: constraints,
                          ),

                          SizedBox(height: isNarrow ? AppSpacing.sm : AppSpacing.md),

                          // ── Contenu scrollable ────────────────────────────
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                children: [
                                  // Classement
                                  _RankingCard(
                                    ranking: ranking,
                                    constraints: constraints,
                                  ),
                                  const SizedBox(height: AppSpacing.md),

                                  // Progression déblocage
                                  const UnlockProgressWidget(),
                                  const SizedBox(height: AppSpacing.md),

                                  // Résumé stats
                                  _StatsCard(
                                    gameState: gameState,
                                    l10n: l10n,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                ],
                              ),
                            ),
                          ),

                          // ── Actions ───────────────────────────────────────
                          const SizedBox(height: AppSpacing.sm),
                          if (_lifeSystemService.currentLives <= 0) ...[
                            OrangeButton(
                              label: _isRewardLoading
                                  ? AppLocalizations.of(context)!.adLoading
                                  : AppLocalizations.of(context)!.watchAdButton,
                              icon: _isRewardLoading ? null : Icons.ondemand_video_rounded,
                              onPressed: _isRewardLoading ? null : _watchAdForLife,
                              isLoading: _isRewardLoading,
                              height: AppSpacing.buttonHeightSecondary,
                              fontSize: 15,
                              letterSpacing: 1.5,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                          PrimaryButton(
                            label: l10n.resultPlayAgain,
                            onPressed: _goLobby,
                          ),
                          TextButton(
                            onPressed: () {
                              AudioService.instance.playButtonSound();
                              _goHome();
                            },
                            child: Text(l10n.resultBackHome),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goLobby() {
    if (_navigationInProgress || !mounted) return;
    _navigationInProgress = true;
    NavigationGuard.log(_tag, 'navigation → lobby');
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.lobby,
      (r) => r.settings.name == AppRoutes.home,
    );
  }

  Future<void> _watchAdForLife() async {
    if (_isRewardLoading || !mounted) return;
    setState(() => _isRewardLoading = true);

    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    await RewardedAdService.instance.showRewardedLifeAd(
      onRewardEarned: () async {
        await _lifeSystemService.restoreLife();
        if (!mounted) return;
        setState(() {});
        messenger.showSnackBar(SnackBar(content: Text(l10n.lifeEarned)));
      },
      onError: (message) {
        if (!mounted) return;
        messenger.showSnackBar(SnackBar(content: Text(message)));
      },
    );

    if (mounted) setState(() => _isRewardLoading = false);
  }

  void _goHome() {
    if (_navigationInProgress || !mounted) return;
    _navigationInProgress = true;
    NavigationGuard.log(_tag, 'navigation → home');
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (r) => false,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fond décoratif
// ─────────────────────────────────────────────────────────────────────────────

class _ResultBackground extends StatelessWidget {
  const _ResultBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(painter: _BackgroundPainter()),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Fond beige de base (géré par Scaffold.backgroundColor)
    // Blob haut — teinte orangée chaude
    final paintTop = Paint()
      ..color = const Color(0xFFE8A87C).withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;

    final pathTop = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(size.width * 0.6, size.height * 0.12,
          size.width, size.height * 0.05)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(pathTop, paintTop);

    // Blob bas gauche — teinte violette douce
    final paintBot = Paint()
      ..color = const Color(0xFF7C4DFF).withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;

    final pathBot = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.80,
          size.width * 0.55, size.height)
      ..close();
    canvas.drawPath(pathBot, paintBot);

    // Cercle décoratif haut-droit
    final paintCircle = Paint()
      ..color = AppColors.orange.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width + 30, -30),
      size.width * 0.45,
      paintCircle,
    );
  }

  @override
  bool shouldRepaint(_BackgroundPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Stickers décoratifs (étoiles, confettis)
// ─────────────────────────────────────────────────────────────────────────────

class _DecorativeStickers extends StatelessWidget {
  const _DecorativeStickers({required this.starsCtrl});

  final AnimationController starsCtrl;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: starsCtrl,
          builder: (context, _) {
            return CustomPaint(
              painter: _StickerPainter(starsCtrl.value),
            );
          },
        ),
      ),
    );
  }
}

class _StickerPainter extends CustomPainter {
  final double t;

  _StickerPainter(this.t);

  static const _stars = [
    // [x_ratio, y_ratio, size, speed, phase]
    [0.08, 0.12, 14.0, 1.0, 0.0],
    [0.88, 0.08, 10.0, 0.7, 0.3],
    [0.92, 0.22, 7.0, 1.2, 0.6],
    [0.05, 0.35, 9.0, 0.8, 0.9],
    [0.75, 0.38, 6.0, 1.5, 0.2],
    [0.15, 0.55, 8.0, 0.6, 0.7],
    [0.82, 0.62, 11.0, 1.1, 0.4],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in _stars) {
      final x = size.width * s[0];
      final y = size.height * s[1];
      final sz = s[2];
      final speed = s[3];
      final phase = s[4];

      final pulse = 0.6 + 0.4 * math.sin((t * speed + phase) * 2 * math.pi);
      final opacity = 0.25 * pulse;

      _drawStar(canvas, Offset(x, y), sz * pulse, opacity);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, double opacity) {
    final paint = Paint()
      ..color = AppColors.orange.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final path = Path();
    const points = 4;
    const outerR = 1.0;
    const innerR = 0.4;

    for (int i = 0; i < points * 2; i++) {
      final angle = (i * math.pi / points) - math.pi / 2;
      final r = (i % 2 == 0) ? outerR : innerR;
      final x = center.dx + size * r * math.cos(angle);
      final y = center.dy + size * r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_StickerPainter old) => old.t != t;
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero gagnant
// ─────────────────────────────────────────────────────────────────────────────

class _WinnerHero extends StatelessWidget {
  const _WinnerHero({
    required this.winner,
    required this.l10n,
    required this.controller,
    required this.constraints,
  });

  final PlayerState winner;
  final AppLocalizations l10n;
  final AnimationController controller;
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final avatarSize = (constraints.maxWidth * 0.24).clamp(60.0, 92.0);
    final trophySize = (constraints.maxWidth * 0.16).clamp(40.0, 64.0);
    final titleFontSize = (constraints.maxWidth * 0.058).clamp(15.0, 22.0);
    final isNarrow = constraints.maxWidth < 360;

    return ScaleTransition(
      scale: Tween(begin: 0.75, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.elasticOut),
      ),
      child: FadeTransition(
        opacity: CurvedAnimation(parent: controller, curve: Curves.easeOut),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: isNarrow ? AppSpacing.md : AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: AppColors.stickerWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
            boxShadow: AppShadows.accentGlow(AppColors.orange),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Trophée
              _AnimatedTrophy(
                size: trophySize,
                controller: controller,
              ),
              SizedBox(height: isNarrow ? AppSpacing.xs : AppSpacing.sm),

              // Avatar gagnant avec halo
              _WinnerAvatar(
                winner: winner,
                size: avatarSize,
              ),
              SizedBox(height: isNarrow ? AppSpacing.xs : AppSpacing.sm),

              // Nom gagnant
              Text(
                l10n.resultWinner(winner.name),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: AppSpacing.xs),

              // Score
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${winner.foodCount}',
                      style: TextStyle(
                        fontSize: (constraints.maxWidth * 0.040).clamp(12.0, 16.0),
                        fontWeight: FontWeight.w700,
                        color: AppColors.orange,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Image.asset(
                      'assets/images/icon_food.png',
                      width: 18,
                      height: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedTrophy extends StatelessWidget {
  const _AnimatedTrophy({required this.size, required this.controller});

  final double size;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // Légère rotation oscillante une fois arrivé
        final oscillate = controller.value >= 1.0 ? 0.0 : 0.0;
        return Transform.rotate(
          angle: oscillate,
          child: child,
        );
      },
      child: Container(
        width: size * 1.3,
        height: size * 1.3,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.orange.withValues(alpha: 0.18),
              AppColors.orange.withValues(alpha: 0.0),
            ],
          ),
        ),
        child: Center(
          child: Text(
            '🏆',
            style: TextStyle(fontSize: size),
          ),
        ),
      ),
    );
  }
}

class _WinnerAvatar extends StatelessWidget {
  const _WinnerAvatar({required this.winner, required this.size});

  final PlayerState winner;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: AppShadows.subtleGlow(AppColors.orange),
      ),
      // Fond blanc forcé sur l'avatar du gagnant : on recrée le cercle
      // manuellement pour remplacer la couleur de profil par blanc.
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: winner.profileColor,
            width: size * 0.04,
          ),
        ),
        child: Center(
          child: Text(
            winner.emoji,
            style: TextStyle(fontSize: size * 0.48),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Carte classement
// ─────────────────────────────────────────────────────────────────────────────

class _RankingCard extends StatelessWidget {
  const _RankingCard({required this.ranking, required this.constraints});

  final List<PlayerState> ranking;
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final avatarSize = (constraints.maxWidth * 0.10).clamp(30.0, 40.0);

    return _StickerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: '🏅',
            label: l10n.resultRanking,
          ),
          const SizedBox(height: AppSpacing.sm),
          ...ranking.asMap().entries.map((entry) {
            final idx = entry.key;
            final player = entry.value;
            return _RankingRow(
              rank: idx + 1,
              player: player,
              avatarSize: avatarSize,
              isWinner: idx == 0,
            );
          }),
        ],
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({
    required this.rank,
    required this.player,
    required this.avatarSize,
    required this.isWinner,
  });

  final int rank;
  final PlayerState player;
  final double avatarSize;
  final bool isWinner;

  String get _rankEmoji {
    return switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => ' $rank.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: isWinner
          ? BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              border: Border.all(
                color: AppColors.orange.withValues(alpha: 0.25),
                width: 1,
              ),
            )
          : null,
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              _rankEmoji,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          PlayerAvatar(
            emoji: player.emoji,
            color: player.profileColor,
            size: avatarSize,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              player.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight:
                    isWinner ? FontWeight.w700 : FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${player.foodCount}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isWinner ? AppColors.orange : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 4),
              Image.asset(
                'assets/images/icon_food.png',
                width: 16,
                height: 16,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Carte stats de partie
// ─────────────────────────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.gameState, required this.l10n});

  final GameState gameState;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final stats = gameState.sessionStats;

    return _StickerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: '📊',
            label: l10n.resultGameSummary,
          ),
          const SizedBox(height: AppSpacing.sm),
          _StatGrid(
            stats: [
              _StatItem(
                label: l10n.resultCardsPlayed,
                value: '${stats.cardsPlayed}',
              ),
              _StatItem(
                label: l10n.resultFoodGained,
                value: '${stats.foodGained}',
                iconAsset: 'assets/images/icon_food.png',
              ),
              _StatItem(
                label: l10n.resultFoodStolen,
                value: '${stats.foodStolen}',
                iconAsset: 'assets/images/icon_food.png',
              ),
              _StatItem(
                label: l10n.resultPinceCards,
                value: '${stats.pinceCardsPlayed}',
              ),
              _StatItem(
                label: l10n.resultRaccoonCards,
                value: '${stats.raccoonCardsPlayed}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  /// Chemin asset optionnel affiché à côté de la valeur (ex: icon_food.png).
  final String? iconAsset;
  const _StatItem({
    required this.label,
    required this.value,
    this.iconAsset,
  });
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats});

  final List<_StatItem> stats;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: stats
          .map(
            (s) => _StatChip(item: s),
          )
          .toList(),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.item});

  final _StatItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        border: Border.all(
          color: AppColors.shadowSoft,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    item.value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.textDark,
                    ),
                  ),
                  if (item.iconAsset != null) ...[
                    const SizedBox(width: 4),
                    Image.asset(
                      item.iconAsset!,
                      width: 14,
                      height: 14,
                    ),
                  ],
                ],
              ),
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.textMuted,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Composants partagés
// ─────────────────────────────────────────────────────────────────────────────

/// Carte sticker blanche avec ombre — conteneur générique des sections.
class _StickerCard extends StatelessWidget {
  const _StickerCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.stickerWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        boxShadow: AppShadows.floating,
      ),
      child: child,
    );
  }
}

/// En-tête de carte avec emoji + label.
class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.icon, required this.label});

  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
