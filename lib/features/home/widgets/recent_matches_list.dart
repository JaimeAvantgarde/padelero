import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padelero/models/match.dart';
import 'package:padelero/shared/constants.dart';
import 'package:padelero/services/database_service.dart';

final recentMatchesProvider = FutureProvider<List<Match>>((ref) async {
  return DatabaseService.getRecentMatches(limit: 10);
});

class RecentMatchesList extends ConsumerWidget {
  const RecentMatchesList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recentMatchesProvider);
    return async.when(
      data: (matches) {
        if (matches.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Aún no hay partidos. ¡Juega el primero!',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final m = matches[index];
              return _MatchTile(match: m);
            },
            childCount: matches.length,
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Error al cargar: $e',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({required this.match});

  final Match match;

  @override
  Widget build(BuildContext context) {
    final sets = (match.resultJson['setScores'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final resultStr = sets
        .map((s) => '${s['team1']}-${s['team2']}')
        .join(' | ');
    final winner = match.winner;
    final duration = match.durationSeconds;
    final min = duration ~/ 60;
    final sec = duration % 60;
    final durationStr = '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        title: Text(
          '${match.team1Name} vs ${match.team2Name}',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          '$resultStr · $durationStr',
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        trailing: winner != null
            ? Icon(
                winner == 1 ? Icons.emoji_events : Icons.emoji_events,
                color: AppColors.accent,
                size: 28,
              )
            : null,
        onTap: () {
          if (match.id != null) context.push('/history/${match.id}');
        },
      ),
    );
  }
}
