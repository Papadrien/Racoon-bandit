import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/primary_button.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PREMIUM'),
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
              const Text(
                'Raccoon Bandit\nPremium',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sans publicités • Vies illimitées\nThèmes exclusifs',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted, height: 1.6),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'ACHETER — 2,99 €',
                // Intégration achat in-app prévue pour la prochaine phase
                onPressed: () {},
              ),
              const SizedBox(height: 12),
              TextButton(
                // Restauration achats prévue pour la prochaine phase
                onPressed: () {},
                child: const Text(
                  'Restaurer les achats',
                  style: TextStyle(color: AppTheme.textMuted),
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
