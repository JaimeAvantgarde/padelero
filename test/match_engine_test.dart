import 'package:flutter_test/flutter_test.dart';
import 'package:padelero/features/scoreboard/match_engine.dart';
import 'package:padelero/models/match_config.dart';
import 'package:padelero/models/game_score.dart';
import 'package:padelero/models/set_score.dart';

/// Helper: marcar [count] puntos para [team].
void _scorePoints(MatchEngine engine, int team, int count) {
  for (int i = 0; i < count; i++) {
    engine.scorePoint(team);
  }
}

/// Helper: ganar un juego completo para [team] (4 puntos a 0 = 0-15-30-40-Game).
void _winGame(MatchEngine engine, int team) => _scorePoints(engine, team, 4);

/// Helper: ganar un set 6-0 para [team].
void _winSet60(MatchEngine engine, int team) {
  for (int g = 0; g < 6; g++) {
    _winGame(engine, team);
  }
}

/// Helper: llegar a 6-6 en el set actual.
void _reachTieBreak(MatchEngine engine) {
  for (int g = 0; g < 6; g++) {
    _winGame(engine, 1);
    _winGame(engine, 2);
  }
}

void main() {
  group('MatchEngine', () {
    // ─────────────────────────────────────────────
    // GAME SCORING
    // ─────────────────────────────────────────────
    group('Game scoring', () {
      test('starts at 0-0', () {
        final engine = MatchEngine(config: const MatchConfig(numberOfSets: 1));
        expect(engine.gameScore.team1Points, 0);
        expect(engine.gameScore.team2Points, 0);
        expect(engine.gameScore.pointDisplay(true), '0');
        expect(engine.gameScore.pointDisplay(false), '0');
      });

      test('progression: 0 → 15 → 30 → 40 → game', () {
        final engine = MatchEngine(
          config: const MatchConfig(numberOfSets: 1, deuceType: DeuceType.goldenPoint),
        );
        engine.scorePoint(1);
        expect(engine.gameScore.pointDisplay(true), '15');
        engine.scorePoint(1);
        expect(engine.gameScore.pointDisplay(true), '30');
        engine.scorePoint(1);
        expect(engine.gameScore.pointDisplay(true), '40');
        engine.scorePoint(1);
        // Game won → points reset, games increase
        expect(engine.currentSetTeam1Games, 1);
        expect(engine.gameScore.team1Points, 0);
        expect(engine.gameScore.team2Points, 0);
      });

      test('golden point: 40-40, next point wins', () {
        final engine = MatchEngine(
          config: const MatchConfig(numberOfSets: 1, deuceType: DeuceType.goldenPoint),
        );
        _scorePoints(engine, 1, 3); // 40-0
        _scorePoints(engine, 2, 3); // 40-40
        expect(engine.gameScore.pointDisplay(true), '40');
        expect(engine.gameScore.pointDisplay(false), '40');
        engine.scorePoint(2); // team 2 wins the game
        expect(engine.currentSetTeam2Games, 1);
      });

      test('advantages: deuce → AD → deuce → AD → game', () {
        final engine = MatchEngine(
          config: const MatchConfig(numberOfSets: 1, deuceType: DeuceType.advantages),
        );
        // Reach 40-40
        for (int i = 0; i < 3; i++) {
          engine.scorePoint(1);
          engine.scorePoint(2);
        }
        expect(engine.gameScore.isDeuce, true);

        // Team 1 advantage
        engine.scorePoint(1);
        expect(engine.gameScore.pointDisplay(true), 'AD');
        expect(engine.gameScore.pointDisplay(false), '40');

        // Back to deuce
        engine.scorePoint(2);
        expect(engine.gameScore.pointDisplay(true), '40');
        expect(engine.gameScore.pointDisplay(false), '40');
        expect(engine.gameScore.isDeuce, true);

        // Team 1 wins with 2 consecutive
        engine.scorePoint(1); // AD
        engine.scorePoint(1); // Game
        expect(engine.currentSetTeam1Games, 1);
      });

      test('team 2 can also win games', () {
        final engine = MatchEngine(config: const MatchConfig(numberOfSets: 1));
        _winGame(engine, 2);
        expect(engine.currentSetTeam2Games, 1);
        expect(engine.currentSetTeam1Games, 0);
      });
    });

    // ─────────────────────────────────────────────
    // SERVE ROTATION
    // ─────────────────────────────────────────────
    group('Serve', () {
      test('first server from config', () {
        final e1 = MatchEngine(config: const MatchConfig(firstServer: 1));
        expect(e1.servingTeam, 1);
        final e2 = MatchEngine(config: const MatchConfig(firstServer: 2));
        expect(e2.servingTeam, 2);
      });

      test('serve alternates after each game', () {
        final engine = MatchEngine(config: const MatchConfig(numberOfSets: 1));
        expect(engine.servingTeam, 1);
        _winGame(engine, 1); // 1-0
        expect(engine.servingTeam, 2);
        _winGame(engine, 2); // 1-1
        expect(engine.servingTeam, 1);
        _winGame(engine, 1); // 2-1
        expect(engine.servingTeam, 2);
      });

      test('serve alternates every 2 points in tie-break', () {
        final engine = MatchEngine(config: const MatchConfig(numberOfSets: 1));
        _reachTieBreak(engine); // 6-6
        expect(engine.isTieBreak, true);

        final firstServer = engine.servingTeam;
        // First point: same server
        engine.scorePoint(1);
        // After 2 points: switch
        engine.scorePoint(2);
        expect(engine.servingTeam, firstServer == 1 ? 2 : 1);
        // After 4 points: switch again
        engine.scorePoint(1);
        engine.scorePoint(2);
        expect(engine.servingTeam, firstServer);
      });
    });

    // ─────────────────────────────────────────────
    // SET COMPLETION
    // ─────────────────────────────────────────────
    group('Set completion', () {
      test('set won at 6-0', () {
        final engine = MatchEngine(config: const MatchConfig(numberOfSets: 1));
        _winSet60(engine, 1);
        expect(engine.setScores.length, 1);
        expect(engine.setScores[0].team1Games, 6);
        expect(engine.setScores[0].team2Games, 0);
        expect(engine.isMatchOver(), true);
      });

      test('set won at 6-4', () {
        final engine = MatchEngine(config: const MatchConfig(numberOfSets: 1));
        // 1 wins 6, 2 wins 4 (alternating: 1,2,1,2,1,2,1,2,1,1)
        for (int i = 0; i < 4; i++) {
          _winGame(engine, 1);
          _winGame(engine, 2);
        }
        // Now 4-4
        _winGame(engine, 1); // 5-4
        _winGame(engine, 1); // 6-4 → set won
        expect(engine.setScores.length, 1);
        expect(engine.setScores[0].team1Games, 6);
        expect(engine.setScores[0].team2Games, 4);
      });

      test('no set at 5-5, must reach 6-4 or 7-5 or tie-break', () {
        final engine = MatchEngine(config: const MatchConfig(numberOfSets: 1));
        for (int i = 0; i < 5; i++) {
          _winGame(engine, 1);
          _winGame(engine, 2);
        }
        // 5-5
        expect(engine.setScores.length, 0);
        _winGame(engine, 1); // 6-5
        expect(engine.setScores.length, 0);
        _winGame(engine, 1); // 7-5 → set won
        expect(engine.setScores.length, 1);
        expect(engine.setScores[0].team1Games, 7);
        expect(engine.setScores[0].team2Games, 5);
      });
    });

    // ─────────────────────────────────────────────
    // TIE-BREAK
    // ─────────────────────────────────────────────
    group('Tie-break', () {
      test('tie-break starts at 6-6', () {
        final engine = MatchEngine(config: const MatchConfig(numberOfSets: 1));
        _reachTieBreak(engine);
        expect(engine.isTieBreak, true);
        expect(engine.currentSetTeam1Games, 6);
        expect(engine.currentSetTeam2Games, 6);
      });

      test('normal tie-break won at 7-0', () {
        final engine = MatchEngine(config: const MatchConfig(numberOfSets: 1));
        _reachTieBreak(engine);
        _scorePoints(engine, 1, 7);
        expect(engine.isTieBreak, false);
        expect(engine.setScores.length, 1);
        expect(engine.setScores[0].team1Games, 7);
        expect(engine.setScores[0].team2Games, 6);
      });

      test('tie-break requires 2-point difference', () {
        final engine = MatchEngine(config: const MatchConfig(numberOfSets: 1));
        _reachTieBreak(engine);
        // Reach 6-6 in tie-break
        for (int i = 0; i < 6; i++) {
          engine.scorePoint(1);
          engine.scorePoint(2);
        }
        expect(engine.tieBreakTeam1Points, 6);
        expect(engine.tieBreakTeam2Points, 6);
        expect(engine.setScores.length, 0); // Still playing

        // 7-6 → not enough
        engine.scorePoint(1);
        expect(engine.setScores.length, 0);

        // 8-6 → win
        engine.scorePoint(1);
        expect(engine.setScores.length, 1);
        expect(engine.setScores[0].team1Games, 7);
      });

      test('super tie-break: first to 10 (last set)', () {
        final engine = MatchEngine(
          config: const MatchConfig(
            numberOfSets: 3,
            lastSetTieBreak: TieBreakType.superTieBreak,
          ),
        );
        // Team 1 wins first set 6-0
        _winSet60(engine, 1);
        expect(engine.setScores.length, 1);

        // Team 2 wins second set 6-0
        _winSet60(engine, 2);
        expect(engine.setScores.length, 2);

        // Third set: reach 6-6 for super tie-break
        _reachTieBreak(engine);
        expect(engine.isTieBreak, true);

        // Score 10 points for team 1 → wins super tie-break
        _scorePoints(engine, 1, 10);
        expect(engine.setScores.length, 3);
        expect(engine.setScores[2].team1Games, 7);
        expect(engine.setScores[2].team2Games, 6);
        expect(engine.isMatchOver(), true);
        expect(engine.getMatchWinner(), 1);
      });

      test('super tie-break also requires 2-point diff', () {
        final engine = MatchEngine(
          config: const MatchConfig(
            numberOfSets: 3,
            lastSetTieBreak: TieBreakType.superTieBreak,
          ),
        );
        _winSet60(engine, 1);
        _winSet60(engine, 2);
        _reachTieBreak(engine);

        // Reach 9-9 in super tie-break
        for (int i = 0; i < 9; i++) {
          engine.scorePoint(1);
          engine.scorePoint(2);
        }
        expect(engine.tieBreakTeam1Points, 9);
        expect(engine.tieBreakTeam2Points, 9);

        // 10-9 → not enough
        engine.scorePoint(1);
        expect(engine.setScores.length, 2);

        // 10-10 → back
        engine.scorePoint(2);
        expect(engine.setScores.length, 2);

        // 11-10 → not enough
        engine.scorePoint(1);
        expect(engine.setScores.length, 2);

        // 12-10 → nope, 11-10 was the score, now 12-10 but let's check
        engine.scorePoint(1);
        expect(engine.setScores.length, 3);
        expect(engine.isMatchOver(), true);
      });
    });

    // ─────────────────────────────────────────────
    // MATCH COMPLETION
    // ─────────────────────────────────────────────
    group('Match completion', () {
      test('1-set match: win 1 set = match over', () {
        final engine = MatchEngine(config: const MatchConfig(numberOfSets: 1));
        _winSet60(engine, 1);
        expect(engine.isMatchOver(), true);
        expect(engine.getMatchWinner(), 1);
      });

      test('best of 3: need 2 sets to win', () {
        final engine = MatchEngine(config: const MatchConfig(numberOfSets: 3));
        _winSet60(engine, 1);
        expect(engine.isMatchOver(), false);
        _winSet60(engine, 1);
        expect(engine.isMatchOver(), true);
        expect(engine.getMatchWinner(), 1);
      });

      test('best of 3: team 2 wins 2-1', () {
        final engine = MatchEngine(config: const MatchConfig(numberOfSets: 3));
        _winSet60(engine, 1); // Set 1: team 1
        _winSet60(engine, 2); // Set 2: team 2
        _winSet60(engine, 2); // Set 3: team 2
        expect(engine.isMatchOver(), true);
        expect(engine.getMatchWinner(), 2);
        expect(engine.setScores.length, 3);
      });

      test('cannot score after match is over', () {
        final engine = MatchEngine(config: const MatchConfig(numberOfSets: 1));
        _winSet60(engine, 1);
        expect(() => engine.scorePoint(1), throwsStateError);
      });

      test('getMatchResult returns correct structure', () {
        final engine = MatchEngine(config: const MatchConfig(numberOfSets: 1));
        _winSet60(engine, 2);
        final result = engine.getMatchResult();
        expect(result['winner'], 2);
        expect((result['setScores'] as List).length, 1);
        expect(result['config'], isA<Map>());
        expect(result['snapshot'], isA<Map>());
      });
    });

    // ─────────────────────────────────────────────
    // CHANGE OF SIDES
    // ─────────────────────────────────────────────
    group('Change of sides', () {
      test('change when total games is odd', () {
        final engine = MatchEngine(config: const MatchConfig(numberOfSets: 1));
        expect(engine.shouldChangeSides(), false); // 0-0
        _winGame(engine, 1); // 1-0 → change
        expect(engine.shouldChangeSides(), true);
        _winGame(engine, 2); // 1-1 → no change
        expect(engine.shouldChangeSides(), false);
        _winGame(engine, 1); // 2-1 → change
        expect(engine.shouldChangeSides(), true);
      });

      test('change every 6 points in tie-break', () {
        final engine = MatchEngine(config: const MatchConfig(numberOfSets: 1));
        _reachTieBreak(engine);
        expect(engine.shouldChangeSides(), false);
        _scorePoints(engine, 1, 3);
        _scorePoints(engine, 2, 3);
        // 3-3 in tie-break = 6 points total → change
        expect(engine.shouldChangeSides(), true);
      });
    });

    // ─────────────────────────────────────────────
    // SET POINT / MATCH POINT DETECTION
    // ─────────────────────────────────────────────
    group('Set point / Match point', () {
      test('set point at 5-4 for leading team', () {
        final engine = MatchEngine(config: const MatchConfig(numberOfSets: 3));
        for (int i = 0; i < 5; i++) { _winGame(engine, 1); }
        for (int i = 0; i < 4; i++) { _winGame(engine, 2); }
        // 5-4: team 1 has set point
        expect(engine.isSetPointFor(1), true);
        expect(engine.isSetPointFor(2), false);
      });

      test('no set point at 5-5', () {
        final engine = MatchEngine(config: const MatchConfig(numberOfSets: 1));
        for (int i = 0; i < 5; i++) {
          _winGame(engine, 1);
          _winGame(engine, 2);
        }
        expect(engine.isSetPointFor(1), false);
        expect(engine.isSetPointFor(2), false);
      });

      test('match point when one set away from winning', () {
        final engine = MatchEngine(config: const MatchConfig(numberOfSets: 3));
        _winSet60(engine, 1); // Won 1 set, need 2
        // At 5-0 in second set → match point
        for (int i = 0; i < 5; i++) { _winGame(engine, 1); }
        expect(engine.isMatchPointFor(1), true);
        expect(engine.isMatchPointFor(2), false);
      });
    });

    // ─────────────────────────────────────────────
    // UNDO
    // ─────────────────────────────────────────────
    group('Undo', () {
      test('undo restores previous point', () {
        final engine = MatchEngine(config: const MatchConfig(numberOfSets: 1));
        engine.scorePoint(1);
        engine.scorePoint(1);
        expect(engine.gameScore.team1Points, 2);
        engine.undoLastPoint();
        expect(engine.gameScore.team1Points, 1);
        engine.undoLastPoint();
        expect(engine.gameScore.team1Points, 0);
        expect(engine.canUndo(), false);
      });

      test('undo after winning a game restores the game', () {
        final engine = MatchEngine(config: const MatchConfig(numberOfSets: 1));
        _winGame(engine, 1);
        expect(engine.currentSetTeam1Games, 1);
        expect(engine.gameScore.team1Points, 0);
        engine.undoLastPoint();
        expect(engine.currentSetTeam1Games, 0);
        expect(engine.gameScore.team1Points, 3);
      });

      test('undo after winning a set restores the set', () {
        final engine = MatchEngine(config: const MatchConfig(numberOfSets: 3));
        _winSet60(engine, 1);
        expect(engine.setScores.length, 1);
        engine.undoLastPoint();
        expect(engine.setScores.length, 0);
        expect(engine.currentSetTeam1Games, 5);
        expect(engine.gameScore.team1Points, 3);
      });

      test('cannot undo at start', () {
        final engine = MatchEngine(config: const MatchConfig(numberOfSets: 1));
        expect(engine.canUndo(), false);
        engine.undoLastPoint(); // Should do nothing
        expect(engine.gameScore.team1Points, 0);
      });

      test('multiple undos in sequence', () {
        final engine = MatchEngine(config: const MatchConfig(numberOfSets: 1));
        engine.scorePoint(1); // 15-0
        engine.scorePoint(2); // 15-15
        engine.scorePoint(1); // 30-15
        engine.undoLastPoint(); // back to 15-15
        expect(engine.gameScore.team1Points, 1);
        expect(engine.gameScore.team2Points, 1);
        engine.undoLastPoint(); // back to 15-0
        expect(engine.gameScore.team1Points, 1);
        expect(engine.gameScore.team2Points, 0);
      });
    });

    // ─────────────────────────────────────────────
    // TEAM NAMES
    // ─────────────────────────────────────────────
    group('Team names', () {
      test('default team names', () {
        final engine = MatchEngine(config: const MatchConfig());
        expect(engine.team1Name, 'Equipo 1');
        expect(engine.team2Name, 'Equipo 2');
      });

      test('custom team names', () {
        final engine = MatchEngine(
          config: const MatchConfig(),
          team1Name: 'Los Cracks',
          team2Name: 'Los Pros',
        );
        expect(engine.team1Name, 'Los Cracks');
        expect(engine.team2Name, 'Los Pros');
      });
    });

    // ─────────────────────────────────────────────
    // SNAPSHOT & SERIALIZATION
    // ─────────────────────────────────────────────
    group('Snapshot / Serialization', () {
      test('getMatchResult contains all data', () {
        final engine = MatchEngine(
          config: const MatchConfig(numberOfSets: 3),
          team1Name: 'A',
          team2Name: 'B',
        );
        _winSet60(engine, 1);
        _winSet60(engine, 1);
        final result = engine.getMatchResult();
        expect(result['winner'], 1);
        expect((result['setScores'] as List).length, 2);
        final config = result['config'] as Map<String, dynamic>;
        expect(config['numberOfSets'], 3);
        final snapshot = result['snapshot'] as Map<String, dynamic>;
        expect(snapshot.containsKey('servingTeam'), true);
      });
    });
  });

  // ─────────────────────────────────────────────
  // GAMECORE DISPLAY
  // ─────────────────────────────────────────────
  group('GameScore', () {
    test('display values: 0, 15, 30, 40', () {
      expect(const GameScore(team1Points: 0).pointDisplay(true), '0');
      expect(const GameScore(team1Points: 1).pointDisplay(true), '15');
      expect(const GameScore(team1Points: 2).pointDisplay(true), '30');
      expect(const GameScore(team1Points: 3).pointDisplay(true), '40');
    });

    test('deuce at 3-3', () {
      const score = GameScore(team1Points: 3, team2Points: 3);
      expect(score.isDeuce, true);
      expect(score.pointDisplay(true), '40');
      expect(score.pointDisplay(false), '40');
    });

    test('advantage display', () {
      const score = GameScore(team1Points: 4, team2Points: 3);
      expect(score.pointDisplay(true), 'AD');
      expect(score.pointDisplay(false), '40');
      expect(score.hasAdvantage, true);
    });

    test('deuce at higher scores (4-4, 5-5)', () {
      expect(const GameScore(team1Points: 4, team2Points: 4).isDeuce, true);
      expect(const GameScore(team1Points: 5, team2Points: 5).isDeuce, true);
    });
  });

  // ─────────────────────────────────────────────
  // MATCHCONFIG
  // ─────────────────────────────────────────────
  group('MatchConfig', () {
    test('default values', () {
      const config = MatchConfig();
      expect(config.numberOfSets, 3);
      expect(config.deuceType, DeuceType.advantages);
      expect(config.lastSetTieBreak, TieBreakType.normal);
      expect(config.firstServer, 1);
    });

    test('copyWith', () {
      const config = MatchConfig();
      final modified = config.copyWith(numberOfSets: 5, deuceType: DeuceType.goldenPoint);
      expect(modified.numberOfSets, 5);
      expect(modified.deuceType, DeuceType.goldenPoint);
      expect(modified.lastSetTieBreak, TieBreakType.normal); // unchanged
    });

    test('JSON round-trip', () {
      const original = MatchConfig(
        numberOfSets: 5,
        deuceType: DeuceType.goldenPoint,
        lastSetTieBreak: TieBreakType.superTieBreak,
        firstServer: 2,
      );
      final json = original.toJson();
      final restored = MatchConfig.fromJson(json);
      expect(restored.numberOfSets, original.numberOfSets);
      expect(restored.deuceType, original.deuceType);
      expect(restored.lastSetTieBreak, original.lastSetTieBreak);
      expect(restored.firstServer, original.firstServer);
    });

    test('fromJson with missing keys uses defaults', () {
      final config = MatchConfig.fromJson({});
      expect(config.numberOfSets, 3);
      expect(config.deuceType, DeuceType.advantages);
    });
  });

  // ─────────────────────────────────────────────
  // SETSCORE
  // ─────────────────────────────────────────────
  group('SetScore', () {
    test('toString', () {
      const score = SetScore(team1Games: 6, team2Games: 4);
      expect(score.toString(), '6-4');
    });

    test('copyWith', () {
      const score = SetScore(team1Games: 3, team2Games: 2);
      final modified = score.copyWith(team1Games: 4);
      expect(modified.team1Games, 4);
      expect(modified.team2Games, 2);
    });
  });
}
