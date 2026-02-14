import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/home/home_screen.dart';
import '../features/match_setup/match_setup_screen.dart';
import '../features/scoreboard/scoreboard_screen.dart';
import '../features/match_summary/summary_screen.dart';
import '../features/history/history_screen.dart';
import '../features/history/match_detail_screen.dart';
import '../features/settings/settings_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: '/setup',
        builder: (_, __) => const MatchSetupScreen(),
      ),
      GoRoute(
        path: '/scoreboard',
        builder: (_, __) => const ScoreboardScreen(),
      ),
      GoRoute(
        path: '/summary',
        builder: (_, __) => const SummaryScreen(),
      ),
      GoRoute(
        path: '/history',
        builder: (_, __) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/history/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return MatchDetailScreen(matchId: id ?? 0);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (_, __) => const SettingsScreen(),
      ),
    ],
  );
}

final routerProvider = Provider<GoRouter>((ref) => createRouter());
