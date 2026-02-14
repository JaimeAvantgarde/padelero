import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padelero/features/history/history_screen.dart';
import 'package:padelero/features/home/widgets/recent_matches_list.dart';
import 'package:padelero/models/match.dart';
import 'package:padelero/shared/constants.dart';
import 'package:padelero/models/set_score.dart';
import 'package:padelero/services/database_service.dart';

class MatchDetailScreen extends ConsumerStatefulWidget {
  const MatchDetailScreen({super.key, required this.matchId});

  final int matchId;

  @override
  ConsumerState<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends ConsumerState<MatchDetailScreen> {
  Future<Match?> _loadMatch() async {
    return DatabaseService.getMatchById(widget.matchId);
  }

  Future<void> _deleteMatch(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Eliminar partido'),
        content: const Text(
          '¿Eliminar este partido del historial? No se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await DatabaseService.deleteMatch(widget.matchId);
    ref.invalidate(allMatchesProvider);
    ref.invalidate(recentMatchesProvider);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detalle del partido'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteMatch(context),
          ),
        ],
      ),
      body: FutureBuilder<Match?>(
        future: _loadMatch(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final match = snapshot.data;
          if (match == null) {
            return const Center(child: Text('Partido no encontrado'));
          }
          final sets = (match.resultJson['setScores'] as List?)
                  ?.map((e) => SetScore(
                        team1Games: (e as Map<String, dynamic>)['team1'] as int,
                        team2Games: e['team2'] as int,
                      ))
                  .toList() ??
              <SetScore>[];
          final duration = match.durationSeconds;
          final min = duration ~/ 60;
          final sec = duration % 60;
          final durationStr = '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
          final dateStr = '${match.date.day}/${match.date.month}/${match.date.year}';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${match.team1Name} vs ${match.team2Name}',
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ...sets.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Set ${e.key + 1}: ${e.value.team1Games} - ${e.value.team2Games}',
                        style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    )),
                const SizedBox(height: 16),
                Text(
                  'Duración: $durationStr',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  'Fecha: $dateStr',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                if (match.winner != null) ...[
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events, color: AppColors.accent, size: 32),
                      const SizedBox(width: 8),
                      Text(
                        'Ganador: ${match.winner == 1 ? match.team1Name : match.team2Name}',
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
