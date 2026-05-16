import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import 'settings_service.dart';

enum SoundEffect { draw, cardPlayed, steal, trash, gameOver, button }

/// Service audio centralisé. Utiliser [AudioService.instance].
///
/// Tous les appels échouent silencieusement (fichiers manquants,
/// audio indisponible, etc.).
class AudioService {
  AudioService._();

  static final AudioService instance = AudioService._();

  static const _sounds = {
    SoundEffect.draw: 'sounds/draw.ogg',
    SoundEffect.cardPlayed: 'sounds/card_played.ogg',
    SoundEffect.steal: 'sounds/steal.ogg',
    SoundEffect.trash: 'sounds/trash.ogg',
    SoundEffect.gameOver: 'sounds/game_over.ogg',
    SoundEffect.button: 'sounds/button.ogg',
  };

  /// Anti-spam : cooldown minimal entre deux plays du même son.
  static const _cooldown = Duration(milliseconds: 120);
  final _lastPlayed = <SoundEffect, DateTime>{};

  /// Joue un effet sonore si le son est activé et hors cooldown.
  void playSfx(SoundEffect effect) {
    if (!SettingsService.soundEnabled) return;

    final now = DateTime.now();
    final last = _lastPlayed[effect];
    if (last != null && now.difference(last) < _cooldown) return;
    _lastPlayed[effect] = now;

    unawaited(_play(effect));
  }

  Future<void> _play(SoundEffect effect) async {
    final path = _sounds[effect];
    if (path == null) return;

    AudioPlayer? player;
    try {
      player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.release);
      await player.play(AssetSource(path));
      // Le player se dispose lui-même après play en mode release
    } catch (_) {
      // Fichier manquant ou audio indisponible → silencieux
      await player?.dispose();
    }
  }

  /// Réservé pour usage futur (musique d'ambiance, etc.).
  void stopAll() {}
}
