import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padelero/shared/constants.dart';

class GamesBar extends StatelessWidget {
  const GamesBar({
    super.key,
    required this.team1Games,
    required this.team2Games,
  });

  final int team1Games;
  final int team2Games;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Team 1 pill (blue)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.team1.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.team1.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  'Games: $team1Games',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.team1,
                  ),
                ),
              ),
            ),
          ),
          // Center yellow divider
          Container(
            width: 4,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Team 2 pill (orange)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.team2.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.team2.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  'Games: $team2Games',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.team2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
