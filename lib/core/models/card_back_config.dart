class CardBackConfig {
  const CardBackConfig({
    required this.id,
    required this.name,
    required this.requiredGames,
    required this.unlockedByDefault,
  });

  final String id;
  final String name;
  final int requiredGames;
  final bool unlockedByDefault;
}
