import 'package:flutter/material.dart';

import 'core/navigation/app_router.dart';
import 'core/services/audio_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_theme_provider.dart';

/// Widget racine de l'application.
///
/// Observe le cycle de vie pour suspendre/reprendre l'audio
/// proprement (mise en arrière-plan, fermeture).
class RaccoonBanditApp extends StatefulWidget {
  const RaccoonBanditApp({super.key});

  @override
  State<RaccoonBanditApp> createState() => _RaccoonBanditAppState();
}

class _RaccoonBanditAppState extends State<RaccoonBanditApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Libère les ressources audio à la fermeture de l'app
    AudioService.instance.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Stoppe tous les sons si l'app passe en arrière-plan
    // (évite sons bloqués ou erreurs audio système)
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      AudioService.instance.stopAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reconstruit MaterialApp quand l'accent change (changement de dos de carte)
    return ListenableBuilder(
      listenable: AppThemeProvider.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Raccoon Bandit',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark.copyWith(
            colorScheme: AppTheme.dark.colorScheme.copyWith(
              secondary: AppThemeProvider.instance.accent,
            ),
          ),
          initialRoute: AppRoutes.home,
          onGenerateRoute: AppRouter.generateRoute,
        );
      },
    );
  }
}
