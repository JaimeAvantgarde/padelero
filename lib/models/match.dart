import 'match_config.dart';

/// Modelo de partido guardado (historial).
class Match {
  const Match({
    required this.id,
    required this.team1Name,
    required this.team2Name,
    required this.config,
    required this.resultJson,
    required this.date,
    required this.durationSeconds,
    this.winner, // 1 o 2, null si no terminado
  });

  final int? id;
  final String team1Name;
  final String team2Name;
  final MatchConfig config;
  final Map<String, dynamic> resultJson;
  final DateTime date;
  final int durationSeconds;
  final int? winner;

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'team1Name': team1Name,
        'team2Name': team2Name,
        'config': config.toJson(),
        'resultJson': resultJson,
        'date': date.toIso8601String(),
        'durationSeconds': durationSeconds,
        'winner': winner,
      };

  factory Match.fromJson(Map<String, dynamic> json) => Match(
        id: json['id'] as int?,
        team1Name: json['team1Name'] as String,
        team2Name: json['team2Name'] as String,
        config: MatchConfig.fromJson(
          Map<String, dynamic>.from(json['config'] as Map),
        ),
        resultJson: Map<String, dynamic>.from(json['resultJson'] as Map),
        date: DateTime.parse(json['date'] as String),
        durationSeconds: json['durationSeconds'] as int,
        winner: json['winner'] as int?,
      );
}
