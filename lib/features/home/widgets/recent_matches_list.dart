import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:padelero/models/match.dart';
import 'package:padelero/models/match_config.dart';
import 'package:padelero/shared/constants.dart';
import 'package:padelero/services/database_service.dart';

final recentMatchesProvider = FutureProvider<List<Match>>((ref) async {
  return DatabaseService.getRecentMatches(limit: 5);
});

class RecentMatchesList extends ConsumerWidget {
  const RecentMatchesList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMatches = ref.watch(recentMatchesProvider);

    return asyncMatches.when(
      data: (matches) {
        if (matches.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'Aun no hay partidos.\n\u00A1Juega el primero!',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  color: Colors.white38,
                ),
              ),
            ),
          );
        }
        return Column(
          children: [
            for (int i = 0; i < matches.length; i++) ...[
              _MatchCard(match: matches[i]),
              if (i < matches.length - 1) const SizedBox(height: 10),
            ],
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Error al cargar: $e',
          style: GoogleFonts.manrope(color: AppColors.defeat, fontSize: 14),
        ),
      ),
    );
  }
}

/// Shared match card widget used by both the recent matches list and history screen.
class MatchCard extends StatelessWidget {
  const MatchCard({super.key, required this.match});
  final Match match;

  @override
  Widget build(BuildContext context) {
    return _MatchCard(match: match);
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match});
  final Match match;

  @override
  Widget build(BuildContext context) {
    final sets = (match.resultJson['setScores'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    final winner = match.winner;
    final minutes = match.durationSeconds ~/ 60;
    final timeStr = DateFormat('HH:mm').format(match.date);
    final deuceLabel = match.config.deuceType == DeuceType.goldenPoint
        ? 'Golden Point'
        : 'Ventajas';

    // Left border color based on result
    Color borderColor;
    if (winner == null) {
      borderColor = AppColors.textSecondary;
    } else if (winner == 1) {
      borderColor = AppColors.success;
    } else {
      borderColor = AppColors.defeat;
    }

    return GestureDetector(
      onTap: () {
        if (match.id != null) context.push('/match/${match.id}');
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: borderColor, width: 3),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Left column: team names + info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    match.team1Name,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    match.team2Name,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$timeStr \u00B7 ${minutes}min \u00B7 $deuceLabel',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Right column: set scores + result pill
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Set scores
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < sets.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      _SetScoreColumn(
                        team1Score: sets[i]['team1'] as int? ?? 0,
                        team2Score: sets[i]['team2'] as int? ?? 0,
                        winner: winner,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                // Result pill
                if (winner != null) _ResultPill(winner: winner),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SetScoreColumn extends StatelessWidget {
  const _SetScoreColumn({
    required this.team1Score,
    required this.team2Score,
    required this.winner,
  });
  final int team1Score;
  final int team2Score;
  final int? winner;

  @override
  Widget build(BuildContext context) {
    // Highlight the winning team's score in the set where they scored more
    final t1Won = team1Score > team2Score;
    final t2Won = team2Score > team1Score;

    Color t1Color;
    if (winner == 1 && t1Won) {
      t1Color = AppColors.secondary;
    } else {
      t1Color = Colors.white70;
    }

    Color t2Color;
    if (winner == 2 && t2Won) {
      t2Color = AppColors.secondary;
    } else {
      t2Color = Colors.white70;
    }

    return Column(
      children: [
        Text(
          '$team1Score',
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: t1Won ? FontWeight.w800 : FontWeight.w500,
            color: t1Color,
          ),
        ),
        Text(
          '$team2Score',
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: t2Won ? FontWeight.w800 : FontWeight.w500,
            color: t2Color,
          ),
        ),
      ],
    );
  }
}

class _ResultPill extends StatelessWidget {
  const _ResultPill({required this.winner});
  final int winner;

  @override
  Widget build(BuildContext context) {
    final isVictory = winner == 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: isVictory
            ? AppColors.success.withValues(alpha: 0.15)
            : AppColors.defeat.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isVictory ? 'Victoria \u2713' : 'Derrota',
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isVictory ? AppColors.success : AppColors.defeat,
        ),
      ),
    );
  }
}
