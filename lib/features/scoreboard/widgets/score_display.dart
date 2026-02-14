import 'package:flutter/material.dart';
import 'package:padelero/app/theme.dart';
import 'package:padelero/features/scoreboard/match_engine.dart';

class ScoreDisplay extends StatelessWidget {
  const ScoreDisplay({
    super.key,
    required this.engine,
    this.animate = false,
  });

  final MatchEngine engine;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final g = engine.gameScore;
    String p1 = g.pointDisplay(true);
    String p2 = g.pointDisplay(false);
    if (engine.isTieBreak) {
      p1 = '${engine.tieBreakTeam1Points}';
      p2 = '${engine.tieBreakTeam2Points}';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ScoreNumber(p1, animate),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '-',
            style: scoreNumberStyle(48),
          ),
        ),
        _ScoreNumber(p2, animate),
      ],
    );
  }
}

class _ScoreNumber extends StatelessWidget {
  const _ScoreNumber(this.text, this.animate);

  final String text;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.9, end: 1),
      duration: const Duration(milliseconds: 150),
      builder: (context, value, child) {
        return Transform.scale(
          scale: animate ? value : 1,
          child: Text(
            text,
            style: scoreNumberStyle(88),
          ),
        );
      },
    );
  }
}
