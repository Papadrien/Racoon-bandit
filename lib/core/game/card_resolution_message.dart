/// Identifiant du message d'effet, résolu côté UI avec AppLocalizations.
enum CardEffectKey {
  gameOver,
  foodGained,
  trashSecured,
  raccoonBlocked,
  raccoonDevours,
  banquet,
  babyRaccoonDevours,
  babyRaccoonEmpty,
  vacuumSteals,
  vacuumEmpty,
  pinceNoTarget,
  pinceSteal,
  none,
}

class CardEffectMessage {
  final CardEffectKey key;
  // Paramètres optionnels utilisés pour interpolation côté UI
  final String? playerName;
  final String? targetName;
  final int? count;

  const CardEffectMessage({
    required this.key,
    this.playerName,
    this.targetName,
    this.count,
  });
}
