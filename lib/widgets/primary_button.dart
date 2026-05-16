import 'package:flutter/material.dart';

import '../core/services/audio_service.dart';
import '../core/services/haptic_service.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed == null
            ? null
            : () {
                HapticService.trigger(HapticType.selection);
                AudioService.instance.playSfx(SoundEffect.button);
                onPressed!();
              },
        child: Text(label),
      ),
    );
  }
}
