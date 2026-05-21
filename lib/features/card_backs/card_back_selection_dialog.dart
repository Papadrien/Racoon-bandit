import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/models/card_back_config.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/progression_service.dart';
import '../../core/theme/app_theme_provider.dart';

/// Bottom sheet de sélection du dos de carte équipé — version premium.
///
/// Affiche tous les dos dans des cartes UI dédiées avec :
/// - preview full, nom, état débloqué/verrouillé, badge équipé
/// - animation scale + glow au moment de l'équipement
/// - thème UI mis à jour instantanément sans fermer le sheet
/// - dos verrouillés : désaturés, cadenas, barre de progression
///
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

    // Sauvegarde + mise à jour thème (instantané, sans fermer le sheet)
    await ProgressionService.equipCardBack(cardBackId);

    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => animatingId = null);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppThemeProvider.instance,
      builder: (context, _) {
        final accent = AppThemeProvider.instance.accent;
        final unlockedIds = ProgressionService.progression.unlockedCardBackIds;
        final allBacks = ProgressionService.cardBacks;
        final totalGames = ProgressionService.progression.totalGamesPlayed;

        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.42,
          maxChildSize: 0.94,
          snap: true,
          snapSizes: const [0.65, 0.94],
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF16162A),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.18),
                    blurRadius: 32,
                    spreadRadius: 2,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 14),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Header avec bouton fermer
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SheetHeader(
                            accent: accent,
                            totalGames: totalGames,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(_hasChanged),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white54,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),
                  Divider(
                    color: accent.withValues(alpha: 0.18),
                    height: 1,
                    indent: 20,
                    endIndent: 20,
                  ),
                  const SizedBox(height: 4),

                  // Grid
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.68,
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
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.accent, required this.totalGames});

  final Color accent;
  final int totalGames;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: accent.withValues(alpha: 0.35), width: 1),
            ),
            child: Icon(Icons.style_rounded, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.cardBacksTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.5,
                    color: Colors.white,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.gamesPlayed(totalGames),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.42),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
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
      duration: const Duration(milliseconds: 480),
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.07)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.07, end: 1.0)
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
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: widget.isEquipped
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withValues(alpha: 0.22),
                          color.withValues(alpha: 0.08),
                          const Color(0xFF1E1E38),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      )
                    : widget.isUnlocked
                        ? const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF252540), Color(0xFF1A1A30)],
                          )
                        : const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF1C1C2E), Color(0xFF16162A)],
                          ),
                border: Border.all(
                  color: widget.isEquipped
                      ? color
                      : widget.isUnlocked
                          ? color.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.07),
                  width: widget.isEquipped ? 2.0 : 1.0,
                ),
                boxShadow: [
                  if (widget.isEquipped || glowStrength > 0)
                    BoxShadow(
                      color: color.withValues(
                        alpha: widget.isEquipped
                            ? 0.28 + glowStrength * 0.22
                            : glowStrength * 0.45,
                      ),
                      blurRadius:
                          widget.isEquipped ? 18 + glowStrength * 10 : 14,
                      spreadRadius: widget.isEquipped ? 1 : 0,
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
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
          borderRadius: BorderRadius.circular(10),
          child: ColorFiltered(
            colorFilter: isUnlocked
                ? const ColorFilter.mode(
                    Colors.transparent, BlendMode.multiply)
                : const ColorFilter.matrix([
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0,      0,      0,      0.35, 0,
                  ]),
            child: Image.asset(
              assetPath,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, a, b) => Container(
                width: double.infinity,
                color: fallbackColor.withValues(alpha: isUnlocked ? 1.0 : 0.3),
              ),
            ),
          ),
        ),

        // Overlay + cadenas si verrouillé
        if (!isUnlocked)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.20),
                    Colors.black.withValues(alpha: 0.55),
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
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.55),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded, color: Colors.white, size: 10),
                  SizedBox(width: 3),
                  Text(
                    AppLocalizations.of(context)!.equipped,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.lock_rounded,
              color: Colors.white70,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$remaining partie${remaining > 1 ? 's' : ''}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(
                color.withValues(alpha: 0.80),
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
                  ? Colors.white
                  : isUnlocked
                      ? Colors.white.withValues(alpha: 0.80)
                      : Colors.white.withValues(alpha: 0.30),
            ),
          ),
          if (!isUnlocked && !config.unlockedByDefault) ...[
            const SizedBox(height: 2),
            Text(
              AppLocalizations.of(context)!.requiredGames(config.requiredGames),
              style: TextStyle(
                fontSize: 9,
                color: Colors.white.withValues(alpha: 0.22),
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
                color: color.withValues(alpha: 0.60),
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
