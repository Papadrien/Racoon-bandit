import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/models/card_back_config.dart';
import '../../core/services/progression_service.dart';
import '../../core/theme/app_theme.dart';

/// Bottom sheet de sélection du dos de carte équipé.
///
/// Affiche uniquement les dos débloqués.
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

  List<CardBackConfig> get _unlockedBacks {
    final unlockedIds = ProgressionService.progression.unlockedCardBackIds;
    return ProgressionService.cardBacks
        .where((cb) => unlockedIds.contains(cb.id))
        .toList();
  }

  Future<void> _equip(String cardBackId) async {
    if (_selectedId == cardBackId) return;
    await ProgressionService.equipCardBack(cardBackId);
    if (!mounted) return;
    setState(() => _selectedId = cardBackId);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final backs = _unlockedBacks;

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
                'DOS DE CARTES',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(color: Colors.white12),
              Expanded(
                child: backs.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun dos débloqué.',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                      )
                    : GridView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: backs.length,
                        itemBuilder: (_, i) =>
                            _CardBackTile(
                          config: backs[i],
                          isEquipped: backs[i].id == _selectedId,
                          onTap: () => _equip(backs[i].id),
                        ),
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

// ─────────────────────────────────────────────────────────────────────────────
// _CardBackTile
// ─────────────────────────────────────────────────────────────────────────────

class _CardBackTile extends StatelessWidget {
  final CardBackConfig config;
  final bool isEquipped;
  final VoidCallback onTap;

  const _CardBackTile({
    required this.config,
    required this.isEquipped,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = AppAssets.cardBackAsset(config.id);
    final fallbackColor = AppAssets.cardBackFallbackColor(config.id);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isEquipped ? AppTheme.primary : Colors.white12,
            width: isEquipped ? 2.5 : 1.5,
          ),
          color: isEquipped
              ? AppTheme.primary.withOpacity(0.08)
              : Colors.white.withOpacity(0.03),
        ),
        child: Column(
          children: [
            // Aperçu carte
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: assetPath != null
                      ? Image.asset(
                          assetPath,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        )
                      : Container(
                          width: double.infinity,
                          color: fallbackColor,
                        ),
                ),
              ),
            ),
            // Nom + badge équipé
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
              child: Column(
                children: [
                  Text(
                    config.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isEquipped ? Colors.white : AppTheme.textMuted,
                    ),
                  ),
                  if (isEquipped) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
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
}
