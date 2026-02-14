/// Resultado de un set: juegos ganados por cada equipo.
class SetScore {
  const SetScore({this.team1Games = 0, this.team2Games = 0});

  final int team1Games;
  final int team2Games;

  SetScore copyWith({int? team1Games, int? team2Games}) => SetScore(
        team1Games: team1Games ?? this.team1Games,
        team2Games: team2Games ?? this.team2Games,
      );

  @override
  String toString() => '$team1Games-$team2Games';
}
