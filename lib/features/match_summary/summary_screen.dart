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
    final winnerName =
        winner == 1 ? result.team1Name : result.team2Name;
    final loserName =
        winner == 1 ? result.team2Name : result.team1Name;

    if (!_saved) {
      _saveMatch(result, duration.inSeconds);
    }

    final dateStr =
        '${result.startedAt.day}/${result.startedAt.month}/${result.startedAt.year}';
    final durationMin = duration.inMinutes;
    final matchTypeLabel = '${engine.config.numberOfSets} sets';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => _goHome(),
        ),
        title: Text(
          'Resultado',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Winner section
            if (winner != null) ...[
              Text(
                '\u{1F3C6}',
                style: GoogleFonts.manrope(fontSize: 48),
              ),
              const SizedBox(height: 12),
              Text(
                winnerName,
                style: GoogleFonts.manrope(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'GANADOR',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.success,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // VS separator
            Text(
              'VS',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 12),

            // Loser name
            if (winner != null)
              Text(
                loserName,
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),

            const SizedBox(height: 32),

            // Set scores in colored pills
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (int i = 0; i < sets.length; i++)
                  _buildSetPill(i, sets[i].team1Games, sets[i].team2Games),
              ],
            ),

            const SizedBox(height: 32),

            // Metadata row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMetaChip(Icons.calendar_today, dateStr),
                const SizedBox(width: 16),
                _buildMetaChip(Icons.access_time, '$durationMin min'),
                const SizedBox(width: 16),
                _buildMetaChip(Icons.sports_tennis, matchTypeLabel),
              ],
            ),

            const SizedBox(height: 48),

            // Action buttons
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _shareToWhatsApp(result, duration.inSeconds),
                icon: const Icon(Icons.chat, color: Colors.white, size: 20),
                label: Text(
                  'WhatsApp',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _shareToInstagram(result, duration.inSeconds),
                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                label: Text(
                  'Instagram',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => _copyImage(result, duration.inSeconds),
                icon: const Icon(Icons.copy, color: Colors.white, size: 20),
                label: Text(
                  'Copiar imagen',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSetPill(int index, int team1Games, int team2Games) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Text(
        'SET ${index + 1}:  $team1Games - $team2Games',
        style: GoogleFonts.spaceMono(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _goHome() async {
    if (!ref.read(isProProvider)) {
      await AdsService.showInterstitialIfLoaded();
    }
    ref.read(matchResultProvider.notifier).clear();
    if (mounted) context.go('/');
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

  Future<void> _shareToWhatsApp(
      MatchResultData result, int durationSeconds) async {
    await _shareResult(result, durationSeconds);
  }

  Future<void> _shareToInstagram(
      MatchResultData result, int durationSeconds) async {
    await _shareResult(result, durationSeconds);
  }

  Future<void> _copyImage(
      MatchResultData result, int durationSeconds) async {
    await _shareResult(result, durationSeconds);
  }

  Future<void> _shareResult(
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
