/// Puntos dentro de un juego: 0, 15, 30, 40, AD (ventaja).
class GameScore {
  const GameScore({this.team1Points = 0, this.team2Points = 0});

  final int team1Points;
  final int team2Points;

  static const List<int> _pointValues = [0, 15, 30, 40];

  /// Devuelve el display del punto (0, 15, 30, 40, o "AD").
  String pointDisplay(bool forTeam1) {
    final p = forTeam1 ? team1Points : team2Points;
    final other = forTeam1 ? team2Points : team1Points;
    if (p > 3 || (p == 3 && other == 3)) {
      if (p == other) return '40';
      if (p > other) return 'AD';
      return '40';
    }
    return '${_pointValues[p]}';
  }

  bool get isDeuce =>
      team1Points >= 3 && team2Points >= 3 && team1Points == team2Points;
  bool get hasAdvantage =>
      (team1Points >= 4 || team2Points >= 4) &&
      (team1Points - team2Points).abs() == 1;

  GameScore copyWith({int? team1Points, int? team2Points}) => GameScore(
        team1Points: team1Points ?? this.team1Points,
        team2Points: team2Points ?? this.team2Points,
      );
}
