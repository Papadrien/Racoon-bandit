import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/lives_indicator.dart';
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
              const Align(
                alignment: Alignment.topRight,
                child: LivesIndicator(lives: 3),
              ),
              const Spacer(),
              const _Logo(),
              const Spacer(),
              PrimaryButton(
                label: 'JOUER',
                onPressed: () {
                  // TODO: navigation vers l'écran de jeu
                },
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
          style: Theme.of(context).textTheme.displayLarge
              ?.copyWith(color: AppTheme.primary),
        ),
        Text(
          'BANDIT',
          style: Theme.of(context).textTheme.displayLarge
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
