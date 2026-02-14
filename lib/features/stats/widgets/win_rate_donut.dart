import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padelero/shared/constants.dart';

class WinRateDonut extends StatelessWidget {
  const WinRateDonut({
    super.key,
    required this.winRate,
    this.size = 100,
  });

  final double winRate;
  final double size;

  @override
  Widget build(BuildContext context) {
    final lossRate = 100 - winRate;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              startDegreeOffset: -90,
              sectionsSpace: 2,
              centerSpaceRadius: size * 0.32,
              sections: [
                PieChartSectionData(
                  value: winRate.clamp(0.01, 100),
                  color: AppColors.success,
                  radius: size * 0.18,
                  showTitle: false,
                ),
                PieChartSectionData(
                  value: lossRate.clamp(0.01, 100),
                  color: AppColors.defeat,
                  radius: size * 0.18,
                  showTitle: false,
                ),
              ],
              borderData: FlBorderData(show: false),
            ),
            duration: const Duration(milliseconds: 600),
          ),
          Text(
            '${winRate.round()}%',
            style: GoogleFonts.spaceMono(
              fontSize: size * 0.2,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
