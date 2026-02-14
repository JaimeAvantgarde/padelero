import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padelero/models/match_config.dart';
import 'package:padelero/features/scoreboard/scoreboard_provider.dart';
import 'package:padelero/shared/constants.dart';

class MatchSetupScreen extends ConsumerStatefulWidget {
  const MatchSetupScreen({super.key});

  @override
  ConsumerState<MatchSetupScreen> createState() => _MatchSetupScreenState();
}

class _MatchSetupScreenState extends ConsumerState<MatchSetupScreen> {
  final _team1Controller = TextEditingController(text: 'Equipo 1');
  final _team2Controller = TextEditingController(text: 'Equipo 2');
  int _numberOfSets = 3;
  DeuceType _deuceType = DeuceType.advantages;
  TieBreakType _lastSetTieBreak = TieBreakType.normal;
  int _firstServer = 1;

  @override
  void dispose() {
    _team1Controller.dispose();
    _team2Controller.dispose();
    super.dispose();
  }

  void _startMatch() {
    final config = MatchConfig(
      numberOfSets: _numberOfSets,
      deuceType: _deuceType,
      lastSetTieBreak: _lastSetTieBreak,
      firstServer: _firstServer,
    );
    ref.read(matchSetupDataProvider.notifier).state = MatchSetupData(
      team1Name: _team1Controller.text.trim().isEmpty ? 'Equipo 1' : _team1Controller.text.trim(),
      team2Name: _team2Controller.text.trim().isEmpty ? 'Equipo 2' : _team2Controller.text.trim(),
      config: config,
    );
    context.go('/scoreboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nuevo partido'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Equipos',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _team1Controller,
              decoration: const InputDecoration(
                labelText: 'Equipo 1',
                hintText: 'Nombre del equipo 1',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _team2Controller,
              decoration: const InputDecoration(
                labelText: 'Equipo 2',
                hintText: 'Nombre del equipo 2',
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Quién saca primero',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _OptionChip<int>(
                    label: 'Equipo 1',
                    value: 1,
                    groupValue: _firstServer,
                    onSelected: (v) => setState(() => _firstServer = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _OptionChip<int>(
                    label: 'Equipo 2',
                    value: 2,
                    groupValue: _firstServer,
                    onSelected: (v) => setState(() => _firstServer = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Formato',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final n in [1, 3, 5])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _OptionChip<int>(
                      label: '$n set${n > 1 ? 's' : ''}',
                      value: n,
                      groupValue: _numberOfSets,
                      onSelected: (v) => setState(() => _numberOfSets = v!),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Tipo de deuce',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _OptionChip<DeuceType>(
                    label: 'Golden point',
                    value: DeuceType.goldenPoint,
                    groupValue: _deuceType,
                    onSelected: (v) => setState(() => _deuceType = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _OptionChip<DeuceType>(
                    label: 'Ventajas',
                    value: DeuceType.advantages,
                    groupValue: _deuceType,
                    onSelected: (v) => setState(() => _deuceType = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Tie-break último set',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _OptionChip<TieBreakType>(
                    label: 'A 7',
                    value: TieBreakType.normal,
                    groupValue: _lastSetTieBreak,
                    onSelected: (v) => setState(() => _lastSetTieBreak = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _OptionChip<TieBreakType>(
                    label: 'Super (a 10)',
                    value: TieBreakType.superTieBreak,
                    groupValue: _lastSetTieBreak,
                    onSelected: (v) => setState(() => _lastSetTieBreak = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _startMatch,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Empezar partido'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionChip<T> extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onSelected,
  });

  final String label;
  final T value;
  final T groupValue;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return Material(
      color: selected ? AppColors.primary.withValues(alpha: 0.3) : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => onSelected(value),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.white : Colors.white70,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
