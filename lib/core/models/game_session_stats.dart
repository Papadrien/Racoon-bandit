class GameSessionStats {
  int cardsPlayed;
  int foodGained;
  int foodStolen;
  int banditCardsPlayed;
  int raccoonCardsPlayed;

  GameSessionStats({
    this.cardsPlayed = 0,
    this.foodGained = 0,
    this.foodStolen = 0,
    this.banditCardsPlayed = 0,
    this.raccoonCardsPlayed = 0,
  });
}
