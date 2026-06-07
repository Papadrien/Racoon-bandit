import 'package:flutter/material.dart';

/// Logo RACCOON BANDIT — rendu depuis l'asset PNG.
class RaccoonBanditLogo extends StatelessWidget {
  const RaccoonBanditLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/raccoon_bandit_logo.png',
      fit: BoxFit.contain,
    );
  }
}
