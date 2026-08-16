import 'package:flutter/material.dart';
import 'package:raccoon_bandit/l10n/app_localizations.dart';

import '../../core/services/audio_service.dart';
import '../../core/services/purchase_service.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/app_shadows.dart';
import '../../core/ui/app_spacing.dart';
import '../../widgets/primary_button.dart';

/// Pop-up de présentation et d'achat du pack Premium.
///
/// Premium débloque en un seul achat non-consommable :
///  - la suppression des publicités récompensées,
///  - des parties illimitées (plus de restriction/attente entre parties),
///  - tous les dos de cartes.
///
/// Ouvrir via [PremiumDialog.show]. Retourne `true` si l'achat a abouti
/// pendant que la pop-up était ouverte (utile pour rafraîchir l'écran
/// appelant).
class PremiumDialog extends StatefulWidget {
  const PremiumDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const PremiumDialog(),
    );
    return result ?? false;
  }

  @override
  State<PremiumDialog> createState() => _PremiumDialogState();
}

class _PremiumDialogState extends State<PremiumDialog> {
  final PurchaseService _purchaseService = PurchaseService.instance;

  bool _isBuying = false;
  bool _isRestoring = false;
  bool _purchasedDuringSession = false;

  Future<void> _buy() async {
    if (_isBuying || _purchaseService.isPremium) return;

    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isBuying = true);
    AudioService.instance.playButtonSound();

    final started = await _purchaseService.buyPremium();

    if (!mounted) return;
    setState(() => _isBuying = false);

    if (!started) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.premiumUnavailable)),
      );
      return;
    }

    // La confirmation arrive de façon asynchrone via le flux d'achats ;
    // on observe le notifier quelques instants pour donner un retour
    // immédiat si l'achat se conclut pendant que la pop-up est ouverte.
    await _watchForActivation(messenger, l10n);
  }

  Future<void> _restore() async {
    if (_isRestoring) return;

    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isRestoring = true);
    AudioService.instance.playButtonSound();

    await _purchaseService.restorePurchases();
    await _watchForActivation(messenger, l10n, silent: true);

    if (!mounted) return;
    setState(() => _isRestoring = false);
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.premiumRestoreDone)),
    );
  }

  Future<void> _watchForActivation(
    ScaffoldMessengerState messenger,
    AppLocalizations l10n, {
    bool silent = false,
  }) async {
    for (var i = 0; i < 20; i++) {
      if (_purchaseService.isPremium) {
        if (!_purchasedDuringSession) {
          _purchasedDuringSession = true;
          if (!silent) {
            messenger.showSnackBar(
              SnackBar(content: Text(l10n.premiumPurchaseSuccess)),
            );
          }
          if (mounted) setState(() {});
        }
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ValueListenableBuilder<bool>(
      valueListenable: _purchaseService.premiumNotifier,
      builder: (context, isPremium, _) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
          ),
          decoration: const BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXLarge)),
            boxShadow: AppShadows.sticker,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                      border: Border.all(
                        color: AppColors.orange.withValues(alpha: 0.28),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: AppColors.orange,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      l10n.premiumHeading,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        height: 1.15,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        Navigator.of(context).pop(_purchasedDuringSession),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.stickerWhite,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSmall + 2),
                        boxShadow: AppShadows.soft,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textMuted,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              if (isPremium) ...[
                _ActivePremiumBanner(l10n: l10n),
              ] else ...[
                Text(
                  l10n.premiumDescription,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                _BenefitRow(
                  icon: Icons.block_rounded,
                  label: l10n.premiumBenefitNoAds,
                ),
                const SizedBox(height: AppSpacing.sm + 2),
                _BenefitRow(
                  icon: Icons.all_inclusive_rounded,
                  label: l10n.premiumBenefitUnlimitedGames,
                ),
                const SizedBox(height: AppSpacing.sm + 2),
                _BenefitRow(
                  icon: Icons.style_rounded,
                  label: l10n.premiumBenefitAllCardBacks,
                ),

                const SizedBox(height: AppSpacing.xl),

                OrangeButton(
                  label: _isBuying
                      ? l10n.premiumBuying
                      : (_purchaseService.premiumProduct?.price ??
                          l10n.premiumBuyButton),
                  isLoading: _isBuying,
                  onPressed: _isBuying ? null : _buy,
                ),

                const SizedBox(height: AppSpacing.md),

                Center(
                  child: TextButton(
                    onPressed: _isRestoring ? null : _restore,
                    child: Text(
                      _isRestoring
                          ? l10n.premiumRestoring
                          : l10n.premiumRestorePurchases,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ligne d'avantage — icône + texte
// ─────────────────────────────────────────────────────────────────────────────

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.orange.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          ),
          child: Icon(icon, color: AppColors.orange, size: 18),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bannière affichée quand Premium est déjà actif
// ─────────────────────────────────────────────────────────────────────────────

class _ActivePremiumBanner extends StatelessWidget {
  const _ActivePremiumBanner({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.stickerWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.28)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.orange,
            size: 32,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.premiumActiveLabel,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.premiumActiveThanks,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
