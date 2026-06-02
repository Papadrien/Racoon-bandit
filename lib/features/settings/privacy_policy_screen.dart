import 'package:flutter/material.dart';

import '../../core/ui/app_colors.dart';
import 'widgets/settings_secondary_header.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String _policy = r'''Politique de confidentialité – Raccoon Bandit

Introduction

Raccoon Bandit est un jeu de cartes familial conçu pour être simple, amusant et accessible aux enfants comme aux adultes.

La protection de votre vie privée est importante. Cette politique explique quelles informations peuvent être collectées lors de l'utilisation de l'application et comment elles sont utilisées.

Données collectées

Raccoon Bandit ne demande pas et ne collecte pas directement de données personnelles permettant d'identifier un utilisateur, telles que son nom, son adresse ou son numéro de téléphone.

Toutefois, certains services tiers intégrés à l'application peuvent collecter automatiquement des informations techniques.

Publicités

Raccoon Bandit peut afficher des publicités récompensées via Google AdMob.

Achats intégrés

L'application propose un achat intégré optionnel permettant de débloquer le mode Premium et de supprimer les publicités.

Statistiques et analyses

Raccoon Bandit utilise Firebase Analytics afin de recueillir des statistiques anonymisées sur l'utilisation de l'application.

Enfants et protection des données

Raccoon Bandit est conçu pour un usage familial.

Services tiers

- Google AdMob
- Google Play Billing / App Store In-App Purchases
- Firebase Analytics

Liens :
https://policies.google.com/privacy

https://firebase.google.com/support/privacy

Vos droits (RGPD)

Pour toute demande relative à vos données :

papadrien.prepa@gmail.com

Modifications de cette politique

Cette politique peut être mise à jour à tout moment.

Contact

papadrien.prepa@gmail.com''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SettingsSecondaryHeader(title: 'Politique de confidentialité'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SelectableText(_policy),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
