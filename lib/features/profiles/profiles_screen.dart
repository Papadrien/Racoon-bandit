import 'package:flutter/material.dart';
import 'package:raccoon_bandit/l10n/app_localizations.dart';

import '../../core/models/player_profile.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/player_profiles_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/app_decorations.dart';
import '../../core/ui/app_shadows.dart';
import '../../core/ui/app_spacing.dart';
import '../../widgets/player_avatar.dart';
import '../settings/widgets/settings_secondary_header.dart';
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
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
          FilledButton(
            onPressed: () {
              AudioService.instance.playButtonSound();
              Navigator.pop(ctx, true);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: Text(l10n.profileDeleteConfirm),
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
      floatingActionButton: _profiles.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                AudioService.instance.playButtonSound();
                _addProfile();
              },
              backgroundColor: AppTheme.primary,
              elevation: 0,
              label: Text(l10n.profilesAddTooltip),
              icon: const Icon(Icons.add_rounded),
            ),
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: SettingsSecondaryHeader(title: l10n.profilesTitle),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _profiles.isEmpty
                  ? _EmptyProfilesState(onAdd: _addProfile)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        100,
                      ),
                      itemCount: _profiles.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (_, i) {
                        final profile = _profiles[i];

                        return _ProfileCard(
                          profile: profile,
                          color: Color(profile.colorValue),
                          onEdit: () {
                            AudioService.instance.playButtonSound();
                            _editProfile(profile);
                          },
                          onDelete: () {
                            AudioService.instance.playButtonSound();
                            _deleteProfile(profile);
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyProfilesState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyProfilesState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: AppDecorations.floatingSticker,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.people_alt_rounded,
                  size: 42,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.profilesEmpty,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    AudioService.instance.playButtonSound();
                    onAdd();
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.profilesAddTooltip),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(
          color: color.withValues(alpha: 0.16),
          width: 1.5,
        ),
        boxShadow: AppShadows.floating,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.25),
                  width: 2,
                ),
              ),
              child: PlayerAvatar(
                emoji: profile.emoji,
                color: color,
                size: 60,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionIconButton(
                  icon: Icons.edit_rounded,
                  color: AppTheme.primary,
                  onPressed: onEdit,
                ),
                const SizedBox(height: AppSpacing.sm),
                _ActionIconButton(
                  icon: Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  onPressed: onDelete,
                ),
              ],
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
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Ink(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}
