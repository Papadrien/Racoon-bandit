import '../models/player_model.dart';

class GameState {
  final List<PlayerModel> players;
  final int roundsPerPlayer;
  int currentPlayerIndex;
  int currentTurn;

  GameState({
    required this.players,
    this.roundsPerPlayer = 3,
    this.currentPlayerIndex = 0,
    this.currentTurn = 1,
  });

  int get totalTurns => players.length * roundsPerPlayer;
  int get currentRound => ((currentTurn - 1) ~/ players.length) + 1;
  bool get isGameOver => currentTurn > totalTurns;

  PlayerModel get currentPlayer => players[currentPlayerIndex];

  List<PlayerModel> get ranking {
    final sorted = List<PlayerModel>.from(players);
    sorted.sort((a, b) => b.score.compareTo(a.score));
    return sorted;
  }

  void correctAnswer() {
    players[currentPlayerIndex].score++;
    _advance();
  }

  void wrongAnswer() {
    _advance();
  }

  void _advance() {
    currentTurn++;
    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
  }
}
