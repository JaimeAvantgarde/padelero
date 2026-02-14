import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_shell.dart';
import '../features/home/home_screen.dart';
import '../features/scoreboard/scoreboard_screen.dart';
import '../features/match_summary/summary_screen.dart';
import '../features/history/history_screen.dart';
import '../features/history/match_detail_screen.dart';
import '../features/stats/stats_screen.dart';
import '../features/settings/settings_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      // Bottom nav shell with 3 tabs
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
          GoRoute(path: '/stats', builder: (_, __) => const StatsScreen()),
        ],
      ),
      // Full-screen routes (no bottom nav)
      GoRoute(path: '/scoreboard', builder: (_, __) => const ScoreboardScreen(), parentNavigatorKey: _rootNavigatorKey),
      GoRoute(path: '/summary', builder: (_, __) => const SummaryScreen(), parentNavigatorKey: _rootNavigatorKey),
      GoRoute(
        path: '/match/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return MatchDetailScreen(matchId: id ?? 0);
        },
      ),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen(), parentNavigatorKey: _rootNavigatorKey),
    ],
  );
}

final routerProvider = Provider<GoRouter>((ref) => createRouter());
