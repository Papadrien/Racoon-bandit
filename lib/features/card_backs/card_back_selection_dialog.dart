import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/models/card_back_config.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/progression_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_theme_provider.dart';

/// Bottom sheet de sélection du dos de carte équipé.
///
/// Affiche tous les dos : débloqués (sélectionnables) et verrouillés
/// (indicateur de progression).
/// En mode debug, un bouton "Débloquer tous les dos" est affiché.
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

  @override
  void initState() {
    super.initState();
    _selectedId = ProgressionService.progression.selectedCardBackId;
  }

  Future<void> _equip(String cardBackId) async {
    if (_selectedId == cardBackId) return;
    await ProgressionService.equipCardBack(cardBackId);
    if (!mounted) return;
    setState(() => _selectedId = cardBackId);
    Navigator.of(context).pop(true);
  }

  Future<void> _debugUnlockAll() async {
    await ProgressionService.debugUnlockAll();
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final unlockedIds = ProgressionService.progression.unlockedCardBackIds;
    final allBacks = ProgressionService.cardBacks;

    return ListenableBuilder(
      listenable: AppThemeProvider.instance,
      builder: (context, _) {
        return DraggableScrollableSheet(
          initialChildSize: 0.60,
          minChildSize: 0.35,
          maxChildSize: 0.90,
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
                    'DOS DE CARTES',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                  // Bouton debug — visible uniquement en mode debug
                  if (kDebugMode) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        AudioService.instance.playButtonSound();
                        _debugUnlockAll();
                      },
                      icon: const Icon(Icons.lock_open, size: 16),
                      label: const Text('Débloquer tous les dos'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orangeAccent,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  const Divider(color: Colors.white12),
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: allBacks.length,
                      itemBuilder: (_, i) {
                        final cb = allBacks[i];
                        final isUnlocked = unlockedIds.contains(cb.id);
                        return _CardBackTile(
                          config: cb,
                          isUnlocked: isUnlocked,
                          isEquipped: cb.id == _selectedId,
                          onTap: isUnlocked ? () => _equip(cb.id) : null,
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
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _CardBackTile extends StatelessWidget {
  final CardBackConfig config;
  final bool isUnlocked;
  final bool isEquipped;
  final VoidCallback? onTap;

  const _CardBackTile({
    required this.config,
    required this.isUnlocked,
    required this.isEquipped,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = AppAssets.cardBackAsset(config.id);
    final fallbackColor = AppAssets.cardBackFallbackColor(config.id);
    final tileColor = config.themeColor;

    return GestureDetector(
      onTap: onTap == null ? null : () {
        AudioService.instance.playButtonSound();
        onTap!();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isEquipped
                ? tileColor
                : isUnlocked
                    ? Colors.white24
                    : Colors.white10,
            width: isEquipped ? 2.5 : 1.5,
          ),
          color: isEquipped
              ? tileColor.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.03),
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Stack(
                  children: [
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
                                0, 0, 0, 0.4, 0,
                              ]),
                        child: Image.asset(
                          assetPath,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, _a, _b) => Container(
                            width: double.infinity,
                            color: fallbackColor
                                .withValues(alpha: isUnlocked ? 1.0 : 0.4),
                          ),
                        ),
                      ),
                    ),
                    if (!isUnlocked)
                      Positioned.fill(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.lock_rounded,
                                color: Colors.white70,
                                size: 28,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _unlockHint(config),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
              child: Column(
                children: [
                  Text(
                    config.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isEquipped
                          ? Colors.white
                          : isUnlocked
                              ? AppTheme.textMuted
                              : Colors.white38,
                    ),
                  ),
                  if (isEquipped) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: tileColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'ÉQUIPÉ',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _unlockHint(CardBackConfig config) {
    if (config.unlockedByDefault || config.requiredGames == 0) return '';
    return '${config.requiredGames} partie${config.requiredGames > 1 ? 's' : ''}';
  }
}
