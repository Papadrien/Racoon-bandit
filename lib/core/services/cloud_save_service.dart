import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/global_progression.dart';
import '../models/global_stats.dart';
import 'play_games_service.dart';
import 'progression_service.dart';
import 'stats_service.dart';

/// Sauvegarde cloud complète (stats + progression) synchronisée entre
/// appareils via le même compte Google Play Games.
///
/// Stockage : Firestore, document `cloud_saves/{playerId}`.
///
/// Stratégie de fusion — jamais d'écrasement destructeur :
/// – à la connexion (splash), on fusionne le cloud avec le local en
///   prenant le meilleur des deux (max des compteurs, union des dos de
///   cartes débloqués). Jouer sur un 2e appareil ne fait donc jamais
///   perdre de progression sur le 1er, ni inversement.
/// – à chaque fin de partie, on repousse l'état local (déjà fusionné)
///   vers le cloud.
///
/// ⚠️ Sécurité — à lire avant mise en prod :
/// L'accès au document est prévu pour être restreint côté règles
/// Firestore (voir `firestore.rules` à la racine du projet) au
/// `playerId` Play Games fourni dans la requête. Sans lier ce playerId à
/// Firebase Auth — ce qui demanderait un pont natif Play Games → Firebase
/// Auth non couvert ici — il ne s'agit pas d'une vérification
/// cryptographique de l'identité : quelqu'un connaissant l'ID d'un autre
/// joueur pourrait théoriquement lire/écrire sa sauvegarde. Acceptable
/// pour de la progression de jeu non sensible et sans lien avec un achat,
/// mais à garder en tête.
class CloudSaveService {
  CloudSaveService._();

  static const String _collection = 'cloud_saves';

  static CollectionReference<Map<String, dynamic>> get _saves =>
      FirebaseFirestore.instance.collection(_collection);

  /// À appeler au splash, juste après le chargement local (StatsService +
  /// ProgressionService) et après PlayGamesService.signInSilently().
  /// Ne fait rien si aucun joueur n'est connecté : l'app continue alors
  /// avec la seule sauvegarde locale, comme avant.
  static Future<void> pullAndMerge() async {
    final playerId = PlayGamesService.playerId;
    if (playerId == null) return;

    try {
      final doc = await _saves.doc(playerId).get();
      final data = doc.data();

      if (!doc.exists || data == null) {
        // Rien dans le cloud pour ce joueur : on amorce avec l'état local.
        await _pushInternal(playerId);
        return;
      }

      final rawStats = data['stats'];
      final rawProgression = data['progression'];

      if (rawStats is Map) {
        final cloudStats =
            GlobalStats.fromJson(Map<String, dynamic>.from(rawStats));
        StatsService.current = _mergeStats(StatsService.current, cloudStats);
        await StatsService.save();
      }

      if (rawProgression is Map) {
        final cloudProgression =
            GlobalProgression.fromMap(Map<String, dynamic>.from(rawProgression));
        await ProgressionService.mergeFromCloud(cloudProgression);
      }

      // Repousse l'état fusionné : le cloud reflète désormais le meilleur
      // des deux, prêt pour un 3e appareil éventuel.
      await _pushInternal(playerId);
    } catch (e) {
      if (kDebugMode) debugPrint('[CloudSaveService] pull échoué : $e');
      // Échec silencieux : l'app continue avec la sauvegarde locale seule.
    }
  }

  /// À appeler à la fin de chaque partie, après que StatsService et
  /// ProgressionService locaux ont été mis à jour.
  static Future<void> pushAfterGame() async {
    final playerId = PlayGamesService.playerId;
    if (playerId == null) return;
    try {
      await _pushInternal(playerId);
    } catch (e) {
      if (kDebugMode) debugPrint('[CloudSaveService] push échoué : $e');
    }
  }

  static Future<void> _pushInternal(String playerId) async {
    await _saves.doc(playerId).set({
      'stats': StatsService.current.toJson(),
      'progression': ProgressionService.progression.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static GlobalStats _mergeStats(GlobalStats local, GlobalStats cloud) {
    return GlobalStats(
      gamesPlayed: math.max(local.gamesPlayed, cloud.gamesPlayed),
      gamesWon: math.max(local.gamesWon, cloud.gamesWon),
      totalFoodGained: math.max(local.totalFoodGained, cloud.totalFoodGained),
      totalFoodStolen: math.max(local.totalFoodStolen, cloud.totalFoodStolen),
      totalCardsPlayed:
          math.max(local.totalCardsPlayed, cloud.totalCardsPlayed),
      totalPinceCardsPlayed:
          math.max(local.totalPinceCardsPlayed, cloud.totalPinceCardsPlayed),
      totalRaccoonCardsPlayed: math.max(
        local.totalRaccoonCardsPlayed,
        cloud.totalRaccoonCardsPlayed,
      ),
      // Champ non alimenté ailleurs dans l'app actuellement — conservé
      // tel quel pour ne rien casser si un jour il l'est.
      achievements: local.achievements,
    );
  }
}
