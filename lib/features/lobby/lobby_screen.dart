import 'package:flutter/material.dart';

import '../../core/navigation/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/primary_button.dart';

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LOBBY'),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              const Icon(Icons.people, size: 72, color: AppTheme.primary),
              const SizedBox(height: 24),
              const Text(
                'Choisissez les joueurs',
                style: TextStyle(fontSize: 18, color: AppTheme.textMuted),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'LANCER LA PARTIE',
                onPressed: () => Navigator.pushNamed(context, AppRoutes.game),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
