import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padelero/features/scoreboard/match_engine.dart';
import 'package:padelero/features/scoreboard/scoreboard_provider.dart';
import 'package:padelero/features/scoreboard/widgets/score_display.dart';
import 'package:padelero/features/scoreboard/widgets/set_indicator.dart';
import 'package:padelero/features/scoreboard/widgets/serve_indicator.dart';
import 'package:padelero/features/scoreboard/widgets/point_button.dart';
import 'package:padelero/shared/constants.dart';

class ScoreboardScreen extends ConsumerStatefulWidget {
  const ScoreboardScreen({super.key});

  @override
  ConsumerState<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends ConsumerState<ScoreboardScreen> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final state = ref.read(scoreboardProvider);
      if (state != null && !state.engine.isMatchOver()) {
        setState(() {
          _elapsed = DateTime.now().difference(state.startedAt);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scoreboardProvider);
    if (state == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No hay partido configurado'),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Volver al inicio'),
              ),
            ],
          ),
        ),
      );
    }

    final engine = state.engine;
    final overlay = state.overlayMessage;

    if (engine.isMatchOver()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(matchResultProvider.notifier).setResult(
              engine: engine,
              startedAt: state.startedAt,
              team1Name: engine.team1Name,
              team2Name: engine.team2Name,
            );
        if (mounted) context.go('/summary');
      });
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(state),
            const SizedBox(height: 8),
            SetIndicator(
              setScores: engine.setScores,
              currentSetTeam1Games: engine.currentSetTeam1Games,
              currentSetTeam2Games: engine.currentSetTeam2Games,
              totalSets: engine.config.numberOfSets,
            ),
            const SizedBox(height: 24),
            _buildTeamsRow(engine),
            const SizedBox(height: 16),
            ScoreDisplay(engine: engine),
            const SizedBox(height: 8),
            Text(
              'Games: ${engine.currentSetTeam1Games}  -  ${engine.currentSetTeam2Games}',
              style: GoogleFonts.manrope(
                fontSize: 16,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (overlay != null) _buildOverlay(overlay),
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: PointButton(
                        label: 'PUNTO\n${engine.team1Name.toUpperCase()}',
                        color: AppColors.primary,
                        onTap: () => ref.read(scoreboardProvider.notifier).scorePoint(1),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: PointButton(
                        label: 'PUNTO\n${engine.team2Name.toUpperCase()}',
                        color: AppColors.secondary,
                        onTap: () => ref.read(scoreboardProvider.notifier).scorePoint(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ScoreboardState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => _showExitConfirm(),
          ),
          Text(
            '⏱ ${_formatDuration(_elapsed)}',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.undo,
              color: state.engine.canUndo() ? Colors.white : Colors.white38,
            ),
            onPressed: state.engine.canUndo()
                ? () => ref.read(scoreboardProvider.notifier).undo()
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamsRow(MatchEngine engine) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ServeIndicator(servingTeam: engine.servingTeam, isTeam1: true),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  engine.team1Name,
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Icon(Icons.sports_tennis, color: Colors.white54, size: 28),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  engine.team2Name,
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ServeIndicator(servingTeam: engine.servingTeam, isTeam1: false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay(String message) {
    Future.delayed(const Duration(milliseconds: 1500), () {
      ref.read(scoreboardProvider.notifier).clearOverlay();
    });
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.accent.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text(
            message,
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.background,
            ),
          ),
        ),
      ),
    );
  }

  void _showExitConfirm() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('¿Salir del partido?'),
        content: const Text(
          'El partido en curso no se guardará. ¿Seguro?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(matchSetupDataProvider.notifier).state = null;
              context.go('/');
            },
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }
}

/// Resultado del partido para la pantalla de resumen.
class MatchResultData {
  MatchResultData({
    required this.engine,
    required this.startedAt,
    required this.team1Name,
    required this.team2Name,
  });
  final MatchEngine engine;
  final DateTime startedAt;
  final String team1Name;
  final String team2Name;
}

final matchResultProvider = StateNotifierProvider<MatchResultNotifier, MatchResultData?>((ref) {
  return MatchResultNotifier();
});

class MatchResultNotifier extends StateNotifier<MatchResultData?> {
  MatchResultNotifier() : super(null);

  void setResult({
    required MatchEngine engine,
    required DateTime startedAt,
    required String team1Name,
    required String team2Name,
  }) {
    state = MatchResultData(
      engine: engine,
      startedAt: startedAt,
      team1Name: team1Name,
      team2Name: team2Name,
    );
  }

  void clear() {
    state = null;
  }
}
