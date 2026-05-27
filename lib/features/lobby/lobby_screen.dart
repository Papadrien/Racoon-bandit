import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/game/game_state.dart';
import '../../core/models/lobby_composition.dart';
import '../../core/models/player_profile.dart';
import '../../core/models/player_state.dart';
import '../../core/navigation/app_router.dart';
import '../card_backs/card_back_selection_dialog.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/lobby_service.dart';
import '../../core/services/player_profiles_service.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/progression_service.dart';
import '../../core/constants/app_assets.dart';
import '../../core/models/card_back_config.dart';
// import '../../core/theme/app_theme.dart';
import '../../core/services/life_system_service.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/app_decorations.dart';
import '../../core/ui/app_shadows.dart';
import '../../core/ui/app_spacing.dart';
import '../../widgets/player_avatar.dart';
import '../../widgets/primary_button.dart';
import 'package:raccoon_bandit/l10n/app_localizations.dart';
import 'chaos_mode_tutorial.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  int _playerCount = 2;

  late List<PlayerProfile?> _selectedProfiles;
  bool _chaosModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _initFromSaved();
  }

  void _initFromSaved() {
    final saved = LobbyService.lastComposition;
    final all = PlayerProfilesService.sortedProfiles;

    if (saved != null && saved.playerCount >= 2 && saved.playerCount <= 4) {
      _playerCount = saved.playerCount;
      _selectedProfiles = List.generate(_playerCount, (i) {
        if (i < saved.profileIds.length && saved.profileIds[i].isNotEmpty) {
          try {
            return all.firstWhere((p) => p.id == saved.profileIds[i]);
          } catch (_) {
            return null;
          }
        }
        return null;
      });
    } else {
      _selectedProfiles = List.filled(_playerCount, null);
    }

    _fillEmptySlots();
  }

  void _fillEmptySlots() {
    final usedIds = _usedProfileIds;
    final available = PlayerProfilesService.sortedProfiles
        .where((p) => !usedIds.contains(p.id))
        .toList();

    int avIdx = 0;
    for (int i = 0; i < _selectedProfiles.length; i++) {
      if (_selectedProfiles[i] == null && avIdx < available.length) {
        _selectedProfiles[i] = available[avIdx];
        avIdx++;
      }
    }
  }

  void _onCountChanged(int count) {
    setState(() {
      _playerCount = count;
      final old = List<PlayerProfile?>.from(_selectedProfiles);
      _selectedProfiles = List.generate(
        count,
        (i) => i < old.length ? old[i] : null,
      );
      _fillEmptySlots();
    });
  }

  Set<String> get _usedProfileIds => _selectedProfiles
      .where((p) => p != null)
      .map((p) => p!.id)
      .toSet();

  Future<void> _openPicker(int slotIndex) async {
    final all = PlayerProfilesService.sortedProfiles;
    final current = _selectedProfiles[slotIndex];

    final otherUsedIds = <String>{};
    for (int i = 0; i < _selectedProfiles.length; i++) {
      if (i != slotIndex && _selectedProfiles[i] != null) {
        otherUsedIds.add(_selectedProfiles[i]!.id);
      }
    }

    final picked = await showModalBottomSheet<PlayerProfile>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ProfilePickerSheet(
        profiles: all,
        currentProfileId: current?.id,
        disabledProfileIds: otherUsedIds,
      ),
    );

    if (picked != null && mounted) {
      setState(() => _selectedProfiles[slotIndex] = picked);
    }
  }

  Future<void> _openCardBackSelection() async {
    final changed = await CardBackSelectionDialog.show(context);
    if (changed && mounted) setState(() {});
  }

  Future<void> _openChaosTutorial() async {
    AudioService.instance.playButtonSound();
    await ChaosTutorial.show(context);
  }

  bool get _canStart =>
      _playerCount >= 2 && _selectedProfiles.every((p) => p != null);

  bool _navigationInProgress = false;

  Future<void> _startGame() async {
    if (_playerCount < 2) return;
    if (_navigationInProgress) return;

    _navigationInProgress = true;

    final players = List.generate(_playerCount, (i) {
      final profile = _selectedProfiles[i];
      return PlayerState(
        id: i + 1,
        name: profile?.name ?? 'Joueur ${i + 1}',
        profileId: profile?.id,
        emoji: profile?.emoji,
        colorValue: profile?.colorValue,
      );
    });

    final lifeSystemService = LifeSystemService();
    await lifeSystemService.load();

    if (lifeSystemService.currentLives <= 0) {
      _navigationInProgress = false;
      return;
    }

    await lifeSystemService.consumeLife();

    unawaited(AnalyticsService.instance.logLifeConsumed(
      livesRemaining: lifeSystemService.currentLives,
    ));

    unawaited(AnalyticsService.instance.logGameStarted(
      nombreJoueurs: _playerCount,
      modePagailleActif: _chaosModeEnabled,
    ));

    await LobbyService.saveComposition(
      LobbyComposition(
        playerCount: _playerCount,
        profileIds: _selectedProfiles.map((p) => p?.id ?? '').toList(),
      ),
    );

    if (!mounted) {
      _navigationInProgress = false;
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.game,
      arguments: GameState(players: players, chaosMode: _chaosModeEnabled),
    ).then((_) {
      if (mounted) _navigationInProgress = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (kDebugMode && didPop) {
          // ignore: avoid_print
          print('[LobbyScreen] back pressed — retour home');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // ── Fond décoratif ─────────────────────────────────────────────
            const _LobbyBackground(),

            // ── Contenu principal ──────────────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  // ── Header ───────────────────────────────────────────────
                  _LobbyHeader(onBack: () => Navigator.pop(context)),

                  // ── Corps scrollable ─────────────────────────────────────
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 360;
                        final hPad = isNarrow
                            ? AppSpacing.hPadNarrow
                            : AppSpacing.hPadNormal;
                        return SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: hPad,
                            vertical: AppSpacing.lg,
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight - AppSpacing.xl,
                            ),
                            child: IntrinsicHeight(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // ── Sélecteur joueurs ────────────────────
                                  _PlayerCountSelector(
                                    playerCount: _playerCount,
                                    onChanged: _onCountChanged,
                                  ),
                                  const SizedBox(height: AppSpacing.xl),

                                  // ── Slots joueurs ────────────────────────
                                  ...List.generate(
                                    _playerCount,
                                    (i) => _PlayerSlotCard(
                                      slotIndex: i,
                                      profile: _selectedProfiles[i],
                                      onTap: () => _openPicker(i),
                                    ),
                                  ),

                                  const Spacer(),
                                  const SizedBox(height: AppSpacing.xl),

                                  // ── Bouton démarrer ──────────────────────
                                  PrimaryButton(
                                    label: AppLocalizations.of(context)!.lobbyStart,
                                    onPressed: _canStart ? _startGame : null,
                                  ),
                                  const SizedBox(height: AppSpacing.lg),

                                  // ── Mode Pagaille ────────────────────────
                                  _ChaosModeSection(
                                    enabled: _chaosModeEnabled,
                                    onToggle: (value) {
                                      setState(() => _chaosModeEnabled = value);
                                    },
                                    onHelpTap: _openChaosTutorial,
                                  ),
                                  const SizedBox(height: AppSpacing.md),

                                  // ── Dos de cartes ────────────────────────
                                  _CardBackButton(
                                    selectedId: ProgressionService
                                        .progression.selectedCardBackId,
                                    onTap: () {
                                      AudioService.instance.playButtonSound();
                                      _openCardBackSelection();
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.xl),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LobbyBackground — fond beige avec stickers décoratifs légers
// ─────────────────────────────────────────────────────────────────────────────

class _LobbyBackground extends StatelessWidget {
  const _LobbyBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          // Fond beige uni
          Container(color: AppColors.background),

          // Dégradé doux en bas pour profondeur
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 220,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withValues(alpha: 0),
                    AppColors.backgroundLight.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
          ),

          // Sticker sapin — haut gauche
          const Positioned(
            top: 40,
            left: -10,
            child: _StickerAsset(
              asset: 'assets/images/sticker_pine_tree.png',
              size: 90,
              opacity: 0.12,
              angle: -0.15,
            ),
          ),

          // Sticker sapin — haut droite
          const Positioned(
            top: 20,
            right: -8,
            child: _StickerAsset(
              asset: 'assets/images/sticker_pine_tree.png',
              size: 75,
              opacity: 0.10,
              angle: 0.18,
            ),
          ),

          // Sticker pomme de pin — milieu droite
          const Positioned(
            top: 260,
            right: 4,
            child: _StickerAsset(
              asset: 'assets/images/sticker_pine_cone.png',
              size: 44,
              opacity: 0.14,
              angle: 0.25,
            ),
          ),

          // Sticker cabane — bas gauche
          const Positioned(
            bottom: 140,
            left: -6,
            child: _StickerAsset(
              asset: 'assets/images/sticker_cabin.png',
              size: 72,
              opacity: 0.11,
              angle: -0.08,
            ),
          ),

          // Sticker pomme de pin — bas droite
          const Positioned(
            bottom: 200,
            right: 8,
            child: _StickerAsset(
              asset: 'assets/images/sticker_pine_cone.png',
              size: 38,
              opacity: 0.13,
              angle: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _StickerAsset extends StatelessWidget {
  final String asset;
  final double size;
  final double opacity;
  final double angle;

  const _StickerAsset({
    required this.asset,
    required this.size,
    required this.opacity,
    required this.angle,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Opacity(
        opacity: opacity,
        child: Image.asset(
          asset,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LobbyHeader — header personnalisé cohérent avec le Home
// ─────────────────────────────────────────────────────────────────────────────

class _LobbyHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _LobbyHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          // Bouton retour style sticker
          GestureDetector(
            onTap: () {
              AudioService.instance.playButtonSound();
              onBack();
            },
            child: Container(
              width: AppSpacing.floatingButtonSize,
              height: AppSpacing.floatingButtonSize,
              decoration: AppDecorations.floatingButton(),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textDark,
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          // Titre
          Expanded(
            child: Text(
              l10n.lobbyTitle,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PlayerCountSelector — sélecteur nombre de joueurs adapté au thème beige
// ─────────────────────────────────────────────────────────────────────────────

class _PlayerCountSelector extends StatelessWidget {
  final int playerCount;
  final ValueChanged<int> onChanged;

  const _PlayerCountSelector({
    required this.playerCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Text(
          l10n.lobbyPlayerCount,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: AppColors.stickerWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            boxShadow: AppShadows.floating,
          ),
          padding: const EdgeInsets.all(AppSpacing.xs + 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [2, 3, 4].map((count) {
              final selected = count == playerCount;
              return GestureDetector(
                onTap: () {
                  AudioService.instance.playButtonSound();
                  onChanged(count);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 64,
                  height: 52,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.orange : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    boxShadow: selected ? AppShadows.button : null,
                  ),
                  child: Center(
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: selected ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ChaosModeSection — adapté au thème beige
// ─────────────────────────────────────────────────────────────────────────────

class _ChaosModeSection extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final VoidCallback onHelpTap;

  const _ChaosModeSection({
    required this.enabled,
    required this.onToggle,
    required this.onHelpTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.stickerWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(
          color: enabled
              ? AppColors.violet.withValues(alpha: 0.30)
              : AppColors.shadowSubtle,
          width: 1.5,
        ),
        boxShadow: AppShadows.floating,
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: enabled
                        ? AppColors.violet.withValues(alpha: 0.10)
                        : AppColors.backgroundLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('🌀', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.lobbyChaosTitle,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        AppLocalizations.of(context)!.lobbyChaosSubtitle,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onHelpTap,
            icon: const Icon(Icons.help_outline_rounded, size: 20),
            color: AppColors.textMuted,
            tooltip: AppLocalizations.of(context)!.lobbyChaosTooltip,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
          ),
          Switch(
            value: enabled,
            onChanged: (val) {
              AudioService.instance.playButtonSound();
              onToggle(val);
            },
            activeThumbColor: AppColors.violet,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PlayerSlotCard — adapté au thème beige/sticker
// ─────────────────────────────────────────────────────────────────────────────

class _PlayerSlotCard extends StatelessWidget {
  final int slotIndex;
  final PlayerProfile? profile;
  final VoidCallback onTap;

  const _PlayerSlotCard({
    required this.slotIndex,
    required this.profile,
    required this.onTap,
  });

  static List<String> _slotLabels(AppLocalizations l10n) => [
        l10n.lobbySlot1,
        l10n.lobbySlot2,
        l10n.lobbySlot3,
        l10n.lobbySlot4,
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = _slotLabels(l10n)[slotIndex % 4];
    final hasProfile = profile != null;
    final accentColor =
        hasProfile ? Color(profile!.colorValue) : AppColors.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm - 1),
      child: GestureDetector(
        onTap: () {
          AudioService.instance.playButtonSound();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md + 2,
          ),
          decoration: BoxDecoration(
            color: hasProfile
                ? AppColors.stickerWhite
                : AppColors.stickerWhite.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            border: Border.all(
              color: hasProfile
                  ? accentColor.withValues(alpha: 0.22)
                  : AppColors.textMuted.withValues(alpha: 0.12),
              width: 1.5,
            ),
            boxShadow: hasProfile ? AppShadows.floating : AppShadows.soft,
          ),
          child: Row(
            children: [
              // Avatar ou placeholder
              if (hasProfile)
                PlayerAvatar(
                  emoji: profile!.emoji,
                  color: Color(profile!.colorValue),
                  size: 52,
                )
              else
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.textMuted.withValues(alpha: 0.20),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.person_add_outlined,
                    color: AppColors.textMuted,
                    size: 22,
                  ),
                ),

              const SizedBox(width: AppSpacing.lg),

              // Textes
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasProfile
                          ? profile!.name
                          : l10n.lobbyChooseProfile,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: hasProfile
                            ? AppColors.textDark
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right_rounded,
                color: accentColor.withValues(alpha: hasProfile ? 0.45 : 0.30),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CardBackButton — aperçu visuel du dos sélectionné avec animation idle
// ─────────────────────────────────────────────────────────────────────────────

class _CardBackButton extends StatefulWidget {
  final String selectedId;
  final VoidCallback onTap;

  const _CardBackButton({
    required this.selectedId,
    required this.onTap,
  });

  @override
  State<_CardBackButton> createState() => _CardBackButtonState();
}

class _CardBackButtonState extends State<_CardBackButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _idleCtrl;
  late Animation<double> _floatAnim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _idleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -2.5, end: 2.5).animate(
      CurvedAnimation(parent: _idleCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _idleCtrl.dispose();
    super.dispose();
  }

  CardBackConfig get _config {
    try {
      return ProgressionService.cardBacks
          .firstWhere((c) => c.id == widget.selectedId);
    } catch (_) {
      return ProgressionService.cardBacks.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _config;
    final accentColor = config.themeColor;
    final cardBackId = widget.selectedId;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        AudioService.instance.playButtonSound();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md + 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.stickerWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.20),
              width: 1.5,
            ),
            boxShadow: AppShadows.floating,
          ),
          child: Row(
            children: [
              _AnimatedCardPreview(
                assetPath: AppAssets.cardBackAsset(cardBackId),
                accentColor: accentColor,
                floatAnim: _floatAnim,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.lobbyCardBackLabel,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      config.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.30),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.lobbyCardBackEquipped,
                        style: TextStyle(
                          fontSize: 10,
                          color: accentColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: accentColor.withValues(alpha: 0.5),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mini carte inclinée avec animation de flottement
class _AnimatedCardPreview extends StatelessWidget {
  final String assetPath;
  final Color accentColor;
  final Animation<double> floatAnim;

  const _AnimatedCardPreview({
    required this.assetPath,
    required this.accentColor,
    required this.floatAnim,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: floatAnim,
      builder: (_, child) {
        return Transform.translate(
          offset: Offset(0, floatAnim.value),
          child: Transform.rotate(
            angle: -0.12 + floatAnim.value * 0.006,
            child: child,
          ),
        );
      },
      child: Container(
        width: 52,
        height: 74,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(2, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: accentColor.withValues(alpha: 0.2),
              child: Icon(Icons.style, color: accentColor, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ProfilePickerSheet
// ─────────────────────────────────────────────────────────────────────────────

class _ProfilePickerSheet extends StatelessWidget {
  final List<PlayerProfile> profiles;
  final String? currentProfileId;
  final Set<String> disabledProfileIds;

  const _ProfilePickerSheet({
    required this.profiles,
    required this.currentProfileId,
    required this.disabledProfileIds,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: AppShadows.sticker,
          ),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.md),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                AppLocalizations.of(context)!.lobbyChooseProfile,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Divider(color: AppColors.textMuted.withValues(alpha: 0.15)),
              Expanded(
                child: profiles.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            AppLocalizations.of(context)!.lobbyNoProfiles,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                        itemCount: profiles.length,
                        itemBuilder: (_, i) {
                          final p = profiles[i];
                          final isDisabled =
                              disabledProfileIds.contains(p.id);
                          final isCurrent = p.id == currentProfileId;
                          final color = Color(p.colorValue);

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xs + 1),
                            child: Opacity(
                              opacity: isDisabled ? 0.35 : 1.0,
                              child: GestureDetector(
                                onTap: isDisabled
                                    ? null
                                    : () {
                                        AudioService.instance.playButtonSound();
                                        Navigator.pop(context, p);
                                      },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.lg,
                                    vertical: AppSpacing.md,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? color.withValues(alpha: 0.10)
                                        : AppColors.stickerWhite,
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusLarge),
                                    border: Border.all(
                                      color: isCurrent
                                          ? color.withValues(alpha: 0.45)
                                          : AppColors.textMuted
                                              .withValues(alpha: 0.10),
                                      width: isCurrent ? 2 : 1,
                                    ),
                                    boxShadow: AppShadows.soft,
                                  ),
                                  child: Row(
                                    children: [
                                      PlayerAvatar(
                                        emoji: p.emoji,
                                        color: color,
                                        size: 44,
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Text(
                                          p.name,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: isDisabled
                                                ? AppColors.textMuted
                                                : AppColors.textDark,
                                          ),
                                        ),
                                      ),
                                      if (isDisabled)
                                        Text(
                                          AppLocalizations.of(context)!
                                              .lobbyProfileAlreadyUsed,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textMuted,
                                            letterSpacing: 0.5,
                                          ),
                                        )
                                      else if (isCurrent)
                                        Icon(
                                          Icons.check_circle,
                                          color: color,
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      },
    );
  }
}
