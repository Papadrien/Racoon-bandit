import 'package:flutter/material.dart';

import '../../core/game/game_state.dart';
import '../../core/models/lobby_composition.dart';
import '../../core/models/player_profile.dart';
import '../../core/models/player_state.dart';
import '../../core/navigation/app_router.dart';
import '../../core/services/lobby_service.dart';
import '../../core/services/player_profiles_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/player_avatar.dart';
import '../../widgets/primary_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LobbyScreen
// ─────────────────────────────────────────────────────────────────────────────

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  int _playerCount = 2;

  /// Profil sélectionné pour chaque slot (length == _playerCount).
  late List<PlayerProfile?> _selectedProfiles;

  @override
  void initState() {
    super.initState();
    _initFromSaved();
  }

  // ── Init ──────────────────────────────────────────────────────────────────

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

  /// Remplit les slots vides avec les premiers profils non encore utilisés.
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

  // ── Player count ──────────────────────────────────────────────────────────

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

  // ── Profile picker ────────────────────────────────────────────────────────

  Set<String> get _usedProfileIds => _selectedProfiles
      .where((p) => p != null)
      .map((p) => p!.id)
      .toSet();

  Future<void> _openPicker(int slotIndex) async {
    final all = PlayerProfilesService.sortedProfiles;
    final current = _selectedProfiles[slotIndex];

    // IDs utilisés dans les AUTRES slots uniquement
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

  // ── Start game ────────────────────────────────────────────────────────────

  bool get _canStart =>
      _playerCount >= 2 && _selectedProfiles.every((p) => p != null);

  Future<void> _startGame() async {
    if (_playerCount < 2) return;
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

    await LobbyService.saveComposition(
      LobbyComposition(
        playerCount: _playerCount,
        profileIds: _selectedProfiles.map((p) => p?.id ?? '').toList(),
      ),
    );

    if (!mounted) return;
    Navigator.pushNamed(
      context,
      AppRoutes.game,
      arguments: GameState(players: players),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LOBBY'),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              // ── Sélecteur nombre de joueurs ─────────────────────────────
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
                      onTap: () => _onCountChanged(count),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color:
                              selected ? AppTheme.primary : Colors.transparent,
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
                              color:
                                  selected ? Colors.white : AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              // ── Slots joueurs ──────────────────────────────────────────
              ...List.generate(
                _playerCount,
                (i) => _PlayerSlotCard(
                  slotIndex: i,
                  profile: _selectedProfiles[i],
                  onTap: () => _openPicker(i),
                ),
              ),
              const Spacer(),
              // ── Bouton démarrer ────────────────────────────────────────
              PrimaryButton(
                label: 'COMMENCER',
                onPressed: _canStart ? _startGame : null,
              ),
              const SizedBox(height: 16),
            ],
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
          onTap: onTap,
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
                // Avatar
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
                // Nom + label slot
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
                // Chevron
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
              // Handle
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
              // Liste des profils
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
                                      : () => Navigator.pop(context, p),
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
