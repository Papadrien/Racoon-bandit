import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Écran placeholder pour la politique de confidentialité.
/// À remplacer par le vrai contenu avant la mise en production Play Store.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CONFIDENTIALITÉ'),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône + titre
              Center(
                child: const Column(
                  children: [
                    const SizedBox(height: 32),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.privacy_tip_outlined,
                        color: AppTheme.primary,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Politique de confidentialité',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Raccoon Bandit',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Contenu placeholder
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _PolicySection(
                      title: 'Collecte de données',
                      content:
                          'Raccoon Bandit ne collecte aucune donnée personnelle. '
                          'Toutes les données de jeu sont stockées localement sur votre appareil.',
                    ),
                    const SizedBox(height: 16),
                    const _PolicySection(
                      title: 'Publicités',
                      content:
                          'L\'application peut afficher des publicités via Google AdMob. '
                          'Ces publicités peuvent utiliser des identifiants anonymisés '
                          'conformément à la politique de Google.',
                    ),
                    const SizedBox(height: 16),
                    const _PolicySection(
                      title: 'Contact',
                      content:
                          'Pour toute question concernant la confidentialité, '
                          'vous pouvez nous contacter via la page de l\'application '
                          'sur le Google Play Store.',
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Note placeholder
              Center(
                child: Text(
                  'Politique de confidentialité complète à venir',
                  style: TextStyle(
                    color: AppTheme.textMuted.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
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

class _PolicySection extends StatelessWidget {
  final String title;
  final String content;

  const const _PolicySection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.primary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
