import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/match.dart';
import '../models/match_config.dart';

class DatabaseService {
  DatabaseService._();
  static Database? _db;
  static const _dbName = 'padelero.db';
  static const _version = 1;

  static Future<Database> get instance async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, _dbName);
    return openDatabase(
      path,
      version: _version,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE matches (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            team1_name TEXT NOT NULL,
            team2_name TEXT NOT NULL,
            config_json TEXT NOT NULL,
            result_json TEXT NOT NULL,
            date TEXT NOT NULL,
            duration_seconds INTEGER NOT NULL,
            winner INTEGER
          )
        ''');
      },
    );
  }

  static Future<int> insertMatch(Match match) async {
    final db = await instance;
    return db.insert('matches', {
      'team1_name': match.team1Name,
      'team2_name': match.team2Name,
      'config_json': jsonEncode(match.config.toJson()),
      'result_json': jsonEncode(match.resultJson),
      'date': match.date.toIso8601String(),
      'duration_seconds': match.durationSeconds,
      'winner': match.winner,
    });
  }

  static Future<List<Match>> getRecentMatches({int limit = 20}) async {
    final db = await instance;
    final list = await db.query(
      'matches',
      orderBy: 'date DESC',
      limit: limit,
    );
    return list.map(_rowToMatch).toList();
  }

  static Future<Match?> getMatchById(int id) async {
    final db = await instance;
    final list = await db.query('matches', where: 'id = ?', whereArgs: [id]);
    if (list.isEmpty) return null;
    return _rowToMatch(list.first);
  }

  static Future<void> deleteMatch(int id) async {
    final db = await instance;
    await db.delete('matches', where: 'id = ?', whereArgs: [id]);
  }

  static Match _rowToMatch(Map<String, dynamic> row) {
    final id = row['id'] as int;
    final configJson = jsonDecode(row['config_json'] as String) as Map<String, dynamic>;
    final resultJson = jsonDecode(row['result_json'] as String) as Map<String, dynamic>;
    return Match(
      id: id,
      team1Name: row['team1_name'] as String,
      team2Name: row['team2_name'] as String,
      config: MatchConfig.fromJson(configJson),
      resultJson: resultJson,
      date: DateTime.parse(row['date'] as String),
      durationSeconds: row['duration_seconds'] as int,
      winner: row['winner'] as int?,
    );
  }
}
