import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padelero/features/home/widgets/recent_matches_list.dart';
import 'package:padelero/features/scoreboard/scoreboard_provider.dart';
import 'package:padelero/features/settings/pro_provider.dart';
import 'package:padelero/models/match_config.dart';
import 'package:padelero/shared/constants.dart';
import 'package:padelero/shared/widgets/ad_banner_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _team1Controller = TextEditingController(text: 'Equipo 1');
  final _team2Controller = TextEditingController(text: 'Equipo 2');
  int _numberOfSets = 3;
  bool _goldenPoint = true;
  bool _superTieBreak = false;
  int _firstServer = 1;

  @override
  void dispose() {
    _team1Controller.dispose();
    _team2Controller.dispose();
    super.dispose();
  }

  void _startMatch() {
    final t1 = _team1Controller.text.trim();
    final t2 = _team2Controller.text.trim();
    if (t1.isEmpty || t2.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Introduce el nombre de ambos equipos',
            style: GoogleFonts.manrope(),
          ),
          backgroundColor: AppColors.defeat,
        ),
      );
      return;
    }
    final config = MatchConfig(
      numberOfSets: _numberOfSets,
      deuceType: _goldenPoint ? DeuceType.goldenPoint : DeuceType.advantages,
      lastSetTieBreak:
          _superTieBreak ? TieBreakType.superTieBreak : TieBreakType.normal,
      firstServer: _firstServer,
    );
    ref.read(matchSetupDataProvider.notifier).state = MatchSetupData(
      team1Name: t1,
      team2Name: t2,
      config: config,
    );
    context.go('/scoreboard');
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(isProProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    // ── Title row ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Nuevo Partido',
                          style: GoogleFonts.manrope(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined,
                              color: Colors.white70, size: 26),
                          onPressed: () => context.push('/settings'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ── EQUIPO 1 ──
                    _SectionHeader(label: 'EQUIPO 1'),
                    const SizedBox(height: 8),
                    _TeamTextField(
                      controller: _team1Controller,
                      hintText: 'Nombre equipo 1',
                    ),
                    const SizedBox(height: 20),

                    // ── EQUIPO 2 ──
                    _SectionHeader(label: 'EQUIPO 2'),
                    const SizedBox(height: 8),
                    _TeamTextField(
                      controller: _team2Controller,
                      hintText: 'Nombre equipo 2',
                    ),
                    const SizedBox(height: 28),

                    // ── FORMATO ──
                    _SectionHeader(label: 'FORMATO'),
                    const SizedBox(height: 12),

                    // Number of sets
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Numero de sets',
                          style: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        Row(
                          children: [
                            for (final n in [1, 3, 5])
                              Padding(
                                padding: EdgeInsets.only(
                                    left: n == 1 ? 0 : 8),
                                child: _SetToggleButton(
                                  label: '$n',
                                  selected: _numberOfSets == n,
                                  onTap: () =>
                                      setState(() => _numberOfSets = n),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Golden Point switch
                    _SwitchTile(
                      title: 'Golden Point',
                      subtitle: 'En 40-40, el siguiente punto gana',
                      value: _goldenPoint,
                      onChanged: (v) => setState(() => _goldenPoint = v),
                    ),

                    // Super Tie-Break switch
                    _SwitchTile(
                      title: 'Super Tie-Break 3er set',
                      subtitle: 'Primer equipo a 10 puntos',
                      value: _superTieBreak,
                      onChanged: (v) => setState(() => _superTieBreak = v),
                    ),
                    const SizedBox(height: 24),

                    // ── QUIEN SACA PRIMERO ──
                    _SectionHeader(label: 'QUIEN SACA PRIMERO'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ServerButton(
                            label: _team1Controller.text.trim().isEmpty
                                ? 'Equipo 1'
                                : _team1Controller.text.trim(),
                            selected: _firstServer == 1,
                            onTap: () => setState(() => _firstServer = 1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ServerButton(
                            label: _team2Controller.text.trim().isEmpty
                                ? 'Equipo 2'
                                : _team2Controller.text.trim(),
                            selected: _firstServer == 2,
                            onTap: () => setState(() => _firstServer = 2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ── START BUTTON ──
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _startMatch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Empezar Partido',
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── PARTIDOS RECIENTES header ──
                    _SectionHeader(label: 'PARTIDOS RECIENTES'),
                    const SizedBox(height: 12),

                    // Recent matches list (non-sliver)
                    const RecentMatchesList(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            // Ad banner for free users
            if (!isPro) const Center(child: AdBannerWidget()),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Private helper widgets
// ─────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _TeamTextField extends StatelessWidget {
  const _TeamTextField({
    required this.controller,
    required this.hintText,
  });
  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Text(
            '\u{1F3CF}',
            style: const TextStyle(fontSize: 20),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        hintText: hintText,
        hintStyle: GoogleFonts.manrope(
          fontSize: 16,
          color: Colors.white38,
        ),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}

class _SetToggleButton extends StatelessWidget {
  const _SetToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 40,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : Colors.white54,
          ),
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: GoogleFonts.manrope(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.manrope(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.primary,
      ),
    );
  }
}

class _ServerButton extends StatelessWidget {
  const _ServerButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.25)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.cardBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (selected) ...[
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Colors.white : Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
