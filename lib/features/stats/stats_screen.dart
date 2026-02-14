import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padelero/shared/constants.dart';
import 'package:padelero/features/stats/stats_provider.dart';
import 'package:padelero/features/stats/widgets/win_rate_donut.dart';
import 'package:padelero/features/stats/widgets/monthly_bar_chart.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStats = ref.watch(matchStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: asyncStats.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(
              'Error: $e',
              style: const TextStyle(color: Colors.red),
            ),
          ),
          data: (stats) => _StatsBody(stats: stats),
        ),
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.stats});
  final MatchStats stats;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header ---
          Text(
            'Estadísticas',
            style: GoogleFonts.manrope(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Resumen general',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // --- Top stats card ---
          _buildTopStatsCard(),
          const SizedBox(height: 16),

          // --- Monthly bar chart card ---
          _buildMonthlyCard(),
          const SizedBox(height: 16),

          // --- Best partners card ---
          _buildPartnersCard(),
          const SizedBox(height: 16),

          // --- Serve / Return row ---
          _buildServeReturnRow(),
        ],
      ),
    );
  }

  Widget _buildTopStatsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          WinRateDonut(winRate: stats.winRate),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _statLine(
                  'Partidos jugados',
                  stats.totalMatches.toString(),
                  Colors.white,
                ),
                const SizedBox(height: 8),
                _statLine(
                  'Victorias',
                  stats.victories.toString(),
                  AppColors.success,
                ),
                const SizedBox(height: 4),
                _statLine(
                  'Derrotas',
                  stats.defeats.toString(),
                  AppColors.defeat,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mejor racha',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${stats.bestStreak} victorias',
                            style: GoogleFonts.spaceMono(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Racha actual',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${stats.currentStreak} victorias',
                            style: GoogleFonts.spaceMono(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statLine(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.spaceMono(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Partidos por mes',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Row(
                children: [
                  _legendDot(AppColors.primary, 'Victorias'),
                  const SizedBox(width: 12),
                  _legendDot(AppColors.defeat, 'Derrotas'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          MonthlyBarChart(monthlyStats: stats.monthlyStats),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPartnersCard() {
    if (stats.partnerWinRates.isEmpty) {
      return const SizedBox.shrink();
    }

    // Show top 5 partners.
    final partners = stats.partnerWinRates.entries.take(5).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mejores parejas',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...partners.map((entry) => _partnerRow(entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _partnerRow(String name, double winPct) {
    // Color gradient: low win% -> defeat, high win% -> success.
    final barColor = Color.lerp(
      AppColors.defeat,
      AppColors.success,
      (winPct / 100).clamp(0, 1),
    )!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  name,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${winPct.round()}%',
                style: GoogleFonts.spaceMono(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: barColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (winPct / 100).clamp(0, 1),
              backgroundColor: Colors.white10,
              color: barColor,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServeReturnRow() {
    return Row(
      children: [
        Expanded(child: _miniStatCard('Al saque', '0%')),
        const SizedBox(width: 12),
        Expanded(child: _miniStatCard('Al resto', '0%')),
      ],
    );
  }

  Widget _miniStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.spaceMono(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
