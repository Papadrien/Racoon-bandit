import 'package:flutter/material.dart';

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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le profil ?'),
        content: Text('Supprimer "${profile.name}" définitivement ?'),
        actions: [
          TextButton(
            onPressed: () {
              AudioService.instance.playButtonSound();
              Navigator.pop(ctx, false);
            },
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              AudioService.instance.playButtonSound();
              Navigator.pop(ctx, true);
            },
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.redAccent),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('PROFILS'),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: _profiles.isEmpty
            ? const Center(
                child: Text(
                  'Aucun profil',
                  style: TextStyle(color: AppTheme.textMuted),
                ),
              )
            : ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                itemCount: _profiles.length,
                // Fix: séparateur avec paramètre correctement nommé
                separatorBuilder: (_, _i) =>
                    const Divider(color: AppTheme.textMuted, height: 1),
                itemBuilder: (_, i) {
                  final p = _profiles[i];
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    leading: PlayerAvatar(
                      emoji: p.emoji,
                      color: Color(p.colorValue),
                      size: 52,
                    ),
                    title: Text(
                      p.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              color: AppTheme.primary),
                          onPressed: () {
                            AudioService.instance.playButtonSound();
                            _editProfile(p);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          onPressed: () {
                            AudioService.instance.playButtonSound();
                            _deleteProfile(p);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          AudioService.instance.playButtonSound();
          _addProfile();
        },
        backgroundColor: AppTheme.primary,
        tooltip: 'Ajouter un profil',
        child: const Icon(Icons.add),
      ),
    );
  }
}
