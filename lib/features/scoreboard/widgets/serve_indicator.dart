import 'package:flutter/material.dart';

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
    final isServing = (servingTeam == 1 && isTeam1) || (servingTeam == 2 && !isTeam1);
    if (!isServing) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: const BoxDecoration(
        color: Color(0xFF1A73E8),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.sports_tennis, color: Colors.white, size: 20),
    );
  }
}
