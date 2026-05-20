# Raccoon Bandit — Firebase Analytics

## Architecture

Tous les événements passent par `lib/core/services/analytics_service.dart`.
**Aucun écran ne doit appeler `FirebaseAnalytics` directement.**

```
Écran / Service → AnalyticsService.instance.logXxx() → FirebaseAnalytics
```

## Événements implémentés

| Événement            | Déclencheur                          | Paramètres                                               |
|----------------------|--------------------------------------|----------------------------------------------------------|
| `app_open`           | Démarrage de l'app                   | —                                                        |
| `screen_view`        | Chaque changement de route           | `screen_name`                                            |
| `game_started`       | Lancement d'une partie (lobby)       | `nombre_joueurs`, `mode_pagaille`                        |
| `game_finished`      | Fin de partie (game screen)          | `nombre_joueurs`, `mode_pagaille`, `vainqueur`, `duree_estimee_s` |
| `life_consumed`      | Consommation d'une vie               | `vies_restantes`                                         |
| `life_restored`      | Recharge via timer                   | `vies_apres`, `source`                                   |
| `rewarded_ad_loaded` | Pub récompensée chargée              | —                                                        |
| `rewarded_ad_shown`  | Pub récompensée affichée             | —                                                        |
| `rewarded_ad_failed` | Échec chargement/affichage pub       | `raison`                                                 |
| `rewarded_ad_rewarded`| Récompense obtenue par l'utilisateur | —                                                        |

## Screens trackés automatiquement

Le `_AnalyticsNavigatorObserver` dans `app.dart` intercepte toutes les navigations :

| Route           | `screen_name` |
|-----------------|---------------|
| `/`             | `home`        |
| `/lobby`        | `lobby`       |
| `/game`         | `game`        |
| `/result`       | `result`      |
| `/profiles`     | `profiles`    |
| `/settings`     | `settings`    |
| `/premium`      | `premium`     |
| `/privacy-policy` | `privacy_policy` |

## Ajouter un nouvel événement

1. Ajouter la méthode dans `AnalyticsService`
2. Appeler `_send('nom_event', { 'param': valeur })` — max 40 chars pour le nom, max 36 chars pour les valeurs string
3. Appeler la méthode depuis l'écran/service concerné
4. Documenter ici

## Debug

En mode debug (`kDebugMode`), chaque événement loggué apparaît dans la console :
```
[Analytics] event: game_started {nombre_joueurs: 3, mode_pagaille: 0}
```

Pour visualiser en temps réel dans la console Firebase :
→ Console Firebase → Analytics → DebugView

## CI/CD — google-services.json

Le fichier `android/app/google-services.json` est dans `.gitignore`.

En CI, utiliser le script `scripts/inject_google_services.sh` avec la variable
`GOOGLE_SERVICES_JSON_BASE64` (secret GitHub Actions).

```yaml
- name: Inject Firebase config
  run: bash scripts/inject_google_services.sh
  env:
    GOOGLE_SERVICES_JSON_BASE64: ${{ secrets.GOOGLE_SERVICES_JSON_BASE64 }}
```

## Configuration Firebase requise

1. Créer un projet Firebase sur https://console.firebase.google.com
2. Ajouter une app Android (`fr.junade.raccoonbandit`)
3. Télécharger `google-services.json` → placer dans `android/app/`
4. Mettre à jour `lib/firebase_options.dart` avec les vraies valeurs
   (ou lancer `flutterfire configure` pour tout regénérer automatiquement)
