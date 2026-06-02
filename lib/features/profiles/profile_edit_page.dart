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
import '../../widgets/primary_button.dart';
import '../settings/widgets/settings_secondary_header.dart';

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
  static const _emojis = [
    '🦝', '🐼', '🦊', '🐸', '🐵', '🐻', '🐱', '🐶', '🐰', '🦁',
  ];

  static const _presetColors = [
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFFFDD835),
    Color(0xFF8E24AA),
    Color(0xFFFF6D00),
    Color(0xFFE91E8C),
    Color(0xFF00BCD4),
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

  Future<bool> _confirmDiscard() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        title: Text(l10n.profileEditDiscardTitle),
        content: Text(l10n.profileEditDiscardContent),
        actions: [
          TextButton(
            onPressed: () {
              AudioService.instance.playButtonSound();
              Navigator.pop(ctx, false);
            },
            child: Text(l10n.profileEditDiscardCancel),
          ),
          FilledButton(
            onPressed: () {
              AudioService.instance.playButtonSound();
              Navigator.pop(ctx, true);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: Text(l10n.profileEditDiscardConfirm),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameCtrl.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileEditNameEmpty)),
      );
      return;
    }

    final updated = widget.profile.copyWith(
      name: name,
      emoji: _emoji,
      colorValue: _color.toARGB32(),
    );

    if (widget.isNew) {
      await PlayerProfilesService.createProfile(updated);
    } else {
      await PlayerProfilesService.updateProfile(updated);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await _confirmDiscard();
        if (discard && mounted) Navigator.pop(context, false);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
        child: Column(
          children: [
            SettingsSecondaryHeader(
              title: widget.isNew
                  ? l10n.profileEditTitleNew
                  : l10n.profileEditTitleEdit,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ListView(
                    padding: EdgeInsets.fromLTRB(
                      constraints.maxWidth < 360
                          ? AppSpacing.hPadNarrow
                          : AppSpacing.hPadNormal,
                      AppSpacing.xl,
                      constraints.maxWidth < 360
                          ? AppSpacing.hPadNarrow
                          : AppSpacing.hPadNormal,
                      120,
                    ),
                    children: [
                      _PreviewCard(
                        emoji: _emoji,
                        color: _color,
                        name: _nameCtrl.text.trim().isEmpty
                            ? l10n.profileEditNameLabel
                            : _nameCtrl.text.trim(),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _SectionCard(
                        title: l10n.profileEditNameLabel,
                        child: TextField(
                          controller: _nameCtrl,
                          onChanged: (_) => setState(() {}),
                          textCapitalization: TextCapitalization.words,
                          maxLength: 20,
                          decoration: InputDecoration(
                            hintText: l10n.profileEditNameLabel,
                            filled: true,
                            fillColor: AppTheme.background,
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMedium,
                              ),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _SectionCard(
                        title: l10n.profileEditSectionAvatar,
                        child: Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: _emojis.map((emoji) {
                            final selected = emoji == _emoji;

                            return _EmojiButton(
                              emoji: emoji,
                              selected: selected,
                              onTap: () {
                                AudioService.instance.playButtonSound();
                                setState(() => _emoji = emoji);
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _SectionCard(
                        title: l10n.profileEditSectionColor,
                        child: Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.md,
                          children: _presetColors.map((color) {
                            final selected =
                                color.toARGB32() == _color.toARGB32();

                            return _ColorButton(
                              color: color,
                              selected: selected,
                              onTap: () {
                                AudioService.instance.playButtonSound();
                                setState(() => _color = color);
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      OrangeButton(
                        label: widget.isNew
                            ? l10n.profileEditButtonCreate
                            : l10n.profileEditButtonSave,
                        onPressed: () {
                          AudioService.instance.playButtonSound();
                          _save();
                        },
                        height: AppSpacing.buttonHeightSecondary,
                        fontSize: 15,
                        letterSpacing: 1.5,
                      ),
                    ],
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
}

class _PreviewCard extends StatelessWidget {
  final String emoji;
  final Color color;
  final String name;

  const _PreviewCard({
    required this.emoji,
    required this.color,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        boxShadow: AppShadows.sticker,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.22),
                width: 2,
              ),
            ),
            child: PlayerAvatar(
              emoji: emoji,
              color: color,
              size: 92,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.sectionCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.textMuted,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _EmojiButton extends StatelessWidget {
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const _EmojiButton({
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.14)
              : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: selected
                ? AppTheme.primary
                : AppTheme.textMuted.withValues(alpha: 0.16),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? AppShadows.soft : null,
        ),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 28),
          ),
        ),
      ),
    );
  }
}

class _ColorButton extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorButton({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: selected
              ? Border.all(color: Colors.white, width: 3)
              : null,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : AppShadows.soft,
        ),
        child: selected
            ? const Icon(Icons.check_rounded, color: Colors.white)
            : null,
      ),
    );
  }
}
