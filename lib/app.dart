import 'package:flutter/material.dart';

import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_theme_provider.dart';

class RaccoonBanditApp extends StatelessWidget {
  const RaccoonBanditApp({super.key});

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
