import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/match_config.dart';
import 'match_engine.dart';

/// Datos del partido para iniciar el marcador (vienen del setup).
class MatchSetupData {
  const MatchSetupData({
    required this.team1Name,
    required this.team2Name,
    required this.config,
  });
  final String team1Name;
  final String team2Name;
  final MatchConfig config;
}

/// Provider que guarda el setup actual antes de ir al marcador.
final matchSetupDataProvider = StateProvider<MatchSetupData?>((ref) => null);

/// Estado del marcador: motor + tiempo de inicio.
class ScoreboardState {
  const ScoreboardState({
    required this.engine,
    required this.startedAt,
    this.overlayMessage,
  });
  final MatchEngine engine;
  final DateTime startedAt;
  final String? overlayMessage;
}

class ScoreboardNotifier extends StateNotifier<ScoreboardState?> {
  ScoreboardNotifier(this._setup) : super(null) {
    if (_setup != null) {
      state = ScoreboardState(
        engine: MatchEngine(
          config: _setup.config,
          team1Name: _setup.team1Name,
          team2Name: _setup.team2Name,
        ),
        startedAt: DateTime.now(),
      );
    }
  }

  final MatchSetupData? _setup;

  void scorePoint(int team) {
    final s = state;
    if (s == null || s.engine.isMatchOver()) return;
    s.engine.scorePoint(team);
    String? overlay;
    if (s.engine.shouldChangeSides()) {
      overlay = 'CAMBIO DE LADO';
    } else if (s.engine.isMatchPointFor(team)) {
      overlay = 'MATCH POINT';
    } else if (s.engine.isSetPointFor(team)) {
      overlay = 'SET POINT';
    }
    state = ScoreboardState(
      engine: s.engine,
      startedAt: s.startedAt,
      overlayMessage: overlay,
    );
  }

  void clearOverlay() {
    final s = state;
    if (s == null) return;
    state = ScoreboardState(engine: s.engine, startedAt: s.startedAt);
  }

  void undo() {
    final s = state;
    if (s == null || !s.engine.canUndo()) return;
    s.engine.undoLastPoint();
    state = ScoreboardState(engine: s.engine, startedAt: s.startedAt);
  }
}

final scoreboardProvider = StateNotifierProvider<ScoreboardNotifier, ScoreboardState?>((ref) {
  final setup = ref.watch(matchSetupDataProvider);
  return ScoreboardNotifier(setup);
});
