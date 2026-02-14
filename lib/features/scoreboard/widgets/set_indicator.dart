import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padelero/models/set_score.dart';

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
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      children: [
        for (int i = 0; i < setScores.length; i++)
          Text(
            'SET ${i + 1}: ${setScores[i].team1Games}-${setScores[i].team2Games}',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        if (setScores.length < totalSets)
          Text(
            'SET ${setScores.length + 1}: $currentSetTeam1Games-$currentSetTeam2Games',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}
