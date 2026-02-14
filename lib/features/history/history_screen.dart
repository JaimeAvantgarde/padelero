import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:padelero/features/home/widgets/recent_matches_list.dart';
import 'package:padelero/models/match.dart';
import 'package:padelero/shared/constants.dart';
import 'package:padelero/services/database_service.dart';

// ── Providers ──────────────────────────────────

final allMatchesProvider = FutureProvider<List<Match>>((ref) async {
  return DatabaseService.getAllMatches();
});

/// Filter: 0 = Todos, 1 = Victorias, 2 = Derrotas
final _historyFilterProvider = StateProvider<int>((ref) => 0);

// ── Screen ─────────────────────────────────────

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMatches = ref.watch(allMatchesProvider);
    final filter = ref.watch(_historyFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: asyncMatches.when(
          data: (allMatches) {
            // Sort by date descending (getAllMatches returns ASC)
            final sorted = List<Match>.from(allMatches)
              ..sort((a, b) => b.date.compareTo(a.date));

            // Compute stats from sorted list
            final victories =
                sorted.where((m) => m.winner == 1).length;
            final defeats =
                sorted.where((m) => m.winner == 2).length;
            final total = victories + defeats;
            final winRate =
                total > 0 ? (victories / total * 100).round() : 0;
            final streak = _computeStreak(sorted);

            // Apply filter
            List<Match> filtered;
            switch (filter) {
              case 1:
                filtered =
                    sorted.where((m) => m.winner == 1).toList();
                break;
              case 2:
                filtered =
                    sorted.where((m) => m.winner == 2).toList();
                break;
              default:
                filtered = sorted;
            }

            // Group by date
            final groups = _groupByDate(filtered);

            return CustomScrollView(
              slivers: [
                // Title
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(24, 24, 24, 20),
                    child: Text(
                      'Historial',
                      style: GoogleFonts.manrope(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Summary bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        _StatBox(
                          label: 'Victorias',
                          value: '$victories',
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        _StatBox(
                          label: 'Derrotas',
                          value: '$defeats',
                          color: AppColors.defeat,
                        ),
                        const SizedBox(width: 8),
                        _StatBox(
                          label: 'Win rate',
                          value: '$winRate%',
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        _StatBox(
                          label: 'Racha',
                          value: streak,
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                  ),
                ),

                // Filter chips
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(24, 20, 24, 12),
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'Todos',
                          selected: filter == 0,
                          onTap: () => ref
                              .read(_historyFilterProvider.notifier)
                              .state = 0,
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Victorias',
                          selected: filter == 1,
                          onTap: () => ref
                              .read(_historyFilterProvider.notifier)
                              .state = 1,
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Derrotas',
                          selected: filter == 2,
                          onTap: () => ref
                              .read(_historyFilterProvider.notifier)
                              .state = 2,
                        ),
                      ],
                    ),
                  ),
                ),

                // Empty state
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'No hay partidos',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          color: Colors.white38,
                        ),
                      ),
                    ),
                  ),

                // Grouped match list
                for (final group in groups) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          const EdgeInsets.fromLTRB(24, 20, 24, 8),
                      child: Text(
                        group.label,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: 10),
                            child: Dismissible(
                              key: ValueKey(
                                  group.matches[index].id),
                              direction:
                                  DismissDirection.endToStart,
                              background: Container(
                                alignment:
                                    Alignment.centerRight,
                                padding: const EdgeInsets.only(
                                    right: 20),
                                decoration: BoxDecoration(
                                  color: AppColors.defeat
                                      .withValues(alpha: 0.2),
                                  borderRadius:
                                      BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.defeat,
                                    size: 28),
                              ),
                              confirmDismiss: (_) =>
                                  _confirmDelete(context),
                              onDismissed: (_) async {
                                final m = group.matches[index];
                                if (m.id == null) return;
                                await DatabaseService
                                    .deleteMatch(m.id!);
                                ref.invalidate(
                                    allMatchesProvider);
                                ref.invalidate(
                                    recentMatchesProvider);
                              },
                              child: MatchCard(
                                  match:
                                      group.matches[index]),
                            ),
                          );
                        },
                        childCount: group.matches.length,
                      ),
                    ),
                  ),
                ],
                // Bottom padding
                const SliverToBoxAdapter(
                    child: SizedBox(height: 24)),
              ],
            );
          },
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(
              'Error: $e',
              style: GoogleFonts.manrope(
                  color: AppColors.defeat, fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Eliminar partido',
          style: GoogleFonts.manrope(
              fontWeight: FontWeight.w700, color: Colors.white),
        ),
        content: Text(
          '\u00BFEliminar este partido del historial? No se puede deshacer.',
          style: GoogleFonts.manrope(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: GoogleFonts.manrope(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.defeat),
            child: Text('Eliminar',
                style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Helper functions ───────────────────────────

String _computeStreak(List<Match> matches) {
  if (matches.isEmpty) return '0';
  int count = 0;
  final firstResult = matches.first.winner;
  if (firstResult == null) return '0';
  for (final m in matches) {
    if (m.winner == firstResult) {
      count++;
    } else {
      break;
    }
  }
  final prefix = firstResult == 1 ? 'W' : 'L';
  return '$prefix$count';
}

class _DateGroup {
  _DateGroup({required this.label, required this.matches});
  final String label;
  final List<Match> matches;
}

List<_DateGroup> _groupByDate(List<Match> matches) {
  if (matches.isEmpty) return [];

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final formatter = DateFormat('dd MMMM', 'es');

  final Map<String, List<Match>> grouped = {};
  final List<String> orderedKeys = [];

  for (final m in matches) {
    final matchDay =
        DateTime(m.date.year, m.date.month, m.date.day);
    String label;
    if (matchDay == today) {
      label = 'HOY';
    } else if (matchDay == yesterday) {
      label = 'AYER';
    } else {
      label = formatter.format(m.date).toUpperCase();
    }
    if (!grouped.containsKey(label)) {
      grouped[label] = [];
      orderedKeys.add(label);
    }
    grouped[label]!.add(m);
  }

  return orderedKeys
      .map((key) => _DateGroup(label: key, matches: grouped[key]!))
      .toList();
}

// ── Subwidgets ─────────────────────────────────

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.success
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.success
                : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }
}
