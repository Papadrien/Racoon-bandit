import 'package:raccoon_bandit/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/models/card_back_config.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/progression_service.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/app_shadows.dart';
import '../../core/ui/app_spacing.dart';

/// Bottom sheet de sélection du dos de carte — style premium cohérent
/// avec le Design System beige/sticker de l'app (Home, Lobby).
///
/// Fond chaud, coins très arrondis, ombres douces, effet floating card.
/// Appeler via [CardBackSelectionDialog.show].
class CardBackSelectionDialog extends StatefulWidget {
  const CardBackSelectionDialog({super.key});

  /// Ouvre la bottom sheet et retourne `true` si le dos a changé.
  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const CardBackSelectionDialog(),
    );
    return result ?? false;
  }

  @override
  State<CardBackSelectionDialog> createState() =>
      _CardBackSelectionDialogState();
}

class _CardBackSelectionDialogState extends State<CardBackSelectionDialog> {
  late String _selectedId;
  late String _initialId;
  String? animatingId;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _selectedId = ProgressionService.progression.selectedCardBackId;
    _initialId = _selectedId;
  }

  Future<void> _equip(String cardBackId) async {
    if (_selectedId == cardBackId) return;

    setState(() {
      animatingId = cardBackId;
      _selectedId = cardBackId;
      _hasChanged = _selectedId != _initialId;
    });

    AudioService.instance.playButtonSound();

    await ProgressionService.equipCardBack(cardBackId);

    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => animatingId = null);
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFF6D00);
    return Builder(
      builder: (context) {
        final unlockedIds = ProgressionService.progression.unlockedCardBackIds;
        final allBacks = ProgressionService.cardBacks;
        final totalGames = ProgressionService.progression.totalGamesPlayed;

        return DraggableScrollableSheet(
          initialChildSize: 0.68,
          minChildSize: 0.45,
          maxChildSize: 0.94,
          snap: true,
          snapSizes: const [0.68, 0.94],
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXLarge)),
                boxShadow: AppShadows.sticker,
              ),
              child: Column(
                children: [
                  // Drag handle
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg),
                    child: Row(
                      children: [
                        // Icône accent
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMedium),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.28),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.style_rounded,
                            color: accent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.cardBacksTitle,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                AppLocalizations.of(context)!
                                    .gamesPlayed(totalGames),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Bouton fermer
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(_hasChanged),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.stickerWhite,
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusSmall + 2),
                              boxShadow: AppShadows.soft,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: AppColors.textMuted,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),
                  Divider(
                    color: AppColors.textMuted.withValues(alpha: 0.13),
                    height: 1,
                    indent: AppSpacing.lg,
                    endIndent: AppSpacing.lg,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Grid
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, AppSpacing.md,
                          AppSpacing.lg, AppSpacing.xl),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: AppSpacing.md,
                        crossAxisSpacing: AppSpacing.md,
                        childAspectRatio: 0.70,
                      ),
                      itemCount: allBacks.length,
                      itemBuilder: (_, i) {
                        final cb = allBacks[i];
                        final isUnlocked = unlockedIds.contains(cb.id);
                        final isEquipped = cb.id == _selectedId;
                        final isAnimating = cb.id == animatingId;

                        return _CardBackTile(
                          key: ValueKey(cb.id),
                          config: cb,
                          isUnlocked: isUnlocked,
                          isEquipped: isEquipped,
                          isAnimating: isAnimating,
                          totalGames: totalGames,
                          onTap: isUnlocked ? () => _equip(cb.id) : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tile
// ─────────────────────────────────────────────────────────────────────────────

class _CardBackTile extends StatefulWidget {
  const _CardBackTile({
    super.key,
    required this.config,
    required this.isUnlocked,
    required this.isEquipped,
    required this.isAnimating,
    required this.totalGames,
    required this.onTap,
  });

  final CardBackConfig config;
  final bool isUnlocked;
  final bool isEquipped;
  final bool isAnimating;
  final int totalGames;
  final VoidCallback? onTap;

  @override
  State<_CardBackTile> createState() => _CardBackTileState();
}

class _CardBackTileState extends State<_CardBackTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.05)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.05, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
    ]).animate(_ctrl);

    _glow = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 65,
      ),
    ]).animate(_ctrl);
  }

  @override
  void didUpdateWidget(_CardBackTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating && !oldWidget.isAnimating) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.config.themeColor;
    final assetPath = AppAssets.cardBackAsset(widget.config.id);
    final fallback = AppAssets.cardBackFallbackColor(widget.config.id);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final glowStrength = widget.isEquipped ? 0.5 : _glow.value;

        return Transform.scale(
          scale: _scale.value,
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: widget.isEquipped
                    ? AppColors.stickerWhite
                    : widget.isUnlocked
                        ? AppColors.stickerWhite
                        : AppColors.stickerWhite.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                border: Border.all(
                  color: widget.isEquipped
                      ? color.withValues(alpha: 0.65)
                      : widget.isUnlocked
                          ? color.withValues(alpha: 0.18)
                          : AppColors.textMuted.withValues(alpha: 0.10),
                  width: widget.isEquipped ? 2.0 : 1.2,
                ),
                boxShadow: [
                  if (widget.isEquipped)
                    ...[
                      ...AppShadows.subtleGlow(color),
                      ...AppShadows.floating,
                    ]
                  else if (glowStrength > 0)
                    BoxShadow(
                      color: color.withValues(alpha: glowStrength * 0.28),
                      blurRadius: 14,
                      spreadRadius: 0,
                    )
                  else
                    ...AppShadows.soft,
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge - 1),
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                        child: _CardPreview(
                          assetPath: assetPath,
                          fallbackColor: fallback,
                          isUnlocked: widget.isUnlocked,
                          isEquipped: widget.isEquipped,
                          color: color,
                          config: widget.config,
                          totalGames: widget.totalGames,
                        ),
                      ),
                    ),
                    _CardFooter(
                      config: widget.config,
                      isUnlocked: widget.isUnlocked,
                      isEquipped: widget.isEquipped,
                      color: color,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Preview image
// ─────────────────────────────────────────────────────────────────────────────

class _CardPreview extends StatelessWidget {
  const _CardPreview({
    required this.assetPath,
    required this.fallbackColor,
    required this.isUnlocked,
    required this.isEquipped,
    required this.color,
    required this.config,
    required this.totalGames,
  });

  final String assetPath;
  final Color fallbackColor;
  final bool isUnlocked;
  final bool isEquipped;
  final Color color;
  final CardBackConfig config;
  final int totalGames;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image (désaturée si verrouillée)
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          child: ColorFiltered(
            colorFilter: isUnlocked
                ? const ColorFilter.mode(
                    Colors.transparent, BlendMode.multiply)
                : const ColorFilter.matrix([
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0,      0,      0,      0.38, 0,
                  ]),
            child: Image.asset(
              assetPath,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, a, b) => Container(
                width: double.infinity,
                color: fallbackColor.withValues(alpha: isUnlocked ? 0.25 : 0.10),
              ),
            ),
          ),
        ),

        // Overlay + cadenas si verrouillé
        if (!isUnlocked)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.10),
                    AppColors.background.withValues(alpha: 0.55),
                  ],
                ),
              ),
              child: Center(
                child: _LockedOverlay(
                  config: config,
                  totalGames: totalGames,
                  color: color,
                ),
              ),
            ),
          ),

        // Badge "ÉQUIPÉ" coin supérieur droit
        if (isEquipped)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                boxShadow: AppShadows.subtleGlow(color),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_rounded, color: Colors.white, size: 9),
                  const SizedBox(width: 3),
                  Text(
                    AppLocalizations.of(context)!.equipped,
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overlay verrouillé
// ─────────────────────────────────────────────────────────────────────────────

class _LockedOverlay extends StatelessWidget {
  const _LockedOverlay({
    required this.config,
    required this.totalGames,
    required this.color,
  });

  final CardBackConfig config;
  final int totalGames;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final required = config.requiredGames;
    final progress = required > 0
        ? (totalGames / required).clamp(0.0, 1.0)
        : 0.0;
    final remaining = (required - totalGames).clamp(0, required);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.stickerWhite.withValues(alpha: 0.80),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.textMuted.withValues(alpha: 0.20),
                width: 1.5,
              ),
              boxShadow: AppShadows.soft,
            ),
            child: const Icon(
              Icons.lock_rounded,
              color: AppColors.textMuted,
              size: 18,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$remaining partie${remaining > 1 ? 's' : ''}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: AppColors.textMuted.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(
                color.withValues(alpha: 0.70),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Footer
// ─────────────────────────────────────────────────────────────────────────────

class _CardFooter extends StatelessWidget {
  const _CardFooter({
    required this.config,
    required this.isUnlocked,
    required this.isEquipped,
    required this.color,
  });

  final CardBackConfig config;
  final bool isUnlocked;
  final bool isEquipped;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            config.name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isEquipped
                  ? AppColors.textDark
                  : isUnlocked
                      ? AppColors.textDark.withValues(alpha: 0.75)
                      : AppColors.textMuted.withValues(alpha: 0.50),
            ),
          ),
          if (!isUnlocked && !config.unlockedByDefault) ...[
            const SizedBox(height: 2),
            Text(
              AppLocalizations.of(context)!.requiredGames(config.requiredGames),
              style: TextStyle(
                fontSize: 9,
                color: AppColors.textMuted.withValues(alpha: 0.55),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (isUnlocked && !isEquipped) ...[
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)!.tapToEquip,
              style: TextStyle(
                fontSize: 9,
                color: color.withValues(alpha: 0.70),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
          if (isEquipped) const SizedBox(height: 6),
        ],
      ),
    );
  }
}
