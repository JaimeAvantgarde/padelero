import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padelero/features/scoreboard/scoreboard_screen.dart';
import 'package:padelero/features/match_summary/share_card.dart';
import 'package:padelero/features/settings/pro_provider.dart';
import 'package:padelero/features/home/widgets/recent_matches_list.dart';
import 'package:padelero/models/match.dart';
import 'package:padelero/services/ads_service.dart';
import 'package:padelero/services/database_service.dart';
import 'package:padelero/shared/constants.dart';

class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(matchResultProvider);
    if (result == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/');
      });
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final engine = result.engine;
    final winner = engine.getMatchWinner();
    final sets = engine.setScores;
    final duration = DateTime.now().difference(result.startedAt);

    if (!_saved) {
      _saveMatch(result, duration.inSeconds);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Resultado'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            if (!ref.read(isProProvider)) {
              await AdsService.showInterstitialIfLoaded();
            }
            ref.read(matchResultProvider.notifier).clear();
            if (mounted) context.go('/');
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            if (winner != null)
              Text(
                '¡${winner == 1 ? result.team1Name : result.team2Name} gana!',
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),
            for (int i = 0; i < sets.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Set ${i + 1}: ${sets[i].team1Games} - ${sets[i].team2Games}',
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Duración: ${duration.inMinutes} min',
              style: GoogleFonts.manrope(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 48),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      if (!ref.read(isProProvider)) {
                        await AdsService.showInterstitialIfLoaded();
                      }
                      if (mounted) context.go('/');
                    },
                    icon: const Icon(Icons.home),
                    label: const Text('Inicio'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareResult(context, result, duration.inSeconds),
                    icon: const Icon(Icons.share),
                    label: const Text('Compartir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveMatch(MatchResultData result, int durationSeconds) async {
    if (_saved) return;
    final engine = result.engine;
    final match = Match(
      id: null,
      team1Name: result.team1Name,
      team2Name: result.team2Name,
      config: engine.config,
      resultJson: engine.getMatchResult(),
      date: DateTime.now(),
      durationSeconds: durationSeconds,
      winner: engine.getMatchWinner(),
    );
    await DatabaseService.insertMatch(match);
    ref.invalidate(recentMatchesProvider);
    if (mounted) setState(() => _saved = true);
  }

  Future<void> _shareResult(
    BuildContext context,
    MatchResultData result,
    int durationSeconds,
  ) async {
    final engine = result.engine;
    final sets = engine.setScores;
    await ShareCard.share(
      context,
      team1Name: result.team1Name,
      team2Name: result.team2Name,
      setScores: sets,
      winner: engine.getMatchWinner(),
      date: DateTime.now(),
      durationSeconds: durationSeconds,
    );
  }
}
