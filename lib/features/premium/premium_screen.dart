import 'package:flutter/material.dart';
import 'package:raccoon_bandit/l10n/app_localizations.dart';

import '../../core/services/audio_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/primary_button.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.premiumTitle),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            children: [
              const Spacer(),
              Icon(
                Icons.workspace_premium,
                size: 80,
                color: AppTheme.accent,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.premiumHeading,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.premiumSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textMuted, height: 1.6),
              ),
              const Spacer(),
              PrimaryButton(
                label: l10n.premiumBuyButton,
                // Intégration achat in-app prévue pour la prochaine phase
                onPressed: () {},
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  AudioService.instance.playButtonSound();
                },
                child: Text(
                  l10n.premiumRestorePurchases,
                  style: const TextStyle(color: AppTheme.textMuted),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
