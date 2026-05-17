import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/game/game_state.dart';
import '../../core/models/lobby_composition.dart';
import '../../core/models/player_profile.dart';
import '../../core/models/player_state.dart';
import '../../core/navigation/app_router.dart';
import '../card_backs/card_back_selection_dialog.dart';
import '../../core/services/lobby_service.dart';
import '../../core/services/player_profiles_service.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/progression_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/life_system_service.dart';
import '../../widgets/player_avatar.dart';
import '../../widgets/primary_button.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  int _playerCount = 2;

  late List<PlayerProfile?> _selectedProfiles;

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
      arguments: GameState(players: players),
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
        appBar: AppBar(
          title: const Text('SALON'),
          leading: const BackButton(),
        ),
        body: SafeArea(
          minimum: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 360;
              final hPad = isNarrow ? 16.0 : 24.0;
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Spacer(),
                        // ── Sélecteur nombre de joueurs ─────────────────────
                        const Text(
                          'Nombre de joueurs',
                          style: TextStyle(fontSize: 18, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [2, 3, 4].map((count) {
                            final selected = count == _playerCount;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: GestureDetector(
                                onTap: () {
                                  AudioService.instance.playButtonSound();
                                  _onCountChanged(count);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: selected ? AppTheme.primary : Colors.transparent,
                                    border: Border.all(
                                      color: selected
                                          ? AppTheme.primary
                                          : AppTheme.textMuted,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$count',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: selected ? Colors.white : AppTheme.textMuted,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 32),
                        // ── Slots joueurs ──────────────────────────────────
                        ...List.generate(
                          _playerCount,
                          (i) => _PlayerSlotCard(
                            slotIndex: i,
                            profile: _selectedProfiles[i],
                            onTap: () => _openPicker(i),
                          ),
                        ),
                        const Spacer(),
                        // ── Bouton démarrer ────────────────────────────────
                        PrimaryButton(
                          label: 'COMMENCER',
                          onPressed: _canStart ? _startGame : null,
                        ),
                        const SizedBox(height: 12),
                        // ── Bouton dos de cartes ───────────────────────────
                        _CardBackButton(
                          selectedId: ProgressionService.progression.selectedCardBackId,
                          onTap: () {
                            AudioService.instance.playButtonSound();
                            _openCardBackSelection();
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PlayerSlotCard
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

  static const _slotLabels = ['Joueur 1', 'Joueur 2', 'Joueur 3', 'Joueur 4'];

  @override
  Widget build(BuildContext context) {
    final label = _slotLabels[slotIndex % _slotLabels.length];
    final hasProfile = profile != null;
    final color =
        hasProfile ? Color(profile!.colorValue) : AppTheme.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            AudioService.instance.playButtonSound();
            onTap();
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: color.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                if (hasProfile)
                  PlayerAvatar(
                    emoji: profile!.emoji,
                    color: Color(profile!.colorValue),
                    size: 48,
                  )
                else
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.textMuted.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.textMuted.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_add_outlined,
                      color: AppTheme.textMuted,
                      size: 22,
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasProfile ? profile!.name : 'Choisir un profil',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: hasProfile ? Colors.white : AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: color.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CardBackButton
// ─────────────────────────────────────────────────────────────────────────────

class _CardBackButton extends StatelessWidget {
  final String selectedId;
  final VoidCallback onTap;

  const _CardBackButton({
    required this.selectedId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          AudioService.instance.playButtonSound();
          onTap();
        },
        icon: const Icon(Icons.style_outlined, size: 18),
        label: Text('Dos de cartes · $selectedId'.toUpperCase()),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textMuted,
          side: const BorderSide(color: Colors.white12, width: 1.5),
          minimumSize: const Size(double.infinity, 48),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
            color: Color(0xFF1E1E2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Choisir un profil',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(color: Colors.white12),
              Expanded(
                child: profiles.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Aucun profil disponible.\nCréez des profils dans les réglages.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: profiles.length,
                        itemBuilder: (_, i) {
                          final p = profiles[i];
                          final isDisabled = disabledProfileIds.contains(p.id);
                          final isCurrent = p.id == currentProfileId;
                          final color = Color(p.colorValue);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Opacity(
                              opacity: isDisabled ? 0.35 : 1.0,
                              child: Material(
                                color: isCurrent
                                    ? color.withValues(alpha: 0.18)
                                    : color.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  onTap: isDisabled
                                      ? null
                                      : () {
                                          AudioService.instance.playButtonSound();
                                          Navigator.pop(context, p);
                                        },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isCurrent
                                            ? color.withValues(alpha: 0.8)
                                            : color.withValues(alpha: 0.25),
                                        width: isCurrent ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        PlayerAvatar(
                                          emoji: p.emoji,
                                          color: color,
                                          size: 44,
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Text(
                                            p.name,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: isDisabled
                                                  ? AppTheme.textMuted
                                                  : Colors.white,
                                            ),
                                          ),
                                        ),
                                        if (isDisabled)
                                          const Text(
                                            'Déjà utilisé',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.textMuted,
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
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
