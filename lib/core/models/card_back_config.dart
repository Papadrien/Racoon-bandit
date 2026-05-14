class CardBackConfig {
  const CardBackConfig({
    required this.id,
    required this.name,
    required this.requiredGames,
    this.unlockedByDefault = false,
  });

  final String id;
  final String name;

  /// Nombre de parties jouées requis pour débloquer ce dos.
  /// 0 si [unlockedByDefault] est vrai.
  final int requiredGames;

  /// Vrai si ce dos est disponible sans condition dès le départ.
  final bool unlockedByDefault;
}
