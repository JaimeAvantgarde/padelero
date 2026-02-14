import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padelero/shared/constants.dart';

class MonthlyBarChart extends StatelessWidget {
  const MonthlyBarChart({
    super.key,
    required this.monthlyStats,
  });

  /// Ordered map: month label -> MapEntry(victories, defeats).
  final Map<String, MapEntry<int, int>> monthlyStats;

  @override
  Widget build(BuildContext context) {
    final entries = monthlyStats.entries.toList();
    if (entries.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text('Sin datos', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    // Find max value for Y axis.
    int maxVal = 1;
    for (final e in entries) {
      final v = e.value.key;
      final d = e.value.value;
      if (v > maxVal) maxVal = v;
      if (d > maxVal) maxVal = d;
    }
    final maxY = (maxVal + 1).toDouble();

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: maxY > 4 ? (maxY / 4).ceilToDouble() : 1,
                getTitlesWidget: (value, meta) {
                  if (value == meta.max || value < 0) return const SizedBox.shrink();
                  return Text(
                    value.toInt().toString(),
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= entries.length) {
                    return const SizedBox.shrink();
                  }
                  final isLast = index == entries.length - 1;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      entries[index].key,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isLast ? AppColors.secondary : Colors.white70,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY > 4 ? (maxY / 4).ceilToDouble() : 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.white10,
              strokeWidth: 0.5,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(entries.length, (i) {
            final victories = entries[i].value.key.toDouble();
            final defeats = entries[i].value.value.toDouble();
            return BarChartGroupData(
              x: i,
              barsSpace: 3,
              barRods: [
                BarChartRodData(
                  toY: victories,
                  color: AppColors.primary,
                  width: 10,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                ),
                BarChartRodData(
                  toY: defeats,
                  color: AppColors.defeat,
                  width: 10,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                ),
              ],
            );
          }),
        ),
        duration: const Duration(milliseconds: 400),
      ),
    );
  }
}
