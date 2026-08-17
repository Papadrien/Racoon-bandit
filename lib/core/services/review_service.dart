import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'analytics_service.dart';

/// Service de demande d'avis via l'API native Google Play In-App Review.
///
/// Stratégie produit :
/// – 1ère sollicitation à la fin de la 2e partie.
/// – 2e et dernière sollicitation à la fin de la 6e partie.
/// – Plus jamais après, quel que soit le nombre de parties jouées ensuite.
///
/// ⚠️ Limite technique volontaire de l'API Google : l'app ne peut jamais
/// savoir si l'utilisateur a réellement laissé un avis (ni même si la popup
/// a réellement été affichée — Google la throttle côté serveur). On ne peut
/// donc pas conditionner la 2e demande à « il n'a pas mis d'avis la 1ère
/// fois », seulement à « on lui a déjà proposé une fois ».
class ReviewService {
  ReviewService._();

  static const _keyFirstPromptShown = 'review_first_prompt_shown_v1';
  static const _keySecondPromptShown = 'review_second_prompt_shown_v1';

  static const int firstPromptAtGame = 2;
  static const int secondPromptAtGame = 6;

  /// À appeler juste après la fin d'une partie, une fois le compteur de
  /// parties déjà incrémenté (StatsService.current.gamesPlayed).
  static Future<void> maybeRequestReview(int gamesPlayed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final firstShown = prefs.getBool(_keyFirstPromptShown) ?? false;
      final secondShown = prefs.getBool(_keySecondPromptShown) ?? false;

      // Déjà sollicité 2 fois : on ne redemande plus jamais.
      if (secondShown) return;

      final shouldPromptFirst =
          !firstShown && gamesPlayed >= firstPromptAtGame;
      final shouldPromptSecond =
          firstShown && !secondShown && gamesPlayed >= secondPromptAtGame;

      if (!shouldPromptFirst && !shouldPromptSecond) return;

      final inAppReview = InAppReview.instance;
      if (!await inAppReview.isAvailable()) return;

      await inAppReview.requestReview();

      if (shouldPromptFirst) {
        await prefs.setBool(_keyFirstPromptShown, true);
        unawaited(
          AnalyticsService.instance.logReviewPromptShown(attempt: 1),
        );
      } else if (shouldPromptSecond) {
        await prefs.setBool(_keySecondPromptShown, true);
        unawaited(
          AnalyticsService.instance.logReviewPromptShown(attempt: 2),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ReviewService] échec silencieux : $e');
      }
      // Ne jamais bloquer/casser l'écran de résultat si le service échoue.
    }
  }

  /// Utile pour les tests manuels / debug uniquement.
  static Future<void> resetForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFirstPromptShown);
    await prefs.remove(_keySecondPromptShown);
  }
}
