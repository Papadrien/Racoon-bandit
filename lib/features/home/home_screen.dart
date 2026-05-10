import 'package:flutter/material.dart';

import '../../core/navigation/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/primary_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            children: [
              // Top bar : settings + premium
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.workspace_premium),
                    color: AppTheme.accent,
                    tooltip: 'Premium',
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.premium),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    color: AppTheme.textMuted,
                    tooltip: 'Paramètres',
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.settings),
                  ),
                ],
              ),
              const Spacer(),
              const _Logo(),
              const Spacer(),
              PrimaryButton(
                label: 'JOUER',
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.lobby),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'RACCOON',
          style: Theme.of(context)
              .textTheme
              .displayLarge
              ?.copyWith(color: AppTheme.primary),
        ),
        Text(
          'BANDIT',
          style: Theme.of(context)
              .textTheme
              .displayLarge
              ?.copyWith(color: AppTheme.accent),
        ),
        const SizedBox(height: 12),
        const Text(
          'multijoueur local',
          style: TextStyle(
            color: AppTheme.textMuted,
            letterSpacing: 3,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
