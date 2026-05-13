import 'package:flutter/material.dart';

import '../../core/models/player_profile.dart';
import '../../core/services/player_profiles_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/player_avatar.dart';

class ProfileEditPage extends StatefulWidget {
  final PlayerProfile profile;
  final bool isNew;

  const ProfileEditPage({
    super.key,
    required this.profile,
    this.isNew = false,
  });

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  // ── Données MVP hardcodées ───────────────────────────────────────────────
  static const _emojis = [
    '🦝', '🐼', '🦊', '🐸', '🐵', '🐻', '🐱', '🐶', '🐰', '🦁',
  ];

  static const _presetColors = [
    Color(0xFFE53935), // rouge
    Color(0xFF1E88E5), // bleu
    Color(0xFF43A047), // vert
    Color(0xFFFDD835), // jaune
    Color(0xFF8E24AA), // violet
    Color(0xFFFF6D00), // orange
    Color(0xFFE91E8C), // rose
    Color(0xFF00BCD4), // turquoise
  ];

  late final TextEditingController _nameCtrl;
  late String _emoji;
  late Color _color;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile.name);
    _emoji = widget.profile.emoji;
    _color = Color(widget.profile.colorValue);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom ne peut pas être vide.')),
      );
      return;
    }
    final updated = widget.profile.copyWith(
      name: name,
      emoji: _emoji,
      colorValue: _color.value,
    );
    if (widget.isNew) {
      await PlayerProfilesService.createProfile(updated);
    } else {
      await PlayerProfilesService.updateProfile(updated);
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'NOUVEAU PROFIL' : 'MODIFIER PROFIL'),
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Enregistrer',
            onPressed: _save,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          children: [
            // Aperçu avatar
            Center(
              child: PlayerAvatar(emoji: _emoji, color: _color, size: 88),
            ),
            const SizedBox(height: 32),

            // Nom
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom',
                border: OutlineInputBorder(),
                counterText: '',
              ),
              textCapitalization: TextCapitalization.words,
              maxLength: 20,
            ),
            const SizedBox(height: 28),

            // Sélecteur emoji
            _SectionLabel(label: 'Avatar'),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: _emojis.map((e) {
                final selected = e == _emoji;
                return GestureDetector(
                  onTap: () => setState(() => _emoji = e),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primary.withOpacity(0.18)
                          : Colors.transparent,
                      border: Border.all(
                        color: selected
                            ? AppTheme.primary
                            : AppTheme.textMuted.withOpacity(0.3),
                        width: selected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(e, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // Sélecteur couleur
            _SectionLabel(label: 'Couleur'),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.6,
              children: _presetColors.map((c) {
                final selected = c.value == _color.value;
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(10),
                      border: selected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: selected
                          ? [BoxShadow(color: c.withOpacity(0.6), blurRadius: 8)]
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: _save,
              child: Text(widget.isNew ? 'CRÉER' : 'ENREGISTRER'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 13,
        color: AppTheme.textMuted,
        letterSpacing: 1,
      ),
    );
  }
}
