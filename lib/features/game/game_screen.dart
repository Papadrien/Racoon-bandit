import 'package:flutter/material.dart';

import '../../core/navigation/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/lives_bar.dart';
import '../../widgets/primary_button.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int _lives = 3;

  void _onAdBonus() {
    if (_lives < 3) {
      setState(() => _lives++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            LivesBar(
              lives: _lives,
              onAdBonus: _onAdBonus,
            ),
            const Expanded(
              child: Center(
                child: Text(
                  'Zone de jeu',
                  style: TextStyle(
                    fontSize: 20,
                    color: AppTheme.textMuted,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: PrimaryButton(
                label: 'RÉSULTATS',
                onPressed: () => Navigator.pushNamed(context, AppRoutes.result),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
