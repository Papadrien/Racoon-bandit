/// Représente une récompense débloquée à afficher au joueur.
///
/// MVP : uniquement [RewardType.cardBack].
/// Extensible pour de futurs types (avatar, fond, badge…).
enum RewardType { cardBack }

class RewardUnlock {
  const RewardUnlock({
    required this.id,
    required this.name,
    required this.type,
    this.assetPath,
  });

  final String id;
  final String name;
  final RewardType type;

  /// Chemin vers l'asset à prévisualiser (peut être null si pas d'image dédiée).
  final String? assetPath;
}
