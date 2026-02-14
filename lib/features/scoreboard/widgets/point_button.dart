import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class PointButton extends StatelessWidget {
  const PointButton({
    super.key,
    required this.teamName,
    required this.onTap,
    required this.color,
    this.enabled = true,
  });

  final String teamName;
  final VoidCallback onTap;
  final Color color;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Material(
        color: enabled ? color.withValues(alpha: 0.9) : color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: enabled
              ? () {
                  HapticFeedback.lightImpact();
                  onTap();
                }
              : null,
          borderRadius: BorderRadius.circular(24),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'PUNTO',
                    style: GoogleFonts.manrope(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: enabled ? Colors.white : Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    teamName.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: enabled
                          ? Colors.white.withValues(alpha: 0.8)
                          : Colors.white54,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
