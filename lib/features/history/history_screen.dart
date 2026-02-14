import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padelero/features/home/widgets/recent_matches_list.dart';
import 'package:padelero/models/match.dart';
import 'package:padelero/shared/constants.dart';
import 'package:padelero/services/database_service.dart';

final allMatchesProvider = FutureProvider<List<Match>>((ref) async {
  return DatabaseService.getRecentMatches(limit: 100);
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(allMatchesProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Historial'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: async.when(
        data: (matches) {
          if (matches.isEmpty) {
            return Center(
              child: Text(
                'No hay partidos guardados',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  color: Colors.white54,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final m = matches[index];
              return _MatchTile(
                match: m,
                onDelete: () async {
                  if (m.id == null) return;
                  await DatabaseService.deleteMatch(m.id!);
                  ref.invalidate(allMatchesProvider);
                  ref.invalidate(recentMatchesProvider);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({required this.match, required this.onDelete});

  final Match match;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final sets = (match.resultJson['setScores'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final resultStr = sets
        .map((s) => '${s['team1']}-${s['team2']}')
        .join(' | ');
    final duration = match.durationSeconds;
    final min = duration ~/ 60;
    final sec = duration % 60;
    final durationStr = '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
    final dateStr = '${match.date.day}/${match.date.month}/${match.date.year}';

    return Dismissible(
      key: ValueKey(match.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
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
      },
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
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
            '$resultStr · $durationStr · $dateStr',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (match.winner != null)
                Icon(Icons.emoji_events, color: AppColors.accent, size: 28),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white54),
                onPressed: () async {
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
                  if (confirm == true) onDelete();
                },
              ),
            ],
          ),
          onTap: () {
            if (match.id != null) context.push('/history/${match.id}');
          },
        ),
      ),
    );
  }
}
