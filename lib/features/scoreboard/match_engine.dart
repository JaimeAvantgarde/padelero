import '../../models/match_config.dart';
import '../../models/set_score.dart';
import '../../models/game_score.dart';

/// Acción reversible para undo.
class _ScoredAction {
  const _ScoredAction({
    required this.team,
    required this.snapshot,
  });
  final int team; // 1 o 2
  final MatchEngineSnapshot snapshot;
}

/// Snapshot del estado del motor (para undo y serialización).
class MatchEngineSnapshot {
  const MatchEngineSnapshot({
    required this.setScores,
    required this.currentSetTeam1Games,
    required this.currentSetTeam2Games,
    required this.team1Points,
    required this.team2Points,
    required this.servingTeam,
    required this.isTieBreak,
    required this.tieBreakTeam1Points,
    required this.tieBreakTeam2Points,
    required this.tieBreakPointsPlayed,
  });

  final List<SetScore> setScores;
  final int currentSetTeam1Games;
  final int currentSetTeam2Games;
  final int team1Points;
  final int team2Points;
  final int servingTeam;
  final bool isTieBreak;
  final int tieBreakTeam1Points;
  final int tieBreakTeam2Points;
  final int tieBreakPointsPlayed;

  Map<String, dynamic> toJson() => {
        'setScores': setScores.map((s) => {'team1': s.team1Games, 'team2': s.team2Games}).toList(),
        'currentSetTeam1Games': currentSetTeam1Games,
        'currentSetTeam2Games': currentSetTeam2Games,
        'team1Points': team1Points,
        'team2Points': team2Points,
        'servingTeam': servingTeam,
        'isTieBreak': isTieBreak,
        'tieBreakTeam1Points': tieBreakTeam1Points,
        'tieBreakTeam2Points': tieBreakTeam2Points,
        'tieBreakPointsPlayed': tieBreakPointsPlayed,
      };
}

/// Motor de partido puro (solo Dart). Toda la lógica de puntuación de pádel.
class MatchEngine {
  MatchEngine({
    required this.config,
    this.team1Name = 'Equipo 1',
    this.team2Name = 'Equipo 2',
  })  : _servingTeam = config.firstServer,
        _setScores = [],
        _currentSetTeam1Games = 0,
        _currentSetTeam2Games = 0,
        _team1Points = 0,
        _team2Points = 0,
        _isTieBreak = false,
        _tieBreakTeam1Points = 0,
        _tieBreakTeam2Points = 0,
        _tieBreakPointsPlayed = 0 {
    _history.add(_ScoredAction(team: 0, snapshot: _takeSnapshot()));
  }

  final MatchConfig config;
  final String team1Name;
  final String team2Name;

  final List<_ScoredAction> _history = [];

  int _servingTeam;
  final List<SetScore> _setScores;
  int _currentSetTeam1Games;
  int _currentSetTeam2Games;
  int _team1Points;
  int _team2Points;
  bool _isTieBreak;
  int _tieBreakTeam1Points;
  int _tieBreakTeam2Points;
  int _tieBreakPointsPlayed;

  int get servingTeam => _servingTeam;
  List<SetScore> get setScores => List.unmodifiable(_setScores);
  int get currentSetTeam1Games => _currentSetTeam1Games;
  int get currentSetTeam2Games => _currentSetTeam2Games;
  GameScore get gameScore => GameScore(team1Points: _team1Points, team2Points: _team2Points);
  bool get isTieBreak => _isTieBreak;
  int get tieBreakTeam1Points => _tieBreakTeam1Points;
  int get tieBreakTeam2Points => _tieBreakTeam2Points;

  MatchEngineSnapshot _takeSnapshot() => MatchEngineSnapshot(
        setScores: List.from(_setScores.map((s) => SetScore(team1Games: s.team1Games, team2Games: s.team2Games))),
        currentSetTeam1Games: _currentSetTeam1Games,
        currentSetTeam2Games: _currentSetTeam2Games,
        team1Points: _team1Points,
        team2Points: _team2Points,
        servingTeam: _servingTeam,
        isTieBreak: _isTieBreak,
        tieBreakTeam1Points: _tieBreakTeam1Points,
        tieBreakTeam2Points: _tieBreakTeam2Points,
        tieBreakPointsPlayed: _tieBreakPointsPlayed,
      );

  void _restoreSnapshot(MatchEngineSnapshot s) {
    _setScores.clear();
    _setScores.addAll(s.setScores);
    _currentSetTeam1Games = s.currentSetTeam1Games;
    _currentSetTeam2Games = s.currentSetTeam2Games;
    _team1Points = s.team1Points;
    _team2Points = s.team2Points;
    _servingTeam = s.servingTeam;
    _isTieBreak = s.isTieBreak;
    _tieBreakTeam1Points = s.tieBreakTeam1Points;
    _tieBreakTeam2Points = s.tieBreakTeam2Points;
    _tieBreakPointsPlayed = s.tieBreakPointsPlayed;
  }

  /// Marca un punto para [team] (1 o 2). Lanza si el partido ya terminó.
  void scorePoint(int team) {
    if (isMatchOver()) {
      throw StateError('Match is over');
    }
    final snapshotBefore = _takeSnapshot();
    if (_isTieBreak) {
      _scoreTieBreakPoint(team);
    } else {
      _scoreGamePoint(team);
    }
    _history.add(_ScoredAction(team: team, snapshot: snapshotBefore));
  }

  void _scoreGamePoint(int team) {
    if (team == 1) {
      _team1Points++;
    } else {
      _team2Points++;
    }

    final gameWon = _checkGameWon();
    if (gameWon != null) {
      if (gameWon == 1) {
        _currentSetTeam1Games++;
      } else {
        _currentSetTeam2Games++;
      }
      _team1Points = 0;
      _team2Points = 0;
      _servingTeam = _servingTeam == 1 ? 2 : 1; // alterna cada juego

      final setWon = _checkSetWon();
      if (setWon != null) {
        _setScores.add(SetScore(team1Games: _currentSetTeam1Games, team2Games: _currentSetTeam2Games));
        _currentSetTeam1Games = 0;
        _currentSetTeam2Games = 0;
        if (!isMatchOver()) {
          _startNextSet();
        }
      } else if (_shouldStartTieBreak()) {
        _isTieBreak = true;
        _tieBreakTeam1Points = 0;
        _tieBreakTeam2Points = 0;
        _tieBreakPointsPlayed = 0;
        // En tie-break: quien sacaba ahora saca el primer punto del tie-break
      }
    }
  }

  /// Devuelve 1 si gana equipo 1, 2 si gana equipo 2, null si el juego sigue.
  int? _checkGameWon() {
    final p1 = _team1Points;
    final p2 = _team2Points;
    if (config.deuceType == DeuceType.goldenPoint) {
      if (p1 >= 4 && p1 > p2) return 1;
      if (p2 >= 4 && p2 > p1) return 2;
      return null;
    }
    // Ventajas: 2 puntos de diferencia, mínimo 4
    if (p1 >= 4 && p1 - p2 >= 2) return 1;
    if (p2 >= 4 && p2 - p1 >= 2) return 2;
    return null;
  }

  bool _shouldStartTieBreak() {
    if (_currentSetTeam1Games != 6 || _currentSetTeam2Games != 6) return false;
    final isLastSet = _setScores.length + 1 >= config.numberOfSets;
    if (isLastSet && config.lastSetTieBreak == TieBreakType.superTieBreak) {
      return true; // super tie-break
    }
    return true; // tie-break normal
  }

  void _scoreTieBreakPoint(int team) {
    if (team == 1) {
      _tieBreakTeam1Points++;
    } else {
      _tieBreakTeam2Points++;
    }
    _tieBreakPointsPlayed++;

    final target = _getTieBreakTarget();
    final t1 = _tieBreakTeam1Points;
    final t2 = _tieBreakTeam2Points;
    final won = (t1 >= target || t2 >= target) && (t1 - t2).abs() >= 2;

    if (won) {
      if (t1 > t2) {
        _currentSetTeam1Games++;
      } else {
        _currentSetTeam2Games++;
      }
      _setScores.add(SetScore(team1Games: _currentSetTeam1Games, team2Games: _currentSetTeam2Games));
      _currentSetTeam1Games = 0;
      _currentSetTeam2Games = 0;
      _isTieBreak = false;
      _tieBreakTeam1Points = 0;
      _tieBreakTeam2Points = 0;
      _tieBreakPointsPlayed = 0;
      if (!isMatchOver()) {
        _servingTeam = _servingTeam == 1 ? 2 : 1;
        _startNextSet();
      }
    } else {
      // En tie-break: primer punto lo saca quien tocaba; luego cada 2 puntos cambia
      if (_tieBreakPointsPlayed >= 2 && (_tieBreakPointsPlayed % 2 == 0)) {
        _servingTeam = _servingTeam == 1 ? 2 : 1;
      }
    }
  }

  int _getTieBreakTarget() {
    final isLastSet = _setScores.length + 1 >= config.numberOfSets;
    if (isLastSet && config.lastSetTieBreak == TieBreakType.superTieBreak) {
      return 10;
    }
    return 7;
  }

  int? _checkSetWon() {
    if (_isTieBreak) {
      final target = _getTieBreakTarget();
      if (_tieBreakTeam1Points >= target && _tieBreakTeam1Points - _tieBreakTeam2Points >= 2) return 1;
      if (_tieBreakTeam2Points >= target && _tieBreakTeam2Points - _tieBreakTeam1Points >= 2) return 2;
      return null;
    }
    if (_currentSetTeam1Games >= 6 && _currentSetTeam1Games - _currentSetTeam2Games >= 2) return 1;
    if (_currentSetTeam2Games >= 6 && _currentSetTeam2Games - _currentSetTeam1Games >= 2) return 2;
    return null;
  }

  void _startNextSet() {
    _servingTeam = _servingTeam == 1 ? 2 : 1; // el que no sacó el último juego del set anterior
  }

  bool isGameOver() {
    return _checkGameWon() != null;
  }

  bool isSetOver() {
    if (_isTieBreak) return _checkSetWon() != null;
    if (_currentSetTeam1Games >= 6 && _currentSetTeam1Games - _currentSetTeam2Games >= 2) return true;
    if (_currentSetTeam2Games >= 6 && _currentSetTeam2Games - _currentSetTeam1Games >= 2) return true;
    return false;
  }

  bool isMatchOver() {
    final sets1 = _setScores.fold<int>(0, (s, set) => s + (set.team1Games > set.team2Games ? 1 : 0));
    final sets2 = _setScores.fold<int>(0, (s, set) => s + (set.team2Games > set.team1Games ? 1 : 0));
    final needed = (config.numberOfSets / 2).ceil();
    return sets1 >= needed || sets2 >= needed;
  }

  /// Cambio de lado: cuando la suma de juegos del set es impar (1-0, 2-1, 3-2...).
  /// En tie-break: cada 6 puntos.
  bool shouldChangeSides() {
    if (_isTieBreak) {
      final total = _tieBreakTeam1Points + _tieBreakTeam2Points;
      if (total > 0 && total % 6 == 0) return true;
      return false;
    }
    final total = _currentSetTeam1Games + _currentSetTeam2Games;
    return total > 0 && total % 2 == 1;
  }

  /// Último punto fue en cambio de lado (para mostrar overlay justo después del punto).
  bool get justChangedSides {
    if (_isTieBreak) {
      final total = _tieBreakTeam1Points + _tieBreakTeam2Points;
      return total > 0 && total % 6 == 0;
    }
    final total = _currentSetTeam1Games + _currentSetTeam2Games;
    return total > 0 && total % 2 == 1;
  }

  bool canUndo() => _history.length > 1;

  void undoLastPoint() {
    if (!canUndo()) return;
    final removed = _history.removeLast();
    _restoreSnapshot(removed.snapshot);
  }

  /// 1 = equipo 1, 2 = equipo 2, null = no terminado.
  int? getMatchWinner() {
    if (!isMatchOver()) return null;
    final sets1 = _setScores.fold<int>(0, (s, set) => s + (set.team1Games > set.team2Games ? 1 : 0));
    final sets2 = _setScores.fold<int>(0, (s, set) => s + (set.team2Games > set.team1Games ? 1 : 0));
    return sets1 > sets2 ? 1 : 2;
  }

  Map<String, dynamic> getMatchResult() {
    return {
      'winner': getMatchWinner(),
      'setScores': _setScores.map((s) => {'team1': s.team1Games, 'team2': s.team2Games}).toList(),
      'config': config.toJson(),
      'snapshot': _takeSnapshot().toJson(),
    };
  }

  /// Set point para el equipo que está a un juego de ganar el set.
  bool isSetPointFor(int team) {
    if (isMatchOver()) return false;
    if (_isTieBreak) {
      final target = _getTieBreakTarget();
      final t1 = _tieBreakTeam1Points;
      final t2 = _tieBreakTeam2Points;
      if (team == 1) return t1 >= target - 1 && t1 > t2;
      return t2 >= target - 1 && t2 > t1;
    }
    if (team == 1) return _currentSetTeam1Games == 5 && _currentSetTeam2Games <= 4;
    return _currentSetTeam2Games == 5 && _currentSetTeam1Games <= 4;
  }

  /// Match point: el siguiente punto gana el partido.
  bool isMatchPointFor(int team) {
    if (isMatchOver()) return false;
    final sets1 = _setScores.fold<int>(0, (s, set) => s + (set.team1Games > set.team2Games ? 1 : 0));
    final sets2 = _setScores.fold<int>(0, (s, set) => s + (set.team2Games > set.team1Games ? 1 : 0));
    final needed = (config.numberOfSets / 2).ceil();
    if (team == 1 && sets1 == needed - 1) {
      if (_isTieBreak) {
        final target = _getTieBreakTarget();
        return _tieBreakTeam1Points >= target - 1 && _tieBreakTeam1Points > _tieBreakTeam2Points;
      }
      return _currentSetTeam1Games == 5 && _currentSetTeam2Games <= 4;
    }
    if (team == 2 && sets2 == needed - 1) {
      if (_isTieBreak) {
        final target = _getTieBreakTarget();
        return _tieBreakTeam2Points >= target - 1 && _tieBreakTeam2Points > _tieBreakTeam1Points;
      }
      return _currentSetTeam2Games == 5 && _currentSetTeam1Games <= 4;
    }
    return false;
  }
}
