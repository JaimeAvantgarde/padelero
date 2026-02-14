import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:padelero/models/set_score.dart';
import 'package:padelero/shared/constants.dart';

class ShareCard extends StatelessWidget {
  const ShareCard({
    super.key,
    required this.team1Name,
    required this.team2Name,
    required this.setScores,
    this.winner,
    required this.date,
    required this.durationSeconds,
    this.size = ShareCardSize.story,
  });

  final String team1Name;
  final String team2Name;
  final List<SetScore> setScores;
  final int? winner;
  final DateTime date;
  final int durationSeconds;
  final ShareCardSize size;

  static Future<void> share(
    BuildContext context, {
    required String team1Name,
    required String team2Name,
    required List<SetScore> setScores,
    required int? winner,
    required DateTime date,
    required int durationSeconds,
  }) async {
    final captureKey = GlobalKey();
    final card = ShareCard(
      team1Name: team1Name,
      team2Name: team2Name,
      setScores: setScores,
      winner: winner,
      date: date,
      durationSeconds: durationSeconds,
      size: ShareCardSize.story,
    );
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (ctx) => Offstage(
        offstage: true,
        child: SizedBox(
          width: 1080,
          height: 1920,
          child: RepaintBoundary(
            key: captureKey,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: card,
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(overlayEntry);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final boundary = captureKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    overlayEntry.remove();
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/padelero_share.png');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Resultado del partido - ${AppStrings.appName}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = size.width;
    final h = size.height;
    final min = durationSeconds ~/ 60;
    final sec = durationSeconds % 60;
    final durationStr =
        '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
    final dateStr = '${date.day}/${date.month}/${date.year}';
    final winnerName = winner == 1 ? team1Name : team2Name;
    final loserName = winner == 1 ? team2Name : team1Name;

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.background,
            AppColors.surface,
            const Color(0xFF0D1117),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Decorative dots scattered around
          ..._buildDecorativeDots(w, h),

          // Main content
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.08,
              vertical: h * 0.06,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Branding at top
                _buildBranding(w),

                // Match result
                Column(
                  children: [
                    // Winner with trophy
                    if (winner != null) ...[
                      Text(
                        '\u{1F3C6}',
                        style: TextStyle(fontSize: w * 0.1),
                      ),
                      SizedBox(height: h * 0.015),
                      Text(
                        winnerName,
                        style: GoogleFonts.manrope(
                          fontSize: w * 0.065,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: h * 0.01),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: w * 0.04,
                          vertical: h * 0.005,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'GANADOR',
                          style: GoogleFonts.manrope(
                            fontSize: w * 0.03,
                            fontWeight: FontWeight.w800,
                            color: AppColors.success,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],

                    SizedBox(height: h * 0.03),

                    // VS separator
                    Text(
                      'VS',
                      style: GoogleFonts.manrope(
                        fontSize: w * 0.04,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    SizedBox(height: h * 0.02),

                    // Loser name
                    if (winner != null)
                      Text(
                        loserName,
                        style: GoogleFonts.manrope(
                          fontSize: w * 0.055,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),

                    SizedBox(height: h * 0.04),

                    // Set scores in individual boxes
                    Wrap(
                      spacing: w * 0.03,
                      runSpacing: h * 0.015,
                      alignment: WrapAlignment.center,
                      children: setScores.asMap().entries.map((e) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: w * 0.05,
                            vertical: h * 0.012,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.cardBorder,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'SET ${e.key + 1}: ${e.value.team1Games} - ${e.value.team2Games}',
                            style: GoogleFonts.spaceMono(
                              fontSize: w * 0.045,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

                // Stats row + URL
                Column(
                  children: [
                    // Stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatChip(w, Icons.calendar_today, dateStr),
                        SizedBox(width: w * 0.04),
                        _buildStatChip(w, Icons.access_time, durationStr),
                        SizedBox(width: w * 0.04),
                        _buildStatChip(w, Icons.sports_tennis, 'Padel'),
                      ],
                    ),
                    SizedBox(height: h * 0.025),
                    Text(
                      AppStrings.webUrl,
                      style: GoogleFonts.manrope(
                        fontSize: w * 0.03,
                        color: Colors.white38,
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

  Widget _buildBranding(double w) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: w * 0.06,
          height: w * 0.06,
          decoration: const BoxDecoration(
            color: AppColors.secondary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              'P',
              style: GoogleFonts.manrope(
                fontSize: w * 0.035,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
        SizedBox(width: w * 0.02),
        Text(
          'PADELERO',
          style: GoogleFonts.manrope(
            fontSize: w * 0.045,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(double w, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: w * 0.03, color: AppColors.textSecondary),
        SizedBox(width: w * 0.01),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: w * 0.028,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDecorativeDots(double w, double h) {
    final rng = Random(42); // Fixed seed for consistent layout
    final colors = [
      AppColors.primary.withValues(alpha: 0.3),
      AppColors.secondary.withValues(alpha: 0.3),
      AppColors.accent.withValues(alpha: 0.25),
      AppColors.success.withValues(alpha: 0.2),
    ];

    final dots = <Widget>[];
    // Place decorative dots at specific positions
    final positions = [
      Offset(w * 0.05, h * 0.08),
      Offset(w * 0.9, h * 0.12),
      Offset(w * 0.85, h * 0.04),
      Offset(w * 0.1, h * 0.88),
      Offset(w * 0.92, h * 0.85),
      Offset(w * 0.03, h * 0.5),
      Offset(w * 0.95, h * 0.55),
      Offset(w * 0.15, h * 0.95),
      Offset(w * 0.88, h * 0.92),
      Offset(w * 0.5, h * 0.03),
    ];

    for (int i = 0; i < positions.length; i++) {
      final size = (rng.nextDouble() * 8 + 4);
      dots.add(
        Positioned(
          left: positions[i].dx,
          top: positions[i].dy,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: colors[i % colors.length],
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }
    return dots;
  }
}

enum ShareCardSize {
  story(1080.0, 1920.0),
  post(1080.0, 1080.0);

  const ShareCardSize(this.width, this.height);
  final double width;
  final double height;
}
