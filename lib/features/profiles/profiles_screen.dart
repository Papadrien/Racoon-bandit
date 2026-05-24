import 'package:flutter/material.dart';
import 'package:raccoon_bandit/l10n/app_localizations.dart';

import '../../core/models/player_profile.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/player_profiles_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/player_avatar.dart';
import 'profile_edit_page.dart';

class ProfilesScreen extends StatefulWidget {
  const ProfilesScreen({super.key});

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  late List<PlayerProfile> _profiles;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() => _profiles = PlayerProfilesService.sortedProfiles);
  }

  Future<void> _editProfile(PlayerProfile profile) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProfileEditPage(profile: profile)),
    );
    if (updated == true) _refresh();
  }

  Future<void> _addProfile() async {
    final profile = PlayerProfilesService.newProfile();
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileEditPage(profile: profile, isNew: true),
      ),
    );
    if (created == true) _refresh();
  }

  Future<void> _deleteProfile(PlayerProfile profile) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.profileDeleteTitle),
        content: Text(l10n.profileDeleteContent(profile.name)),
        actions: [
          TextButton(
            onPressed: () {
              AudioService.instance.playButtonSound();
              Navigator.pop(ctx, false);
            },
            child: Text(l10n.profileDeleteCancel),
          ),
          TextButton(
            onPressed: () {
              AudioService.instance.playButtonSound();
              Navigator.pop(ctx, true);
            },
            child: Text(
              l10n.profileDeleteConfirm,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await PlayerProfilesService.deleteProfile(profile.id);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profilesTitle),
        leading: const BackButton(),
      ),
      body: SafeArea(
        minimum: const EdgeInsets.symmetric(horizontal: 4),
        child: _profiles.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 56,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.profilesEmpty,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        AudioService.instance.playButtonSound();
                        _addProfile();
                      },
                      icon: const Icon(Icons.add),
                      label: Text(l10n.profilesAddTooltip),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: _profiles.length,
                separatorBuilder: (_, i) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final p = _profiles[i];
                  final color = Color(p.colorValue);
                  return _ProfileCard(
                    profile: p,
                    color: color,
                    onEdit: () {
                      AudioService.instance.playButtonSound();
                      _editProfile(p);
                    },
                    onDelete: () {
                      AudioService.instance.playButtonSound();
                      _deleteProfile(p);
                    },
                  );
                },
              ),
      ),
      floatingActionButton: _profiles.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                AudioService.instance.playButtonSound();
                _addProfile();
              },
              backgroundColor: AppTheme.primary,
              tooltip: l10n.profilesAddTooltip,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ProfileCard — carte de profil style cohérent avec Settings
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final PlayerProfile profile;
  final Color color;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProfileCard({
    required this.profile,
    required this.color,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.20),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            PlayerAvatar(
              emoji: profile.emoji,
              color: color,
              size: 52,
            ),
            const SizedBox(width: 16),

            // Nom
            Expanded(
              child: Text(
                profile.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Actions
            _ActionIconButton(
              icon: Icons.edit_outlined,
              color: AppTheme.primary,
              onPressed: onEdit,
            ),
            const SizedBox(width: 4),
            _ActionIconButton(
              icon: Icons.delete_outline,
              color: Colors.redAccent,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionIconButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}
