import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'settings_service.dart';

/// Effets sonores disponibles dans le jeu.
enum SoundEffect {
  /// Pioche d'une carte
  piocheCarte,

  /// Gain de nourriture (carte food jouée avec succès)
  gainNourriture,

  /// Pince attaque un joueur
  pince,

  /// Raton laveur vole de la nourriture
  raccoon,

  /// Frigo pose de carte trash
  frigo,

  /// Frigo bloque le raton (SFX dédié au blocage)
  fridgeBlock,

  /// Popup de récompense (débloquage)
  popupRecompense,

  /// Bouton UI
  button,

  // ── Legacy aliases (conservés pour compatibilité interne) ────────────────

  /// Alias legacy → piocheCarte
  draw,

  /// Alias legacy → gainNourriture
  cardPlayed,

  /// Alias legacy → raccoon ou bandit selon contexte
  steal,

  /// Alias legacy → frigo
  trash,

  /// Son de fin de partie (futur)
  gameOver,

  banquet,
  babyRaccoon,
  vacuum,
}

/// Service audio centralisé. Utiliser [AudioService.instance].
///
/// – Centralise tous les SFX du jeu.
/// – Anti-spam : cooldown par son.
/// – Respect du mute utilisateur ([SettingsService.soundEnabled]).
/// – Préchargement des sons fréquents via [preloadAll].
/// – Cycle application : libère les ressources proprement.
/// – Extensible : ajouter musique séparément sans toucher aux SFX.
class AudioService {
  AudioService._();

  static final AudioService instance = AudioService._();

  // ── Mapping effet → fichier asset ─────────────────────────────────────────

  static const _sounds = <SoundEffect, String>{
    SoundEffect.piocheCarte:    'sounds/pioche_carte.mp3',
    SoundEffect.gainNourriture: 'sounds/gain_nourriture.mp3',
    SoundEffect.pince:         'sounds/bandit.mp3',
    SoundEffect.raccoon:        'sounds/raccoon.mp3',
    SoundEffect.frigo:          'sounds/fridge_block.mp3',
    SoundEffect.fridgeBlock:    'sounds/frigo.mp3',
    SoundEffect.popupRecompense:'sounds/popup_recompense.mp3',
    SoundEffect.button:         'sounds/button_click.mp3',

    // Legacy aliases → redirigés vers les nouveaux sons
    SoundEffect.draw:      'sounds/pioche_carte.mp3',
    SoundEffect.cardPlayed:'sounds/gain_nourriture.mp3',
    SoundEffect.steal:     'sounds/raccoon.mp3',
    SoundEffect.trash:     'sounds/frigo.mp3',
    SoundEffect.gameOver:  'sounds/popup_recompense.mp3',
    SoundEffect.banquet: 'sounds/gain_nourriture.mp3',
    SoundEffect.babyRaccoon: 'sounds/raccoon.mp3',
    SoundEffect.vacuum: 'sounds/bandit.mp3',
  };

  /// Sons préchargés au démarrage (sons les plus fréquents en gameplay).
  static const _toPreload = [
    SoundEffect.piocheCarte,
    SoundEffect.gainNourriture,
    SoundEffect.bandit,
    SoundEffect.raccoon,
    SoundEffect.frigo,
    SoundEffect.fridgeBlock,
    SoundEffect.button,
  ];

  // ── Anti-spam ──────────────────────────────────────────────────────────────

  static const _cooldown = Duration(milliseconds: 100);
  final _lastPlayed = <SoundEffect, DateTime>{};

  // ── Pool de players préchargés ─────────────────────────────────────────────

  final _preloaded = <SoundEffect, AudioPlayer>{};
  bool _preloadDone = false;

  // ── API publique ───────────────────────────────────────────────────────────

  /// Précharge les sons gameplay fréquents pour éviter tout délai au premier son.
  /// À appeler une fois dans [main()] ou lors de l'initialisation de l'app.
  Future<void> preloadAll() async {
    if (_preloadDone) return;
    _preloadDone = true;

    for (final effect in _toPreload) {
      final path = _sounds[effect];
      if (path == null) continue;
      try {
        final player = AudioPlayer();
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setSource(AssetSource(path));
        _preloaded[effect] = player;
      } catch (e) {
        debugPrint('[AudioService] preload failed for $effect: $e');
      }
    }
  }

  /// Joue un effet sonore.
  ///
  /// Retourne silencieusement si :
  /// - le son est désactivé par l'utilisateur
  /// - le cooldown anti-spam n'est pas écoulé
  /// - le fichier est manquant ou l'audio est indisponible
  void playSfx(SoundEffect effect) {
    if (!SettingsService.soundEnabled) return;

    final now = DateTime.now();
    final last = _lastPlayed[effect];
    if (last != null && now.difference(last) < _cooldown) return;
    _lastPlayed[effect] = now;

    unawaited(_play(effect));
  }

  // ── Méthodes nommées (pour lisibilité dans les écrans) ────────────────────

  void playCardSound()    => playSfx(SoundEffect.piocheCarte);
  void playBanditSound()  => playSfx(SoundEffect.bandit);
  void playRaccoonSound() => playSfx(SoundEffect.raccoon);
  void playRewardSound()  => playSfx(SoundEffect.popupRecompense);
  void playButtonSound()  => playSfx(SoundEffect.button);
  void playFoodSound()    => playSfx(SoundEffect.gainNourriture);
  void playFrigoSound()    => playSfx(SoundEffect.frigo);
  void playFridgeBlockSound() => playSfx(SoundEffect.fridgeBlock);
  void playBanquetSound() => playSfx(SoundEffect.banquet);
  void playBabyRaccoonSound() => playSfx(SoundEffect.babyRaccoon);
  void playVacuumSound() => playSfx(SoundEffect.vacuum);

  /// Libère toutes les ressources audio (appel optionnel à la fermeture).
  Future<void> dispose() async {
    for (final player in _preloaded.values) {
      await player.dispose();
    }
    _preloaded.clear();
    _preloadDone = false;
  }

  /// Réservé pour usage futur (musique d'ambiance).
  /// Séparer musique / SFX : volume indépendant possible ici.
  void stopAll() {}

  // ── Lecture interne ────────────────────────────────────────────────────────

  Future<void> _play(SoundEffect effect) async {
    final path = _sounds[effect];
    if (path == null) return;

    // Utilise le player préchargé si disponible
    final preloaded = _preloaded[effect];
    if (preloaded != null) {
      try {
        await preloaded.stop();
        await preloaded.resume();
        return;
      } catch (_) {
        // Fallback sur création d'un nouveau player
      }
    }

    // Sinon crée un player jetable
    AudioPlayer? player;
    try {
      player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.release);
      await player.play(AssetSource(path));
    } catch (e) {
      debugPrint('[AudioService] play failed for $effect: $e');
      await player?.dispose();
    }
  }
}
