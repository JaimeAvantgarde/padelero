import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padelero/models/set_score.dart';
import 'package:padelero/shared/constants.dart';

class SetIndicator extends StatelessWidget {
  const SetIndicator({
    super.key,
    required this.setScores,
    required this.currentSetTeam1Games,
    required this.currentSetTeam2Games,
    required this.totalSets,
  });

  final List<SetScore> setScores;
  final int currentSetTeam1Games;
  final int currentSetTeam2Games;
  final int totalSets;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];

    for (int i = 0; i < setScores.length; i++) {
      parts.add(
          'SET ${i + 1}: ${setScores[i].team1Games}-${setScores[i].team2Games}');
    }

    if (setScores.length < totalSets) {
      parts.add(
          'SET ${setScores.length + 1}: $currentSetTeam1Games-$currentSetTeam2Games');
    }

    final displayText = parts.join('  |  ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        displayText,
        style: GoogleFonts.manrope(
          fontSize: 14,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
