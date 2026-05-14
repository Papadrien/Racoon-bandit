import '../core/game/game_state.dart';
import '../core/models/reward_unlock.dart';

/// Arguments passés à [ResultScreen] via Navigator.
class ResultScreenArgs {
  const ResultScreenArgs({
    required this.gameState,
    this.newUnlocks = const [],
  });

  final GameState gameState;

  /// Récompenses débloquées pendant cette partie (peut être vide).
  final List<RewardUnlock> newUnlocks;
}
