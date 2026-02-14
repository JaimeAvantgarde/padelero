import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padelero/shared/constants.dart';

class ServeIndicator extends StatelessWidget {
  const ServeIndicator({
    super.key,
    required this.servingTeam,
    required this.isTeam1,
  });

  final int servingTeam;
  final bool isTeam1;

  @override
  Widget build(BuildContext context) {
    final isServing =
        (servingTeam == 1 && isTeam1) || (servingTeam == 2 && !isTeam1);
    if (!isServing) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'Saca',
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }
}
