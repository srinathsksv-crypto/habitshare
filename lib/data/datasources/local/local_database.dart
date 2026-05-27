import 'package:flutter/foundation.dart';
import 'package:habitshare/config/constants/app_constants.dart';
import 'package:habitshare/core/errors/exceptions.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  LocalDatabase._();

  static Database? _database;

  static Future<Database> get instance async {
    _database ??= await _init();
    return _database!;
  }

  static Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'habitshare.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE ${AppConstants.habitsTable} (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            title TEXT NOT NULL,
            description TEXT,
            category_id TEXT,
            color_hex TEXT,
            frequency TEXT,
            target_per_period INTEGER,
            is_archived INTEGER,
            created_at TEXT,
            updated_at TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE ${AppConstants.habitLogsTable} (
            id TEXT PRIMARY KEY,
            habit_id TEXT NOT NULL,
            user_id TEXT NOT NULL,
            logged_at TEXT,
            note TEXT,
            value INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE ${AppConstants.syncQueueTable} (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entity_type TEXT NOT NULL,
            entity_id TEXT NOT NULL,
            operation TEXT NOT NULL,
            payload TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  static Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}

class LocalDatabaseDataSource {
  LocalDatabaseDataSource({Future<Database>? database})
      : _databaseFuture = kIsWeb ? null : (database ?? LocalDatabase.instance);

  final Future<Database>? _databaseFuture;

  // In-memory fallbacks for Web platform (avoiding sqflite entirely on Web)
  final List<Map<String, dynamic>> _webHabitCache = [];
  final List<Map<String, dynamic>> _webSyncQueue = [];
  int _webSyncIdCounter = 1;

  Future<void> cacheHabits(List<Map<String, dynamic>> habits) async {
    if (kIsWeb) {
      _webHabitCache.clear();
      _webHabitCache.addAll(habits);
      return;
    }
    try {
      final db = await _databaseFuture!;
      final batch = db.batch();
      for (final habit in habits) {
        batch.insert(
          AppConstants.habitsTable,
          habit,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (e) {
      throw CacheException('Failed to cache habits: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCachedHabits(String userId) async {
    if (kIsWeb) {
      return _webHabitCache.where((h) => h['user_id'] == userId).toList();
    }
    try {
      final db = await _databaseFuture!;
      return db.query(
        AppConstants.habitsTable,
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );
    } catch (e) {
      throw CacheException('Failed to read cached habits: $e');
    }
  }

  Future<void> enqueueSync({
    required String entityType,
    required String entityId,
    required String operation,
    required String payload,
  }) async {
    if (kIsWeb) {
      _webSyncQueue.add({
        'id': _webSyncIdCounter++,
        'entity_type': entityType,
        'entity_id': entityId,
        'operation': operation,
        'payload': payload,
        'created_at': DateTime.now().toIso8601String(),
      });
      return;
    }
    try {
      final db = await _databaseFuture!;
      await db.insert(AppConstants.syncQueueTable, {
        'entity_type': entityType,
        'entity_id': entityId,
        'operation': operation,
        'payload': payload,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw SyncException('Failed to enqueue sync item: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    if (kIsWeb) {
      return List.from(_webSyncQueue);
    }
    try {
      final db = await _databaseFuture!;
      return db.query(
        AppConstants.syncQueueTable,
        orderBy: 'created_at ASC',
      );
    } catch (e) {
      throw SyncException('Failed to read sync queue: $e');
    }
  }

  Future<void> clearSyncItem(int id) async {
    if (kIsWeb) {
      _webSyncQueue.removeWhere((item) => item['id'] == id);
      return;
    }
    try {
      final db = await _databaseFuture!;
      await db.delete(
        AppConstants.syncQueueTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw SyncException('Failed to clear sync item: $e');
    }
  }

  Future<int> pendingCount() async {
    if (kIsWeb) {
      return _webSyncQueue.length;
    }
    final db = await _databaseFuture!;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${AppConstants.syncQueueTable}',
    );
    return (result.first['count'] as int?) ?? 0;
  }
}
