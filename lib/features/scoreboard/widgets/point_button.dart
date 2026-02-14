import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class PointButton extends StatelessWidget {
  const PointButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.color,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? color.withOpacity(0.9) : color.withOpacity(0.3),
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
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: enabled ? Colors.white : Colors.white54,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
