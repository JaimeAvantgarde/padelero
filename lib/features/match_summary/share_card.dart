import 'dart:io';
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
    final boundary =
        captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
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
      text: 'Resultado del partido - $AppStrings.appName',
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = size.width;
    final h = size.height;
    final min = durationSeconds ~/ 60;
    final sec = durationSeconds % 60;
    final durationStr = '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
    final dateStr = '${date.day}/${date.month}/${date.year}';

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
      child: Padding(
        padding: EdgeInsets.all(w * 0.08),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.appName,
              style: GoogleFonts.manrope(
                fontSize: w * 0.08,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Column(
              children: [
                Text(
                  team1Name,
                  style: GoogleFonts.manrope(
                    fontSize: w * 0.06,
                    fontWeight: FontWeight.w700,
                    color: winner == 1 ? AppColors.accent : Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: h * 0.02),
                Text(
                  'VS',
                  style: GoogleFonts.manrope(
                    fontSize: w * 0.04,
                    color: Colors.white54,
                  ),
                ),
                SizedBox(height: h * 0.02),
                Text(
                  team2Name,
                  style: GoogleFonts.manrope(
                    fontSize: w * 0.06,
                    fontWeight: FontWeight.w700,
                    color: winner == 2 ? AppColors.accent : Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: h * 0.04),
                ...setScores.asMap().entries.map((e) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: h * 0.01),
                    child: Text(
                      'Set ${e.key + 1}: ${e.value.team1Games} - ${e.value.team2Games}',
                      style: GoogleFonts.spaceMono(
                        fontSize: w * 0.07,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  );
                }),
                if (winner != null) ...[
                  SizedBox(height: h * 0.02),
                  Icon(
                    Icons.emoji_events,
                    size: w * 0.12,
                    color: AppColors.accent,
                  ),
                ],
              ],
            ),
            Column(
              children: [
                Text(
                  '$dateStr · $durationStr',
                  style: GoogleFonts.manrope(
                    fontSize: w * 0.035,
                    color: Colors.white54,
                  ),
                ),
                SizedBox(height: h * 0.02),
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
    );
  }
}

enum ShareCardSize {
  story(1080.0, 1920.0),
  post(1080.0, 1080.0);

  const ShareCardSize(this.width, this.height);
  final double width;
  final double height;
}
