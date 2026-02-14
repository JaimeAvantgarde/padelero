import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:padelero/models/match.dart';
import 'package:padelero/services/database_service.dart';

class MatchStats {
  const MatchStats({
    required this.totalMatches,
    required this.victories,
    required this.defeats,
    required this.winRate,
    required this.bestStreak,
    required this.currentStreak,
    required this.monthlyStats,
    required this.partnerWinRates,
  });

  final int totalMatches;
  final int victories;
  final int defeats;
  final double winRate;
  final int bestStreak;
  final int currentStreak;

  /// Key: abbreviated Spanish month name (e.g. "Ene", "Feb").
  /// Value: MapEntry(victories, defeats) for that month.
  final Map<String, MapEntry<int, int>> monthlyStats;

  /// Key: partner name, Value: win rate percentage (0-100).
  final Map<String, double> partnerWinRates;

  static const MatchStats empty = MatchStats(
    totalMatches: 0,
    victories: 0,
    defeats: 0,
    winRate: 0,
    bestStreak: 0,
    currentStreak: 0,
    monthlyStats: {},
    partnerWinRates: {},
  );
}

/// Spanish abbreviated month names indexed 1-12.
const _spanishMonths = [
  '', // index 0 unused
  'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
  'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
];

MatchStats _computeStats(List<Match> matches) {
  if (matches.isEmpty) return MatchStats.empty;

  // Only consider finished matches (winner != null).
  final finished = matches.where((m) => m.winner != null).toList();
  if (finished.isEmpty) return MatchStats.empty;

  // Sort by date ascending so streaks are computed chronologically.
  finished.sort((a, b) => a.date.compareTo(b.date));

  final totalMatches = finished.length;
  final victories = finished.where((m) => m.winner == 1).length;
  final defeats = totalMatches - victories;
  final winRate = totalMatches > 0 ? (victories / totalMatches) * 100 : 0.0;

  // --- Streaks ---
  int bestStreak = 0;
  int currentStreak = 0;
  int runStreak = 0;
  for (final m in finished) {
    if (m.winner == 1) {
      runStreak++;
      bestStreak = max(bestStreak, runStreak);
    } else {
      runStreak = 0;
    }
  }
  // Current streak: count consecutive wins from the end.
  for (int i = finished.length - 1; i >= 0; i--) {
    if (finished[i].winner == 1) {
      currentStreak++;
    } else {
      break;
    }
  }

  // --- Monthly stats (last 6 months) ---
  final now = DateTime.now();
  final monthlyStats = <String, MapEntry<int, int>>{};

  // Build ordered list of the last 6 months.
  for (int offset = 5; offset >= 0; offset--) {
    final target = DateTime(now.year, now.month - offset, 1);
    final label = _spanishMonths[target.month];
    monthlyStats[label] = const MapEntry(0, 0);
  }

  for (final m in finished) {
    final label = _spanishMonths[m.date.month];
    if (monthlyStats.containsKey(label)) {
      final prev = monthlyStats[label]!;
      if (m.winner == 1) {
        monthlyStats[label] = MapEntry(prev.key + 1, prev.value);
      } else {
        monthlyStats[label] = MapEntry(prev.key, prev.value + 1);
      }
    }
  }

  // --- Partner win rates ---
  // team1Name may contain individual names separated by " / " or "/".
  final partnerWins = <String, int>{};
  final partnerTotal = <String, int>{};

  for (final m in finished) {
    final names = m.team1Name
        .split(RegExp(r'\s*/\s*'))
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty);
    for (final name in names) {
      partnerTotal[name] = (partnerTotal[name] ?? 0) + 1;
      if (m.winner == 1) {
        partnerWins[name] = (partnerWins[name] ?? 0) + 1;
      }
    }
  }

  final partnerWinRates = <String, double>{};
  for (final name in partnerTotal.keys) {
    final total = partnerTotal[name]!;
    final wins = partnerWins[name] ?? 0;
    partnerWinRates[name] = total > 0 ? (wins / total) * 100 : 0;
  }

  // Sort partners by win rate descending.
  final sortedPartners = Map.fromEntries(
    partnerWinRates.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)),
  );

  return MatchStats(
    totalMatches: totalMatches,
    victories: victories,
    defeats: defeats,
    winRate: winRate,
    bestStreak: bestStreak,
    currentStreak: currentStreak,
    monthlyStats: monthlyStats,
    partnerWinRates: sortedPartners,
  );
}

final matchStatsProvider = FutureProvider.autoDispose<MatchStats>((ref) async {
  final matches = await DatabaseService.getAllMatches();
  return _computeStats(matches);
});
